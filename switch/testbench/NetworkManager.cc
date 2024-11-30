#include "NetworkManager.h"
#include "Vswitch_wrapper.h"
#include <string>

extern Vswitch_wrapper *dut;
extern void ensure(uint32_t actual, uint32_t expected, const char *test_name);

void NetworkManager::queuePacketSend(uint8_t from, const std::span<uint32_t> &flit) {
    for (auto f : flit) {
        this->to_be_sent[from].push(f);
    }
}

void NetworkManager::queuePacketCheck(uint8_t from, const std::span<uint32_t> &flit) {
    for (auto f : flit) {
        this->to_be_sent[from].push(f);
    }
}

void NetworkManager::tick() {
    // Check outputs
    for (int i = 0; i < 4; i++) {
        dut->packet_sent[i] = 0;
        if (dut->data_ready_out[i] && this->to_check[i].size() > 0) {
            std::cout << "Checking data from switch " << i << std::endl;
            auto expected = this->to_check[i].front();
            this->to_check[i].pop();
            std::string test_name = "Expected output from test ";
            test_name += std::to_string(i);
            ensure(dut->out[i] & 0xFFFFFFFF, expected, test_name.c_str());
            dut->packet_sent[i] = 1;
        }
    }

    // Update any inputs
    for (int i = 0; i < 4; i++) {
        dut->in_flit[i] = 0;
        dut->data_ready_in[i] = 0;
        if (this->to_be_sent[i].size()) {
            std::cout << "Putting data on switch " << i << std::endl;
            auto to_be_sent = this->to_be_sent[i].front();
            this->to_be_sent[i].pop();
            dut->in_flit[i] = to_be_sent;
            dut->data_ready_in[i] = 1;
        }
    }
}

bool NetworkManager::isComplete() {
    return this->to_be_sent.size() == 0 && this->to_check.size() == 0;
}
