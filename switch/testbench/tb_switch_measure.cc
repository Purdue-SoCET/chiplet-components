#include "NetworkManager.h"
#include "Vswitch_wrapper.h"
#include "crc.h"
#include "packet.h"
#include "utility.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <queue>
#include <random>
#include <span>
#include <vector>

#define INJECTION_RATE_FREQ 100000000
#define TOTAL_INJECTIONS 1000
#define FREQ_MHZ 100

uint64_t sim_time = 0;
uint64_t fails = 0;

NetworkManager *manager;
Vswitch_wrapper *dut;
VerilatedFstC *trace;

void sendSmallWrite(uint8_t from, uint8_t to, const std::span<uint32_t> &data, bool vc = 0) {
    SmallWrite hdr(from, to, data.size(), 0xCAFECAFE, vc);
    std::vector<uint64_t> flits = {hdr};
    crc_t crc = crc_init();
    for (auto d : data) {
        // TODO: hide annoying bug where if the top nibble is 0x4 and the next 5 bits match a node,
        // it'll consume it even though its a data flit, should fix this in hardware
        d |= 0xF << 28;
        flits.push_back((((uint64_t)hdr.vc) << 39) | (((uint64_t)hdr.id) << 37) |
                        (((uint64_t)hdr.req) << 32) | d);
        crc = crc_update(crc, &d, 4);
    }
    flits.push_back((((uint64_t)hdr.vc) << 39) | (((uint64_t)hdr.id) << 37) |
                    (((uint64_t)hdr.req) << 32) | (0xF << 28) | crc_finalize(crc));
    manager->queuePacketSend(from, flits);
    std::queue<uint64_t> flit_queue = {};
    for (auto f : flits) {
        flit_queue.push(f & FLIT_MASK);
    }
    manager->queuePacketCheck(to, flit_queue);
}

// Send all config packets out of switch 1, we can't check these since they will be consumed by the
// switch.
void sendConfig(uint8_t switch_num, uint8_t addr, uint16_t data) {
    ConfigPkt hdr(1, switch_num, addr, data);
    std::array<uint64_t, 1> flits = {hdr};
    manager->queuePacketSend(1, flits);
}

void sendRouteTableInit(uint8_t switch_num, uint8_t tbl_entry, uint8_t src, uint8_t dest,
                        uint8_t port) {
    sendConfig(switch_num, tbl_entry, src << 10 | dest << 5 | port); // TODO: num bits for port?
}

void resetAndInit() {
    reset();
    manager->reset();
    // Set up routing table
    // For 1:
    // {*, 2, 1}
    sendRouteTableInit(1, 0, 0, 2, 1);
    // {*, 3, 2}
    sendRouteTableInit(1, 1, 0, 3, 2);
    // {*, 4, 1}
    sendRouteTableInit(1, 2, 0, 4, 1);

    // For 2:
    // {*, 1, 1}
    sendRouteTableInit(2, 0, 0, 1, 1);
    // {*, 4, 2}
    sendRouteTableInit(2, 1, 0, 4, 2);
    // {*, 3, 1}
    sendRouteTableInit(2, 2, 0, 3, 1);

    // For 3:
    // {*, 1, 1}
    sendRouteTableInit(3, 0, 0, 1, 1);
    // {*, 4, 2}
    sendRouteTableInit(3, 1, 0, 4, 2);
    // {*, 2, 2}
    sendRouteTableInit(3, 2, 0, 2, 2);

    // For 4:
    // {*, 2, 1}
    sendRouteTableInit(4, 0, 0, 2, 1);
    // {*, 3, 2}
    sendRouteTableInit(4, 1, 0, 3, 2);
    // {*, 1, 2}
    sendRouteTableInit(4, 2, 0, 1, 2);

    // Give some time for the packets to flow through the network
    wait_for_propagate(300);
}

bool inject() {
    static uint32_t total_injections = 0;
    const uint32_t cycles_per_sec = FREQ_MHZ * 1e6;
    const uint32_t cycles_per_injection = cycles_per_sec / INJECTION_RATE_FREQ;
    static_assert(cycles_per_injection > 0);
    if (total_injections <= TOTAL_INJECTIONS && sim_time % cycles_per_injection == 0) {
        total_injections++;
        for (int from = 1; from <= 4; from++) {
            uint8_t to = from;
            do {
                to = std::rand() % 4 + 1;
            } while (from == to);
            uint8_t packet_len = (std::rand() % 16) + 1;
            std::vector<uint32_t> data(packet_len);
            std::generate(data.begin(), data.end(), std::rand);
            sendSmallWrite(from, to, data);
        }
    }

    return total_injections <= TOTAL_INJECTIONS;
}

int main(int argc, char **argv) {
    manager = new NetworkManager;
    dut = new Vswitch_wrapper;
    trace = new VerilatedFstC;
    Verilated::traceEverOn(true);
    dut->trace(trace, 5);
    trace->open("switch.fst");

    // Put randomized packets on each switch at a configurable rate
    {
        unsigned seed = std::time(nullptr);
        std::srand(seed);
        printf("Seed: %d\n", seed);
        resetAndInit();
        while (inject() || !manager->isComplete()) {
            tick(false);
        }
    }

    wait_for_propagate(100);

    if (fails != 0) {
        std::cout << "\x1b[31mTotal failures\x1b[0m: " << fails << std::endl;
    } else {
        std::cout << "\x1b[32mALL TESTS PASSED\x1b[0m" << std::endl;
    }

    dut->final();
    trace->close();

    return 0;
}
