#include "NetworkManager.h"
#include "Vswitch_wrapper.h"
#include "utility.h"
#include "verilated_fst_c.h"

extern uint64_t sim_time;

extern Vswitch_wrapper *dut;
extern NetworkManager *manager;
extern VerilatedFstC *trace;

void reset() {
    dut->clk = 0;
    dut->nrst = 1;
    for (int i = 0; i < 4; i++) {
        dut->in_flit[i] = 0;
        dut->data_ready_in[i] = 0;
        dut->packet_sent[i] = 0;
    }

    tick(false);
    dut->nrst = 0;
    tick(false);
    tick(false);
    tick(false);
    dut->nrst = 1;
    tick(false);
    tick(false);
}

void signalHandler(int signum) {
    std::cout << "Got signal " << signum << std::endl;
    std::cout << "Calling SystemVerilog 'final' block & exiting!" << std::endl;

    manager->reportRemainingCheck();

    dut->final();
    trace->close();

    exit(signum);
}

void tick(bool limit) {
    dut->clk = 0;
    manager->tick();
    dut->eval();
    trace->dump(sim_time++);
    dut->clk = 1;
    dut->eval();
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
