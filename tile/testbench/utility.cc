#include "NetworkManager.h"
#include "Vtile_wrapper.h"
#include "utility.h"
#include "verilated_fst_c.h"

extern uint64_t sim_time;

extern Vtile_wrapper *dut;
extern NetworkManager *manager;
extern VerilatedFstC *trace;

void reset() {
    dut->clk = 0;
    dut->n_rst = 1;
    for (int i = 0; i < 4; i++) {
        dut->wen[i] = 0;
        dut->ren[i] = 0;
        dut->addr[i] = 0;
        dut->wdata[i] = 0;
        dut->strobe[i] = 0xF;
    }

    tick(false);
    dut->n_rst = 0;
    tick(false);
    tick(false);
    tick(false);
    dut->n_rst = 1;
    tick(false);
    tick(false);
}

void signalHandler(int signum) {
    std::cout << "Got signal " << signum << std::endl;
    std::cout << "Calling SystemVerilog 'final' block & exiting!" << std::endl;

    manager->reportRemainingCheck();

    trace->close();

    exit(signum);
}

void tick(bool limit) {
    dut->clk = 0;
    dut->eval_step();
    manager->eval_step();
    dut->eval_end_step();
    manager->eval_end_step();
    trace->dump(sim_time++);
    dut->clk = 1;
    dut->eval_step();
    manager->eval_step();
    dut->eval_end_step();
    manager->eval_end_step();
    trace->dump(sim_time++);

    if (limit && sim_time > 1000000) {
        signalHandler(0);
    }
}

void wait_for_propagate(uint32_t waits) {
    for (int i = 0; i < waits; i++) {
        tick(false);
    }
}
