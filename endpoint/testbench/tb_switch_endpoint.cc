#include "EndSwitchManager.h"
#include "Vswitch_endpoint_wrapper.h"
#include "crc.h"
#include "utility.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <queue>
#include <span>
#include <vector>

uint64_t sim_time = 0;
uint64_t fails = 0;

NetworkManager *manager;
Vswitch_endpoint_wrapper *dut;
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

    if (sim_time > 10000) {
        signalHandler(0);
    }
}

void writeBus(uint32_t addr, uint32_t data) {
    dut->addr = addr;
    dut->wdata = data;
    dut->wen = 1;
    tick();
    dut->wen = 0;
}

void reset() {
    dut->clk = 0;
    dut->n_rst = 1;
    for (int i = 0; i < 4; i++) {
        dut->wen = 0;
        dut->ren = 0;
        dut->addr = 0;
        dut->wdata = 0;
        dut->strobe = 0xF;
        dut->in_flit = 0;
        dut->packet_sent = 0;
    }

    tick();
    dut->n_rst = 0;
    tick();
    tick();
    tick();
    dut->n_rst = 1;
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
        : fmt(0x9), dest(dest), addr(addr >> 2), len(len), req(req), id(0), vc(vc) {}

    operator uint64_t() {
        return (((uint64_t)this->vc) << 39) | (((uint64_t)this->id) << 37) |
               (((uint64_t)this->req) << 32) | (((uint64_t)this->fmt) << 28) |
               (((uint64_t)this->dest) << 23) | (((uint64_t)this->addr) << 4) |
               (((uint64_t)this->len));
    }
} __attribute__((packed)) __attribute__((aligned(8)));

void sendSmallWrite(uint8_t from, uint8_t to, const std::span<uint32_t> &data, bool vc = 0) {
    SmallWrite hdr(from, to, data.size(), 0xCAFECAFE, vc);
    std::queue<uint32_t> flits;
    flits.push((uint32_t)(uint64_t)hdr);
    crc_t crc = crc_init();
    for (auto d : data) {
        flits.push((((uint64_t)hdr.vc) << 39) | (((uint64_t)hdr.id) << 37) |
                   (((uint64_t)hdr.req) << 32) | d);
        crc = crc_update(crc, &d, 4);
    }
    flits.push((((uint64_t)hdr.vc) << 39) | (((uint64_t)hdr.id) << 37) |
               (((uint64_t)hdr.req) << 32) | crc_finalize(crc));
    manager->queuePacketSend(from, flits);
    manager->queuePacketCheck(to, flits);
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
    std::queue<uint32_t> flits;
    flits.push(hdr);
    manager->queuePacketSend(1, flits);
}

void sendRouteTableInit(uint8_t switch_num, uint8_t tbl_entry, uint8_t src, uint8_t dest,
                        uint8_t port) {
    sendConfig(switch_num, tbl_entry, src << 10 | dest << 5 | port); // TODO: num bits for port?
}

void resetAndInit() {
    reset();
    manager->reset();

    writeBus(0, 0);
    writeBus(0x4, 0x080);
    writeBus(0x8, 0x100);
    writeBus(0xC, 0x180);
    // Set up routing table
    // For 1:
    // {*, *, 1}
    sendRouteTableInit(1, 0, 0, 0, 1);

    // Give some time for the packets to flow through the network
    wait_for_propagate(50);
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
    dut = new Vswitch_endpoint_wrapper;
    trace = new VerilatedFstC;
    Verilated::traceEverOn(true);
    dut->trace(trace, 5);
    trace->open("endpoint.fst");

    // Test single packet routing
    // Send packet from 1 to 2
    {
        resetAndInit();
        std::vector<uint32_t> data = {0xFAFAFA, 0xAFAFAFAF, 0xCAFECAFE, 0x12345678};
        sendSmallWrite(1, 2, data);
        while (!manager->isComplete()) {
            tick();
        }
        data = {0x12345678, 0xFAFAFA, 0xCAFECAFE, 0xAFAFAFAF};
        sendSmallWrite(1, 2, data);
        while (!manager->isComplete()) {
            tick();
        }
        data = {rand(), rand()};
        sendSmallWrite(1, 2, data);
        while (!manager->isComplete()) {
            tick();
        }
        data = {rand(), rand()};
        sendSmallWrite(1, 2, data);
        while (!manager->isComplete()) {
            tick();
        }
    }

    wait_for_propagate(100);

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

    trace->close();

    return 0;
}
