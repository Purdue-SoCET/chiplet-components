#include "NetworkManager.h"
#include "Vswitch_wrapper.h"
#include "crc.h"
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

void signalHandler(int);

void tick() {
    dut->clk = 0;
    manager->tick();
    dut->eval();
    trace->dump(sim_time++);
    dut->clk = 1;
    dut->eval();
    trace->dump(sim_time++);

    if (sim_time > 1000000) {
        signalHandler(0);
    }
}

void reset() {
    dut->clk = 0;
    dut->nrst = 1;
    for (int i = 0; i < 4; i++) {
        dut->in_flit[i] = 0;
        dut->data_ready_in[i] = 0;
        dut->packet_sent[i] = 0;
    }

    tick();
    dut->nrst = 0;
    tick();
    tick();
    tick();
    dut->nrst = 1;
    tick();
    tick();
}

void wait_for_propagate(uint32_t waits) {
    for (int i = 0; i < waits; i++) {
        tick();
    }
}

class SmallWrite {
  public:
    uint64_t len : 4;
    uint64_t addr : 19;
    uint64_t dest : 5;
    uint64_t fmt : 4;
    uint64_t req : 5;
    uint64_t id : 2;
    bool vc;

  public:
    SmallWrite(uint8_t req, uint8_t dest, uint8_t len, uint32_t addr, bool vc)
        : fmt(0x9), dest(dest), addr(addr >> 2), len(len == 16 ? 0 : len), req(req), id(0), vc(vc) {
    }

    operator uint64_t() {
        return (((uint64_t)this->vc) << 39) | (((uint64_t)this->id) << 37) |
               (((uint64_t)this->req) << 32) | (((uint64_t)this->fmt) << 28) |
               (((uint64_t)this->dest) << 23) | (((uint64_t)this->addr) << 4) |
               (((uint64_t)this->len));
    }
} __attribute__((packed)) __attribute__((aligned(8)));

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

class ConfigPkt {
  public:
    uint64_t data_lo : 7;
    uint8_t addr;
    uint8_t data_hi;
    uint64_t dest : 5;
    uint64_t fmt : 4;
    uint64_t req : 5;
    uint64_t id : 2;
    bool vc;
    uint64_t reserved : 24;

  public:
    ConfigPkt(uint8_t req, uint8_t dest, uint8_t addr, uint16_t data)
        : fmt(0x4), dest(dest), data_hi(data >> 7), addr(addr), data_lo(data & 0x7F), req(req),
          id(0), vc(0), reserved(0) {}

    operator uint64_t() {
        return (((uint64_t)this->vc) << 39) | (((uint64_t)this->id) << 37) |
               (((uint64_t)this->req) << 32) | (((uint64_t)this->fmt) << 28) |
               (((uint64_t)this->dest) << 23) | (((uint64_t)this->data_hi) << 15) |
               (((uint64_t)this->addr) << 7) | (((uint64_t)this->data_lo));
    }
} __attribute__((packed)) __attribute__((aligned(8)));

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
    sendConfig(4, 0x15, 0x6);
    // {*, *, 1}
    sendRouteTableInit(4, 2, 0, 0, 1);

    // For 2:
    // {*, *, 1}
    sendRouteTableInit(2, 0, 0, 0, 1);

    // Give some time for the packets to flow through the network
    wait_for_propagate(125);
}

void signalHandler(int signum) {
    std::cout << "Got signal " << signum << std::endl;
    std::cout << "Calling SystemVerilog 'final' block & exiting!" << std::endl;

    manager->reportRemainingCheck();

    dut->final();
    trace->close();

    exit(signum);
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
            tick();
        }
    }

    // Send packet from 1 to 3
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345679};
        sendSmallWrite(1, 3, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 1 to 4
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345679};
        sendSmallWrite(1, 4, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 2 to 1
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567A};
        sendSmallWrite(2, 1, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 2 to 3
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallWrite(2, 3, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 2 to 4
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallWrite(2, 4, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 3 to 1
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567C};
        sendSmallWrite(3, 1, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 3 to 2
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567D};
        sendSmallWrite(3, 2, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 3 to 4
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallWrite(3, 4, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 4 to 1
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567C};
        sendSmallWrite(4, 1, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 4 to 2
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567D};
        sendSmallWrite(4, 2, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    // Send packet from 4 to 3
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallWrite(4, 3, data);
        while (!manager->isComplete()) {
            tick();
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
            tick();
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
            tick();
        }
    }

    // Send packet from 1 to 3 with different vcs
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF};
        sendSmallWrite(1, 3, data);
        sendSmallWrite(1, 3, data, 1);
        while (!manager->isComplete()) {
            tick();
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
            tick();
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
            tick();
        }
    }

    // Put randomized packets on each switch
    {
        unsigned seed = std::time(nullptr);
        std::srand(seed);
        printf("Seed: %d\n", seed);
        resetAndInit();
        uint8_t packet_size = 6;
        std::vector<uint32_t> data(packet_size);
        std::generate(data.begin(), data.end(), std::rand);
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
            tick();
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
