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

void sendRouteTableInit(uint8_t switch_num, uint8_t tbl_entry, uint8_t src, uint8_t dest,
                        uint8_t port) {
    sendConfig(switch_num, tbl_entry, src << 10 | dest << 5 | port); // TODO: num bits for port?
}

void resetAndInit() {
    reset();
    manager->reset();
    // Set up routing table
    // For 1:
    // {*, *, 1}
    sendRouteTableInit(1, 0, 0, 0, 1);

    // For 3:
    // {*, *, 1}
    sendRouteTableInit(3, 0, 0, 0, 1);

    // For 4:
    // {*, 1, 1}
    sendRouteTableInit(4, 0, 0, 1, 1);
    // {*, 2, 2}
    sendRouteTableInit(4, 1, 0, 2, 2);
    // Set dateline for going out of either port
    sendConfig(4, DATELINE_ADDR, 0x6);
    // {*, *, 1}
    sendRouteTableInit(4, 2, 0, 0, 1);

    // For 2:
    // {*, *, 1}
    sendRouteTableInit(2, 0, 0, 0, 1);

    // Give some time for the packets to flow through the network
    wait_for_propagate(125);
}

int main(int argc, char **argv) {
    manager = new NetworkManager;
    dut = new Vswitch_wrapper;
    trace = new VerilatedFstC;
    Verilated::traceEverOn(true);
    dut->trace(trace, 5);
    trace->open("switch.fst");

    // TODO: can we reserve ID=0 for wildcard?
    // Configuration for testing:
    //
    //
    // ┌─────────────────┼─────────────────┐
    // │                                   │
    // │  ┌─────┐                          │
    // └─►│     │                          │
    //    │  1  │                          │
    //    │     ├──┐  ┌─────┐     ┌─────┐  │
    //    └─────┘  └─►│     │     │     ├──┘
    //                │  3  ├────►│  4  │
    //    ┌─────┐  ┌─►│     │     │     ├──┐
    //    │     ├──┘  └─────┘     └─────┘  │
    //    │  2  │                          │
    // ┌─►│     │                          │
    // │  └─────┘                          │
    // │                                   │
    // └─────────────────┼─────────────────┘
    //
    // In ports for 1: {endpoint, 4}
    // Out ports for 1: {endpoint, 3}
    // In ports for 2: {endpoint, 4}
    // Out ports for 2: {endpoint, 3}
    // In ports for 3: {endpoint, 1, 2}
    // Out ports for 3: {endpoint, 4}
    // In ports for 4: {endpoint, 3}
    // Out ports for 4: {endpoint, 1, 2}

    // Test single packet routing
    // Send packet from 1 to 2
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345678};
        sendSmallWrite(1, 2, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 1 to 3
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345679};
        sendSmallWrite(1, 3, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 1 to 4
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345679};
        sendSmallWrite(1, 4, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 2 to 1
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567A};
        sendSmallWrite(2, 1, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 2 to 3
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallWrite(2, 3, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 2 to 4
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallWrite(2, 4, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 3 to 1
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567C};
        sendSmallWrite(3, 1, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 3 to 2
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567D};
        sendSmallWrite(3, 2, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 3 to 4
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallWrite(3, 4, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 4 to 1
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567C};
        sendSmallWrite(4, 1, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 4 to 2
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567D};
        sendSmallWrite(4, 2, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 4 to 3
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallWrite(4, 3, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Test multiple packet routing
    // Send packet from 1 to 2 and 1 to 3
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567E};
        sendSmallWrite(1, 2, data);
        data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567F};
        sendSmallWrite(1, 3, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 2 to 3 and 2 to 1
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567E};
        sendSmallWrite(2, 3, data);
        data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567F};
        sendSmallWrite(2, 1, data);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Send packet from 1 to 3 with different vcs
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF};
        sendSmallWrite(1, 3, data);
        sendSmallWrite(1, 3, data, 1);
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Put 3 packets on each switch and send them all
    {
        resetAndInit();
        for (int from = 1; from <= 4; from++) {
            for (int to = 1; to <= 4; to++) {
                if (from != to) {
                    std::vector<uint32_t> data = {0xCAFECAFE};
                    sendSmallWrite(from, to, data);
                }
            }
        }
        while (!manager->isComplete()) {
            tick(true);
        }
    }

    // Put 3 packets on each switch and send them all with larger packets
    {
        resetAndInit();
        for (int from = 1; from <= 4; from++) {
            for (int to = 1; to <= 4; to++) {
                if (from != to) {
                    std::vector<uint32_t> data = {0xCAFECAFE, 0xFAFAFAFA, 0xAFAFAFAF, 0x12345678};
                    sendSmallWrite(from, to, data);
                }
            }
        }
        while (!manager->isComplete()) {
            tick(true);
        }
    }

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
