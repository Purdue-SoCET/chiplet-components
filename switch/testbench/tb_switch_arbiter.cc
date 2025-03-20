#include "Vswitch_arbiter_wrapper.h"
#include "verilated.h"
#include "verilated_fst_c.h"

uint64_t sim_time = 0;
uint64_t fails = 0;

Vswitch_arbiter_wrapper *dut;
VerilatedFstC *trace;

void signalHandler(int signum) {
    std::cout << "Got signal " << signum << std::endl;
    std::cout << "Calling SystemVerilog 'final' block & exiting!" << std::endl;

    dut->final();
    trace->close();

    exit(signum);
}

void tick(bool limit) {
    dut->CLK = 0;
    dut->eval();
    trace->dump(sim_time++);
    dut->CLK = 1;
    dut->eval();
    trace->dump(sim_time++);

    if (limit && sim_time > 1000000) {
        signalHandler(0);
    }
}

void reset() {
    dut->CLK = 0;
    dut->nRST = 1;
    dut->bid = 0;

    tick(false);
    dut->nRST = 0;
    tick(false);
    tick(false);
    tick(false);
    dut->nRST = 1;
    tick(false);
    tick(false);
}

void wait_for_propagate(uint32_t waits) {
    for (int i = 0; i < waits; i++) {
        tick(false);
    }
}

void ensure(uint8_t actual, uint8_t expected, const char *test_name) {
    if (actual != expected) {
        printf("[FAIL] Time %d\t%s actual: %d, expected: %d\n", sim_time, test_name, actual,
               expected);
        fails++;
    }
}

int main(int argc, char **argv) {
    dut = new Vswitch_arbiter_wrapper;
    trace = new VerilatedFstC;
    Verilated::traceEverOn(true);
    dut->trace(trace, 5);
    trace->open("arbiter.fst");

    // Test case 1: single bid
    {
        reset();
        dut->bid = 0x10;
        ensure(dut->select, 0, "test case 1 before tick");
        ensure(dut->valid, 0, "test case 1 before tick");
        tick(false);
        ensure(dut->select, 4, "test case 1 after tick");
        ensure(dut->valid, 1, "test case 1 after tick");
    }

    // Test case 2: multi bid
    {
        reset();
        dut->bid = 0x11;
        ensure(dut->select, 0, "test case 2 before tick");
        ensure(dut->valid, 0, "test case 2 before tick");
        tick(false);
        ensure(dut->select, 4, "test case 2 after tick");
        ensure(dut->valid, 1, "test case 2 after tick");
    }

    // Test case 3: multi bid, multi cycle, go left
    {
        reset();
        dut->bid = 0x11;
        ensure(dut->select, 0, "test case 3 before tick");
        tick(false);
        ensure(dut->select, 4, "test case 3 after tick");
        ensure(dut->valid, 1, "test case 3 after tick");
        tick(false);
        ensure(dut->select, 0, "test case 3 after second tick");
        ensure(dut->valid, 1, "test case 3 after second tick");
    }

    // Test case 4: multi bid, multi cycle, go right
    {
        reset();
        dut->bid = 0x10;
        ensure(dut->select, 0, "test case 4 before tick");
        tick(false);
        ensure(dut->select, 4, "test case 4 after tick");
        ensure(dut->valid, 1, "test case 4 after tick");
        dut->bid |= 1 << 7;
        tick(false);
        ensure(dut->select, 7, "test case 4 after second tick");
        ensure(dut->valid, 1, "test case 4 after second tick");
    }

    // Test case 5: single bid, multi cycle, go self
    {
        reset();
        dut->bid = 0x10;
        ensure(dut->select, 0, "test case 4 before tick");
        tick(false);
        ensure(dut->select, 4, "test case 4 after tick");
        ensure(dut->valid, 1, "test case 4 after tick");
        tick(false);
        ensure(dut->select, 4, "test case 4 after second tick");
        ensure(dut->valid, 1, "test case 4 after second tick");
    }

    wait_for_propagate(10);

    if (fails != 0) {
        std::cout << "\x1b[31mTotal failures\x1b[0m: " << fails << std::endl;
    } else {
        std::cout << "\x1b[32mALL TESTS PASSED\x1b[0m" << std::endl;
    }

    dut->final();
    trace->close();

    return fails;
}
