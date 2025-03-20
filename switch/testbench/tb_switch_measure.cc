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

NetworkManager<9> *manager;
Vswitch_wrapper *dut;
VerilatedFstC *trace;

void signalHandler(int signum) {
    std::cout << "Got signal " << signum << std::endl;
    std::cout << "Calling SystemVerilog 'final' block & exiting!" << std::endl;

    manager->reportRemainingCheck();

    dut->final();
    trace->close();

    exit(signum);
}

void tick(bool limit) {
    dut->clk = 0;
    manager->tick();
    dut->eval();
    trace->dump(sim_time++);
    dut->clk = 1;
    dut->eval();
    trace->dump(sim_time++);

    if (limit && sim_time > 1000000) {
        signalHandler(0);
    }
}

void reset() {
    dut->clk = 0;
    dut->nrst = 1;
    for (int i = 0; i < 9; i++) {
        dut->in_flit[i] = 0;
        dut->data_ready_in[i] = 0;
        dut->packet_sent[i] = 0;
    }

    tick(false);
    dut->nrst = 0;
    tick(false);
    tick(false);
    tick(false);
    dut->nrst = 1;
    tick(false);
    tick(false);
}

void wait_for_propagate(uint32_t waits) {
    for (int i = 0; i < waits; i++) {
        tick(false);
    }
}

void sendSmallWrite(uint8_t from, uint8_t to, const std::span<uint32_t> &data, bool vc = 0) {
    SmallWrite hdr(from, to, data.size(), 0xCAFECAFE, vc);
    std::vector<uint64_t> flits = {hdr};
    crc_t crc = crc_init();
    for (auto d : data) {
        flits.push_back((((uint64_t)hdr.vc) << 39) | (((uint64_t)hdr.id) << 37) |
                        (((uint64_t)hdr.req) << 32) | d);
        crc = crc_update(crc, &d, 4);
    }
    flits.push_back((((uint64_t)hdr.vc) << 39) | (((uint64_t)hdr.id) << 37) |
                    (((uint64_t)hdr.req) << 32) | crc_finalize(crc));
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

void sendNode(uint8_t switch_num) {
    sendConfig(switch_num, NODE_ID_ADDR, switch_num);
}

void sendRouteTableInit(uint8_t switch_num, uint8_t tbl_entry, uint8_t src, uint8_t dest,
                        uint8_t port) {
    sendConfig(switch_num, tbl_entry, src << 10 | dest << 5 | port); // TODO: num bits for port?
}

void resetAndInit() {
    reset();
    manager->reset();
    // East/west first, then north/south
    // Set Nodo ID in 1
    sendNode(1);
    // Set up routing table
    // For 1:
    // {*, 2, 1}
    sendRouteTableInit(1, 0, 0, 2, 1);
    // {*, 3, 1}
    sendRouteTableInit(1, 1, 0, 3, 1);
    // {*, 4, 2}
    sendRouteTableInit(1, 2, 0, 4, 2);
    // {*, 5, 1}
    sendRouteTableInit(1, 3, 0, 5, 1);
    // {*, 6, 1}
    sendRouteTableInit(1, 4, 0, 6, 1);
    // {*, 7, 2}
    sendRouteTableInit(1, 5, 0, 7, 2);
    // {*, 8, 1}
    sendRouteTableInit(1, 6, 0, 8, 1);
    // {*, 9, 1}
    sendRouteTableInit(1, 7, 0, 9, 1);

    // For 2:
    sendNode(2);
    // {*, 1, 1}
    sendRouteTableInit(2, 0, 0, 1, 1);
    // {*, 3, 2}
    sendRouteTableInit(2, 1, 0, 3, 2);
    // {*, 4, 1}
    sendRouteTableInit(2, 2, 0, 4, 1);
    // {*, 5, 3}
    sendRouteTableInit(2, 3, 0, 5, 3);
    // {*, 6, 2}
    sendRouteTableInit(2, 4, 0, 6, 2);
    // {*, 7, 1}
    sendRouteTableInit(2, 5, 0, 7, 1);
    // {*, 8, 3}
    sendRouteTableInit(2, 6, 0, 8, 3);
    // {*, 9, 2}
    sendRouteTableInit(2, 7, 0, 9, 2);

    // For 3:
    sendNode(3);
    // {*, 1, 1}
    sendRouteTableInit(3, 0, 0, 1, 1);
    // {*, 2, 1}
    sendRouteTableInit(3, 1, 0, 2, 1);
    // {*, 4, 1}
    sendRouteTableInit(3, 2, 0, 4, 1);
    // {*, 5, 1}
    sendRouteTableInit(3, 3, 0, 5, 1);
    // {*, 6, 2}
    sendRouteTableInit(3, 4, 0, 6, 2);
    // {*, 7, 1}
    sendRouteTableInit(3, 5, 0, 7, 1);
    // {*, 8, 1}
    sendRouteTableInit(3, 6, 0, 8, 1);
    // {*, 9, 2}
    sendRouteTableInit(3, 7, 0, 9, 2);

    // For 4:
    sendNode(4);
    // {*, 1, 1}
    sendRouteTableInit(4, 0, 0, 1, 1);
    // {*, 2, 2}
    sendRouteTableInit(4, 1, 0, 2, 2);
    // {*, 3, 2}
    sendRouteTableInit(4, 2, 0, 3, 2);
    // {*, 5, 2}
    sendRouteTableInit(4, 3, 0, 5, 2);
    // {*, 6, 2}
    sendRouteTableInit(4, 4, 0, 6, 2);
    // {*, 7, 3}
    sendRouteTableInit(4, 5, 0, 7, 3);
    // {*, 8, 2}
    sendRouteTableInit(4, 6, 0, 8, 2);
    // {*, 9, 2}
    sendRouteTableInit(4, 7, 0, 9, 2);

    // For 5:
    sendNode(5);
    // {*, 1, 2}
    sendRouteTableInit(5, 0, 0, 1, 2);
    // {*, 2, 1}
    sendRouteTableInit(5, 1, 0, 2, 1);
    // {*, 3, 3}
    sendRouteTableInit(5, 2, 0, 3, 3);
    // {*, 4, 2}
    sendRouteTableInit(5, 3, 0, 4, 2);
    // {*, 6, 3}
    sendRouteTableInit(5, 4, 0, 6, 3);
    // {*, 7, 2}
    sendRouteTableInit(5, 5, 0, 7, 2);
    // {*, 8, 4}
    sendRouteTableInit(5, 6, 0, 8, 4);
    // {*, 9, 3}
    sendRouteTableInit(5, 7, 0, 9, 3);

    // For 6:
    sendNode(6);
    // {*, 1, 2}
    sendRouteTableInit(6, 0, 0, 1, 2);
    // {*, 2, 2}
    sendRouteTableInit(6, 1, 0, 2, 2);
    // {*, 3, 1}
    sendRouteTableInit(6, 2, 0, 3, 1);
    // {*, 4, 2}
    sendRouteTableInit(6, 3, 0, 4, 2);
    // {*, 5, 2}
    sendRouteTableInit(6, 4, 0, 5, 2);
    // {*, 7, 2}
    sendRouteTableInit(6, 5, 0, 7, 2);
    // {*, 8, 2}
    sendRouteTableInit(6, 6, 0, 8, 2);
    // {*, 9, 3}
    sendRouteTableInit(6, 7, 0, 9, 3);

    // For 7:
    sendNode(7);
    // {*, 1, 1}
    sendRouteTableInit(7, 0, 0, 1, 1);
    // {*, 2, 2}
    sendRouteTableInit(7, 1, 0, 2, 2);
    // {*, 3, 2}
    sendRouteTableInit(7, 2, 0, 3, 2);
    // {*, 4, 1}
    sendRouteTableInit(7, 3, 0, 4, 1);
    // {*, 5, 2}
    sendRouteTableInit(7, 4, 0, 5, 2);
    // {*, 6, 2}
    sendRouteTableInit(7, 5, 0, 6, 2);
    // {*, 8, 2}
    sendRouteTableInit(7, 6, 0, 8, 2);
    // {*, 9, 2}
    sendRouteTableInit(7, 7, 0, 9, 2);

    // For 8:
    sendNode(8);
    // {*, 1, 2}
    sendRouteTableInit(8, 0, 0, 1, 2);
    // {*, 2, 1}
    sendRouteTableInit(8, 1, 0, 2, 1);
    // {*, 3, 3}
    sendRouteTableInit(8, 2, 0, 3, 3);
    // {*, 4, 2}
    sendRouteTableInit(8, 3, 0, 4, 2);
    // {*, 5, 1}
    sendRouteTableInit(8, 4, 0, 5, 1);
    // {*, 6, 3}
    sendRouteTableInit(8, 5, 0, 6, 3);
    // {*, 7, 2}
    sendRouteTableInit(8, 6, 0, 7, 2);
    // {*, 9, 3}
    sendRouteTableInit(8, 7, 0, 9, 3);

    // For 9:
    sendNode(9);
    // {*, 1, 2}
    sendRouteTableInit(9, 0, 0, 1, 2);
    // {*, 2, 2}
    sendRouteTableInit(9, 1, 0, 2, 2);
    // {*, 3, 1}
    sendRouteTableInit(9, 2, 0, 3, 1);
    // {*, 4, 2}
    sendRouteTableInit(9, 3, 0, 4, 2);
    // {*, 5, 2}
    sendRouteTableInit(9, 4, 0, 5, 2);
    // {*, 6, 1}
    sendRouteTableInit(9, 5, 0, 6, 1);
    // {*, 7, 2}
    sendRouteTableInit(9, 6, 0, 7, 2);
    // {*, 8, 2}
    sendRouteTableInit(9, 7, 0, 8, 2);

    // Give some time for the packets to flow through the network
    wait_for_propagate(500);
}

bool inject() {
    static uint32_t total_injections = 0;
    const uint32_t cycles_per_sec = FREQ_MHZ * 1e6;
    const uint32_t cycles_per_injection = cycles_per_sec / INJECTION_RATE_FREQ;
    static_assert(cycles_per_injection > 0);
    if (total_injections <= TOTAL_INJECTIONS && sim_time % cycles_per_injection == 0) {
        total_injections++;
        for (int from = 1; from <= 9; from++) {
            uint8_t to = from;
            do {
                to = std::rand() % 9 + 1;
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
    dut = new Vswitch_wrapper;
    manager = new NetworkManager<9>(dut);
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
            tick(true);
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

    return fails;
}
