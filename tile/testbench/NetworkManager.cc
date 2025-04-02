#include "NetworkManager.h"
#include "Vtile_wrapper.h"
#include "utility.h"
#include <span>
#include <string>

extern Vtile_wrapper *dut;

// `from` is 1-indexed
void NetworkManager::queuePacketSend(uint8_t from, const std::span<uint32_t> &flit) {
    uint32_t addr = 0x0000;
    for (auto f : flit) {
        this->queueBusWrite(from, addr, f);
    }
    this->queueBusWrite(from, ENDPOINT_SEND_ADDR, this->curr_id[from - 1]);
    this->curr_id[from - 1] = (this->curr_id[from - 1] + 1) % 4;
}

// `from` is 1-indexed
void NetworkManager::queuePacketCheck(uint8_t to, std::queue<uint32_t> flit) {
    this->to_bus_read[to - 1].push_back(flit);
}

void NetworkManager::queueBusWrite(uint8_t to, uint32_t addr, uint32_t data) {
    this->to_bus_write[to - 1].push(std::make_pair(addr, data));
}

void NetworkManager::reset() {
    this->curr_id = {};
    this->to_bus_write = {};
    this->to_bus_read = {};
}

void NetworkManager::reportRemainingCheck() {
    for (int tile = 0; tile < 4; tile++) {
        printf("Remaining for tile %d: %zu\n", tile + 1, this->to_bus_read[tile].size());
    }
}

void NetworkManager::eval_step() {
    // Handle bus writes
    for (int i = 0; i < 4; i++) {
        if (!dut->ren[i] && !dut->request_stall[i]) {
            if (dut->wen[i]) {
                dut->wen[i] = 0;
                dut->addr[i] = 0;
                this->to_bus_write[i].pop();
            } else if (!this->to_bus_write[i].empty()) {
                uint32_t addr = std::get<0>(this->to_bus_write[i].front());
                uint32_t data = std::get<1>(this->to_bus_write[i].front());
                dut->wen[i] = 1;
                dut->wdata[i] = data;
                dut->addr[i] = addr;
            }
        }
    }
}

void NetworkManager::eval_end_step() {
    // Handle bus reads
}

bool NetworkManager::isComplete() {
    uint32_t to_be_sent = 0;
    uint32_t to_check = 0;
    for (auto s : this->to_bus_write) {
        to_be_sent += s.size();
    }
    for (auto s : this->to_bus_read) {
        to_check += s.size();
    }
    return to_be_sent == 0 && to_check == 0;
}
