#include "Vswitch_wrapper.h"
#include "random"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <iomanip>
#include <iostream>
#include <span>
#include <string>
#include <vector>

uint64_t sim_time = 0;
uint64_t fails = 0;

Vswitch_wrapper *dut;
VerilatedFstC *trace;

void tick() {
    dut->clk = 0;
    dut->eval();
    trace->dump(sim_time++);
    dut->clk = 1;
    dut->eval();
    trace->dump(sim_time++);
}

void reset() {
    dut->clk = 0;
    dut->nrst = 1;

    tick();
    dut->nrst = 0;
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

void sendConfig(uint8_t switch_num, uint8_t addr, uint16_t data) {
    // TODO
}

void sendRouteTableInit(uint8_t switch_num, uint8_t tbl_entry, uint8_t src, uint8_t dest,
                        uint8_t port) {
    sendConfig(switch_num, tbl_entry, src << 9 | dest << 4 | port); // TODO: num bits for port?
}

int main(int argc, char **argv) {
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
    // Send packet from 1 to 2
    {
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345678};
        sendSmallData(1, 2, data);
    }

    // Send packet from 1 to 3
    {
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345679};
        sendSmallData(1, 3, data);
    }

    // Send packet from 2 to 1
    {
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567A};
        sendSmallData(2, 1, data);
    }

    // Send packet from 2 to 3
    {
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567B};
        sendSmallData(2, 3, data);
    }

    // Send packet from 3 to 1
    {
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567C};
        sendSmallData(3, 1, data);
    }

    // Send packet from 3 to 2
    {
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567D};
        sendSmallData(3, 2, data);
    }

    // Test multiple packet routing
    // Send packet from 1 to 2 and 1 to 3
    {
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567E};
        sendSmallDataNonblocking(1, 2, data);
        data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567F};
        sendSmallDataNonblocking(1, 3, data);
        // TODO: check data
    }

    // Send packet from 2 to 3 and 2 to 1
    {
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567E};
        sendSmallDataNonblocking(2, 3, data);
        data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x1234567F};
        sendSmallDataNonblocking(2, 1, data);
        // TODO: check data
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
