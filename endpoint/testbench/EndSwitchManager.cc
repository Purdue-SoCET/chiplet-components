#include "NetworkManager.h"
#include "Vswitch_endpoint_wrapper.h"
#include "utility.h"
#include <span>
#include <string>

extern Vswitch_wrapper *dut;

// `from` is 1-indexed
void NetworkManager::queuePacketSend(uint8_t from, const std::span<uint64_t> &flit) {
    for (auto f : flit) {
        this->to_be_sent[from - 1].push(f);
    }
}

// `from` is 1-indexed
void NetworkManager::queuePacketCheck(uint8_t from, std::queue<uint32_t> flit) {
    this->to_check[from - 1].push_back(flit);
}

void NetworkManager::reset() {
    this->to_be_sent = {};
    this->to_check = {};
    this->buffer_occupancy = {8, 8, 8, 8, 8, 8, 8, 8};
}

void NetworkManager::tick() {
    // Check outputs
    for (int i = 0; i < 4; i++) {
        dut->packet_sent[i] = 0;
        if (dut->data_ready_out[i] && this->to_check[i].size() > 0) {
            std::cout << "Checking data from switch " << i + 1 << std::endl;
            std::vector<uint32_t> expected;
            for (auto possible_packets : this->to_check[i]) {
                expected.push_back(possible_packets.front());
            }
            std::string test_name = "Expected output from test ";
            test_name += std::to_string(i);
            int found = ensure(dut->out[i] & 0xFFFFFFFF, expected, test_name.c_str());
            if (found >= 0) {
                this->to_check[i][found].pop();
                if (this->to_check[i][found].empty()) {
                    this->to_check[i].erase(this->to_check[i].begin() + found);
                }
            }
            dut->packet_sent[i] = 1;
        }
    }
    for (int i = 0; i < 8; i++) {
        if (dut->buffer_available[i]) {
            this->buffer_occupancy[i] += 6;
        }
    }

    // Update any inputs
    for (int i = 0; i < 4; i++) {
        // dut->in_flit = 0;
        // dut->data_ready_in = 0;
        // bus inputs to endpoint
        dut->wen = 0;
        dut->ren = 0;
        dut->addr = 0;
        dut->wdata = 0;
        dut->strobe = 0;

        auto to_be_sent = this->to_be_sent[i].front();
        auto vc = to_be_sent >> 39;
        if (this->to_be_sent[i].size() && this->buffer_occupancy[vc * 4 + i] > 2) {
            this->to_be_sent[i].pop();
            this->buffer_occupancy[vc * 4 + i]--;
            std::cout << "Putting data 0x" << std::hex << to_be_sent << std::dec << " on switch "
                      << i + 1 << std::endl;
            dut->in_flit[i] = to_be_sent;
            dut->data_ready_in[i] = 1;
            // dut->wen = 0;
            // dut->ren = 0;
            // dut->addr = 0;
            // dut->wdata = 0;
            // dut->strobe = 0;
        }
    }
}

bool NetworkManager::isComplete() {
    uint32_t to_be_sent = 0;
    uint32_t to_check = 0;
    for (auto s : this->to_be_sent) {
        to_be_sent += s.size();
    }
    for (auto s : this->to_check) {
        to_check += s.size();
    }
    return to_be_sent == 0 && to_check == 0;
}