#include "NetworkManager.h"
#include "Vtile_wrapper.h"
#include "crc.h"
#include "packet.h"
#include "utility.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <queue>
#include <random>
#include <span>
#include <vector>

uint64_t sim_time = 0;
uint64_t fails = 0;

NetworkManager *manager;
Vtile_wrapper *dut;
VerilatedFstC *trace;

void writeBus(uint8_t tile, uint32_t addr, uint32_t data) {
    manager->queueBusWrite(tile, addr, data);
}

void sendSmallWrite(uint8_t from, uint8_t to, const std::span<uint32_t> &data, bool vc = 0) {
    SmallWrite hdr(from, to, data.size(), 0xCAFECAFE, vc);
    std::vector<uint32_t> flits = {hdr};
    crc_t crc = crc_init();
    for (auto d : data) {
        flits.push_back((((uint64_t)hdr.vc) << 39) | (((uint64_t)hdr.id) << 37) |
                        (((uint64_t)hdr.req) << 32) | d);
        crc = crc_update(crc, &d, 4);
    }
    flits.push_back((((uint64_t)hdr.vc) << 39) | (((uint64_t)hdr.id) << 37) |
                    (((uint64_t)hdr.req) << 32) | crc_finalize(crc));
    manager->queuePacketSend(from, flits);
    std::queue<uint32_t> flit_queue = {};
    for (auto f : flits) {
        flit_queue.push(f);
    }
    manager->queuePacketCheck(to, flit_queue);
}

// Send all config packets out of switch 1, we can't check these since they will be consumed by the
// switch.
void sendConfig(uint8_t switch_num, uint8_t addr, uint16_t data) {
    ConfigPkt hdr(1, switch_num, addr, data);
    std::vector<uint32_t> flits = {hdr};
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

    for (int tile = 1; tile <= 4; tile++) {
        writeBus(tile, 0x0, 0x000);
        writeBus(tile, 0x4, 0x080);
        writeBus(tile, 0x8, 0x100);
        writeBus(tile, 0xC, 0x180);
    }

    // Set Node ID in 1
    sendNode(1);
    // Set up routing table
    // For 1:
    // {*, 2, 1}
    sendRouteTableInit(1, 0, 0, 2, 1);
    // {*, 3, 2}
    sendRouteTableInit(1, 1, 0, 3, 2);
    // {*, 4, 1}
    sendRouteTableInit(1, 2, 0, 4, 1);

    // For 2:
    sendNode(2);
    // {*, 1, 1}
    sendRouteTableInit(2, 0, 0, 1, 1);
    // {*, 4, 2}
    sendRouteTableInit(2, 1, 0, 4, 2);
    // {*, 3, 1}
    sendRouteTableInit(2, 2, 0, 3, 1);

    // For 3:
    sendNode(3);
    // {*, 1, 1}
    sendRouteTableInit(3, 0, 0, 1, 1);
    // {*, 4, 2}
    sendRouteTableInit(3, 1, 0, 4, 2);
    // {*, 2, 2}
    sendRouteTableInit(3, 2, 0, 2, 2);

    // For 4:
    sendNode(4);
    // {*, 2, 1}
    sendRouteTableInit(4 , 0, 0, 2, 1);
    // {*, 3, 2}
    sendRouteTableInit(4, 1, 0, 3, 2);
    // {*, 1, 2}
    sendRouteTableInit(4, 2, 0, 1, 2);

    // Give some time for the packets to flow through the network
    wait_for_propagate(50000);
}

int main(int argc, char **argv) {
    manager = new NetworkManager;
    dut = new Vtile_wrapper;
    trace = new VerilatedFstC;
    Verilated::traceEverOn(true);
    dut->trace(trace, 5);
    trace->open("tile.fst");

    // Test single packet routing
    // Send packet from 1 to 2
    {
        resetAndInit();
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    /*
    // Put randomized packets on each switch
    {
        unsigned seed = std::time(nullptr);
        std::srand(seed);
        printf("Seed: %d\n", seed);
        resetAndInit();
        for (int from = 1; from <= 4; from++) {
            for (int to = 1; to <= 4; to++) {
                if (from != to) {
                    for (int i = 0; i < 10; i++) {
                        uint8_t packet_size = (std::rand() % 16) + 1;
                        std::vector<uint32_t> data(packet_size);
                        std::generate(data.begin(), data.end(), std::rand);
                        sendSmallWrite(from, to, data);
                    }
                }
            }
        }
        while (!manager->isComplete()) {
            tick(true);
        }
    }
    */

    wait_for_propagate(100);
    /*
    // Test dateline crossing
    {
        resetAndInit();
        // TODO
    }
    */

    // Test error checking
    // CRC error
    // TODO: long packet sent with wrong crc, should be killed in forward path and asked to be
    // resent
    // TODO: try to put 4 packets on each switch
    // TODO: randomize

    if (fails != 0) {
        std::cout << "\x1b[31mTotal failures\x1b[0m: " << fails << std::endl;
    } else {
        std::cout << "\x1b[32mALL TESTS PASSED\x1b[0m" << std::endl;
    }

    dut->final();
    trace->close();

    return 0;
}
