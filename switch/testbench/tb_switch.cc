#include "NetworkManager.h"
#include "Vswitch_wrapper.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <queue>
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

    if (sim_time > 100000) {
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
}

void wait_for_propagate(uint32_t waits) {
    for (int i = 0; i < waits; i++) {
        tick();
    }
}

void ensure(uint32_t actual, uint32_t expected, const char *test_name) {
    if (actual != expected) {
        std::cout << "[FAIL] "
                  << "Time " << sim_time << "\t" << test_name << ": Expected: " << std::hex
                  << expected << ", Actual: " << actual << std::dec << std::endl;
        fails++;
    } else {
        std::cout << "[PASS] "
                  << "Time " << sim_time << "\t" << test_name << std::endl;
    }
}

void sendPacket(uint8_t from, uint8_t to, const std::span<uint32_t> &flits) {
    // TODO
}

void sendSmallDataNonblocking(uint8_t from, uint8_t to, const std::span<uint32_t> &data) {
    // TODO
}

void sendSmallData(uint8_t from, uint8_t to, const std::span<uint32_t> &data) {
    // TODO
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
        : fmt(0x4 /* TODO: ?? */), dest(dest), data_hi(data >> 7), addr(addr), data_lo(data & 0x7F), req(req),
          id(0), vc(0), reserved(0) {}

    operator uint64_t() {
        return ((uint64_t)this->vc << 39) |
               ((uint64_t)this->id << 37) |
               ((uint64_t)this->req << 32) |
               ((uint64_t)this->fmt << 28) |
               ((uint64_t)this->dest << 23) |
               ((uint64_t)this->data_hi << 15) |
               ((uint64_t)this->addr << 7) |
               ((uint64_t)this->data_lo);
    }
} __attribute__((packed)) __attribute__((aligned(8)));

// Send all config packets out of switch 1, we can't check these since they will be consumed by the
// switch.
void sendConfig(uint8_t switch_num, uint8_t addr, uint16_t data) {
    ConfigPkt pkt(1, switch_num, addr, data);
    std::array<uint64_t, 1> flits = {pkt};
    manager->queuePacketSend(1, flits);
}

void sendRouteTableInit(uint8_t switch_num, uint8_t tbl_entry, uint8_t src, uint8_t dest,
                        uint8_t port) {
    sendConfig(switch_num, tbl_entry, src << 10 | dest << 5 | port); // TODO: num bits for port?
}

void resetAndInit() {
    reset();
    // Set up routing table
    // For 1:
    // {*, *, 1}
    sendRouteTableInit(1, 0, 0, 0, 1);
    // For 2:
    // {*, *, 1}
    sendRouteTableInit(2, 0, 0, 0, 1);
    // For 3:
    // {*, *, 1}
    // sendRouteTableInit(3, 0, 0, 0, 1);
    // For 4:
    // {*, 1, 1}
    // sendRouteTableInit(4, 0, 0, 1, 1);
    // {*, 2, 2}
    // sendRouteTableInit(4, 1, 0, 2, 2);
    // Set dateline for going out of either port
    // sendConfig(4, 0x15, 0x3);
    // {*, *, 1}
    // sendRouteTableInit(4, 2, 0, 0, 1);
    while (!manager->isComplete()) {
        tick();
    }
}

void signalHandler(int signum) {
    std::cout << "Got signal " << signum << std::endl;
    std::cout << "Calling SystemVerilog 'final' block & exiting!" << std::endl;

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
    //    │  0  │                          │
    //    │     ├──┐  ┌─────┐     ┌─────┐  │
    //    └─────┘  └─►│     │     │     ├──┘
    //                │  2  ├────►│  3  │
    //    ┌─────┐  ┌─►│     │     │     ├──┐
    //    │     ├──┘  └─────┘     └─────┘  │
    //    │  1  │                          │
    // ┌─►│     │                          │
    // │  └─────┘                          │
    // │                                   │
    // └─────────────────┼─────────────────┘
    //
    // In ports for 0: {endpoint, 3}
    // Out ports for 0: {endpoint, 2}
    // In ports for 1: {endpoint, 3}
    // Out ports for 1: {endpoint, 2}
    // In ports for 2: {endpoint, 0, 1}
    // Out ports for 2: {endpoint, 3}
    // In ports for 3: {endpoint, 2}
    // Out ports for 3: {endpoint, 0, 1}

    resetAndInit();

    while (!manager->isComplete()) {
        tick();
    }

    /*
    // Test single packet routing
    // Send packet from 0 to 1
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345678};
        sendSmallData(0, 1, data);
    }

    // Send packet from 0 to 2
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345679};
        sendSmallData(0, 2, data);
    }

    // Send packet from 1 to 0
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567A};
        sendSmallData(1, 0, data);
    }

    // Send packet from 1 to 2
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallData(1, 2, data);
    }

    // Send packet from 2 to 0
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567C};
        sendSmallData(2, 0, data);
    }

    // Send packet from 2 to 1
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567D};
        sendSmallData(2, 1, data);
    }

    // Test multiple packet routing
    // Send packet from 0 to 1 and 0 to 2
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567E};
        sendSmallDataNonblocking(0, 1, data);
        data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567F};
        sendSmallDataNonblocking(0, 2, data);
        // TODO: check data
    }

    // Send packet from 1 to 2 and 1 to 0
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567E};
        sendSmallDataNonblocking(1, 2, data);
        data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567F};
        sendSmallDataNonblocking(1, 0, data);
        // TODO: check data
    }

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

    if (fails != 0) {
        std::cout << "Total failures: " << fails << std::endl;
    }

    trace->close();

    return 0;
}
