#include "Vfifo_wrapper.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <iomanip>
#include <iostream>
#include <string>

uint64_t sim_time = 0;
uint64_t fails = 0;

Vfifo_wrapper *dut;
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
    dut->wen = 0;
    dut->ren = 0;
    dut->clear = 0;
    dut->wdata = 0;

    tick();
    dut->nrst = 0;
    tick();
    dut->nrst = 1;
    tick();
}

void wait_for_propagate(uint32_t clocks) {
    for (auto i = 0; i < clocks; i++)
        tick();
}

void push(uint32_t value) {
    dut->wen = 1;
    dut->wdata = value;
    tick();
    dut->wen = 0;
    dut->wdata = 0;
}

void push_many(const std::vector<uint32_t> &values) {
    for (auto val : values)
        push(val);
}

void ensure(uint32_t actual, uint32_t expected, const char *test_name) {
    if (actual != expected) {
        std::cout << "[FAIL] "
                  << "Time " << sim_time << "\t" << test_name << ": Expected: " << expected
                  << ", Actual: " << actual << std::endl;
        fails++;
    } else {
        std::cout << "[PASS] "
                  << "Time " << sim_time << "\t" << test_name << std::endl;
    }
}

uint32_t pop() {
    uint32_t value = dut->rdata;
    dut->ren = 1;
    tick();
    dut->ren = 0;
    return value;
}

void pop_many_ensuring(const std::vector<uint32_t> &values, const char *test_name) {
    for (auto val : values)
        ensure(pop(), val, test_name);
}

int main(int argc, char **argv) {
    dut = new Vfifo_wrapper;
    trace = new VerilatedFstC;
    Verilated::traceEverOn(true);
    dut->trace(trace, 5);
    trace->open("fifo.fst");

    // Test case 1: Push single element and pop it
    reset();
    ensure(dut->empty, 1, "before pushing 32");
    push(32);
    ensure(dut->empty, 0, "after pushing 32");
    ensure(dut->count, 1, "after pushing 32");
    ensure(pop(), 32, "after pushing 32");

    // Test case 2: Count correct after multiple pushes
    reset();
    ensure(dut->empty, 1, "before pushing values");
    push(1);
    ensure(dut->empty, 0, "after pushing 1");
    push_many({2, 3, 4});
    ensure(dut->count, 4, "after pushing values");
    ensure(pop(), 1, "after pushing values");

    // Test case 3: Pointer wraparound
    reset();
    ensure(dut->empty, 1, "before pushing values");
    push(1);
    ensure(dut->empty, 0, "after pushing 1");
    push_many({2, 3, 4, 5, 6, 7, 8});
    ensure(dut->full, 1, "after pushing values");
    ensure(dut->count, 8, "after pushing values");
    ensure(pop(), 1, "after pushing values");
    ensure(dut->count, 7, "after pushing values");
    push(9);
    ensure(dut->count, 8, "after pushing values");
    ensure(pop(), 2, "after pushing values");
    ensure(dut->count, 7, "after pushing values");
    ensure(pop(), 3, "after pushing values");
    ensure(dut->count, 6, "after pushing values");
    ensure(pop(), 4, "after pushing values");
    ensure(dut->count, 5, "after pushing values");

    // Test case 4: Overrun
    reset();
    ensure(dut->empty, 1, "before pushing values");
    push_many({1, 2, 3, 4, 5, 6, 7, 8});
    ensure(dut->overrun, 0, "after overrun");
    ensure(dut->full, 1, "before pushing values");
    ensure(dut->empty, 0, "before pushing values");
    ensure(dut->count, 8, "before pushing values");
    push(9);
    pop_many_ensuring({1, 2, 3, 4, 5, 6, 7, 8}, "after overrun");
    ensure(dut->empty, 1, "before pushing values");

    // Test case 5: Underrun
    reset();
    ensure(dut->empty, 1, "before pushing values");
    pop();
    ensure(dut->underrun, 1, "underrun after underrun");
    ensure(dut->count, 0, "count after underrun");
    ensure(dut->full, 0, "full after underrun");
    ensure(dut->empty, 1, "empty after underrun");

    // Test case 6: REN && WEN
    reset();
    ensure(dut->empty, 1, "before pushing values");
    ensure(dut->full, 0, "before pushing values");
    ensure(dut->count, 0, "before pushing values");
    push_many({1, 2, 3, 4});
    dut->wen = 1;
    dut->wdata = 5;
    dut->ren = 1;
    ensure(dut->empty, 0, "before pushing values");
    ensure(dut->full, 0, "before pushing values");
    ensure(dut->count, 4, "before pushing values");
    ensure(dut->rdata, 1, "before pushing values");
    tick();
    ensure(dut->empty, 0, "after pushing values");
    ensure(dut->full, 0, "after pushing values");
    ensure(dut->count, 4, "after pushing values");
    ensure(dut->rdata, 2, "after pushing values");

    // Test case 7: REN && WEN while full
    reset();
    ensure(dut->empty, 1, "empty before pushing values");
    ensure(dut->full, 0, "full before pushing values");
    ensure(dut->count, 0, "count before pushing values");
    push_many({1, 2, 3, 4, 5, 6, 7, 8});
    ensure(dut->full, 1, "full after pushing");
    ensure(dut->empty, 0, "empty after pushing");
    ensure(dut->underrun, 0, "underrun after pushing");
    ensure(dut->overrun, 0, "overrun after pushing");
    ensure(dut->count, 8, "count after pushing");
    ensure(dut->rdata, 1, "rdata after pushing");
    dut->wen = 1;
    dut->wdata = 9;
    dut->ren = 1;
    tick();
    dut->ren = 0;
    dut->wen = 0;
    ensure(dut->full, 1, "full after pushing");
    ensure(dut->empty, 0, "empty after pushing");
    ensure(dut->underrun, 0, "underrun after pushing");
    ensure(dut->overrun, 1, "overrun after pushing");
    ensure(dut->count, 8, "count after pushing");
    ensure(dut->rdata, 1, "rdata after pushing");
    pop_many_ensuring({1,2,3,4,5,6,7,8}, "values contained after pushing");

    // Test case 7: REN && WEN while empty
    reset();
    ensure(dut->full, 0, "full after pushing");
    ensure(dut->empty, 1, "empty after pushing");
    ensure(dut->underrun, 0, "underrun after pushing");
    ensure(dut->overrun, 0, "overrun after pushing");
    ensure(dut->count, 0, "count after pushing");
    dut->wen = 1;
    dut->wdata = 100;
    dut->ren = 1;
    tick();
    dut->ren = 0;
    dut->wen = 0;
    ensure(dut->full, 0, "full after pushing");
    ensure(dut->empty, 1, "empty after pushing");
    ensure(dut->underrun, 1, "underrun after pushing");
    ensure(dut->overrun, 0, "overrun after pushing");
    ensure(dut->count, 0, "count after pushing");
    push(100);
    ensure(dut->full, 0, "full after pushing");
    ensure(dut->empty, 0, "empty after pushing");
    ensure(dut->underrun, 1, "underrun after pushing");
    ensure(dut->overrun, 0, "overrun after pushing");
    ensure(dut->count, 1, "count after pushing");
    ensure(pop(), 100, "after popping");
    ensure(dut->full, 0, "full after pushing");
    ensure(dut->empty, 1, "empty after pushing");
    ensure(dut->underrun, 1, "underrun after pushing");
    ensure(dut->overrun, 0, "overrun after pushing");
    ensure(dut->count, 0, "count after pushing");

    if (fails != 0) {
        std::cout << "Total failures: " << fails << std::endl;
    }

    trace->close();

    return 0;
}
