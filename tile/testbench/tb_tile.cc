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

uint32_t readBus(uint8_t tile, uint32_t addr) {
    dut->addr[tile - 1] = addr;
    dut->ren[tile - 1] = 1;
    tick(false);
    uint32_t ret = dut->rdata[tile - 1];
    dut->ren[tile - 1] = 0;
    return ret;
}

void sendSmallWrite(uint8_t from, uint8_t to, const std::span<uint32_t> &data, bool vc = 0) {
    SmallWrite hdr(from, to, data.size(), 0xCAFECAFE, vc);
    std::vector<uint32_t> flits = {hdr};
    for (auto d : data) {
        flits.push_back((((uint64_t)hdr.vc) << 39) | (((uint64_t)hdr.id) << 37) |
                        (((uint64_t)hdr.req) << 32) | d);
    }
    manager->queuePacketSend(from, flits);
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
    sendRouteTableInit(4, 0, 0, 2, 1);
    // {*, 3, 2}
    sendRouteTableInit(4, 1, 0, 3, 2);
    // {*, 1, 2}
    sendRouteTableInit(4, 2, 0, 1, 2);

    // Give some time for the packets to flow through the network
    wait_for_propagate(3000);
}

int main(int argc, char **argv) {
    manager = new NetworkManager;
    dut = new Vtile_wrapper;
    trace = new VerilatedFstC;
    Verilated::traceEverOn(true);
    dut->trace(trace, 5);
    trace->open("tile.fst");

    for (int from = 1; from <= 4; from++) {
        for (int to = 1; to <= 4; to++) {
            if (from != to) {
                resetAndInit();
                std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345678};
                sendSmallWrite(from, to, data);
                while (!manager->isComplete()) {
                    tick(false);
                }
                uint32_t header = SmallWrite(from, to, 4, 0xCAFECAFE, 0);
                while (readBus(to, 0x1100) == 0) {}
                ensure(readBus(to, 0x1100), {{1}}, "num packets", false);
                readBus(to, 0x110C);
                crc_t crc = crc_init();
                ensure(readBus(to, 0x1000), {{header}}, "header", false);
                crc = crc_update(crc, &header, 4);
                ensure(readBus(to, 0x1000), {{data[0]}}, "body flit 1", false);
                crc = crc_update(crc, &data[0], 4);
                ensure(readBus(to, 0x1000), {{data[1]}}, "body flit 2", false);
                crc = crc_update(crc, &data[1], 4);
                ensure(readBus(to, 0x1000), {{data[2]}}, "body flit 3", false);
                crc = crc_update(crc, &data[2], 4);
                ensure(readBus(to, 0x1000), {{data[3]}}, "body flit 4", false);
                crc = crc_update(crc, &data[3], 4);
                crc = crc_finalize(crc);
                ensure(readBus(to, 0x1000), {{crc}}, "crc", false);

                // Random data test
                data = {rand(), rand(), rand()};
                sendSmallWrite(from, to, data);
                while (!manager->isComplete()) {
                    tick(false);
                }
                header = SmallWrite(from, to, 3, 0xCAFECAFE, 1);
                while (readBus(to, 0x1100) == 0) {}
                ensure(readBus(to, 0x1100), {{1}}, "rand num packets", false);
                readBus(to, 0x110C);
                crc = crc_init();
                ensure(readBus(to, 0x1000), {{header}}, "rand header", false);
                crc = crc_update(crc, &header, 4);
                ensure(readBus(to, 0x1000), {{data[0]}}, "rand body flit 1", false);
                crc = crc_update(crc, &data[0], 4);
                ensure(readBus(to, 0x1000), {{data[1]}}, "rand body flit 2", false);
                crc = crc_update(crc, &data[1], 4);
                ensure(readBus(to, 0x1000), {{data[2]}}, "rand body flit 3", false);
                crc = crc_update(crc, &data[2], 4);
                crc = crc_finalize(crc);
                ensure(readBus(to, 0x1000), {{crc}}, "rand crc", false);

                wait_for_propagate(1000);
            }
        }
    }

    if (fails != 0) {
        std::cout << "\x1b[31mTotal failures\x1b[0m: " << fails << std::endl;
    } else {
        std::cout << "\x1b[32mALL TESTS PASSED\x1b[0m" << std::endl;
    }

    dut->final();
    trace->close();

    return fails;
}
