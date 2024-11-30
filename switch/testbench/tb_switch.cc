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

// Send all config packets out of switch 1, we can't check these since they will be consumed by the
// switch.
void sendConfig(uint8_t switch_num, uint8_t addr, uint16_t data) {
    uint32_t flit =
        0x4 << 28 | switch_num << 23 | (data >> 7) << 15 | (addr & 0xFF) << 8 | (data & 0x7F);
    std::array<uint32_t, 1> flits = {flit};
    manager->queuePacketSend(0, flits);
}

void sendRouteTableInit(uint8_t switch_num, uint8_t tbl_entry, uint8_t src, uint8_t dest,
                        uint8_t port) {
    sendConfig(switch_num, tbl_entry, src << 9 | dest << 4 | port); // TODO: num bits for port?
}

void resetAndInit() {
    reset();
    // Set up routing table
    // For 1:
    // {*, *, 0}
    sendRouteTableInit(0, 0, 0, 0, 0);
    // For 2:
    // {*, *, 0}
    sendRouteTableInit(1, 0, 0, 0, 0);
    // For 3:
    // {*, *, 0}
    sendRouteTableInit(2, 0, 0, 0, 0);
    // For 4:
    // {*, 1, 0}
    sendRouteTableInit(3, 0, 0, 1, 0);
    // {*, 2, 1}
    sendRouteTableInit(3, 1, 0, 2, 1);
    // Set dateline for going out of either port
    sendConfig(3, 0x15, 0x3);
    // {*, *, 0}
    sendRouteTableInit(3, 2, 0, 0, 0);
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

    // Set up routing table
    // For 1:
    // {*, *, 0}
    sendRouteTableInit(1, 0, 0, 0, 0);
    // For 2:
    // {*, *, 0}
    sendRouteTableInit(2, 0, 0, 0, 0);
    // For 3:
    // {*, *, 0}
    sendRouteTableInit(3, 0, 0, 0, 0);
    // For 4:
    // {*, 1, 0}
    sendRouteTableInit(4, 0, 0, 1, 0);
    // {*, 2, 1}
    sendRouteTableInit(4, 1, 0, 2, 1);
    // Set dateline for going out of either port
    sendConfig(4, 0x15, 0x3);
    // {*, *, 0}
    sendRouteTableInit(4, 2, 0, 0, 0);

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

    // Test error checking
    // 8b10b error
    // TODO:

    // CRC error
    // TODO:

    if (fails != 0) {
        std::cout << "Total failures: " << fails << std::endl;
    }

    trace->close();

    return 0;
}
