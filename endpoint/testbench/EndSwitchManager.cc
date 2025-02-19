#include "NetworkManager.h"
#include "Vswitch_endpoint_wrapper.h"
#include "utility.h"
#include <span>
#include <string>

#define FLIT_MASK 0x7FFFFFFFF

extern Vswitch_endpoint_wrapper *dut;

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
    if (/* need some register to see if there's data available */ false) {
        // TODO: read and see if the data matches up
    }
    dut->packet_sent = 0;
    if (dut->data_ready_out && this->to_check[1].size() > 0) {
        std::vector<uint32_t> expected;
        for (auto possible_packets : this->to_check[1]) {
            expected.push_back(possible_packets.front());
        }
        std::string test_name = "Expected output from direct switch";
        int found = ensure(dut->out & FLIT_MASK, expected, test_name.c_str());
        if (found >= 0) {
            this->to_check[1][found].pop();
            if (this->to_check[1][found].empty()) {
                this->to_check[1].erase(this->to_check[i].begin() + found);
            }
        }
        dut->packet_sent[1] = 1;
    }

    // Update any inputs
    // Handle bus side
    if (!dut->ren && !dut->request_stall) {
        if (dut->wen) {
            this->to_be_sent[0].pop();
            dut->wen = 0;
        }
        if (this->to_be_sent[0].size()) {
            dut->wen = 1;
            dut->wdata = this->to_be_sent;
        }
    }

    // Handle direct switch side
    dut->data_ready_in = 0;
    if (this->to_be_sent[1].size()) {
        auto to_be_sent = this->to_be_sent[i].front();
        auto vc = to_be_sent >> 39;
        if (this->buffer_occupancy[vc * 4 + i] > 2) {
            this->to_be_sent[i].pop();
            this->buffer_occupancy[vc * 4 + i]--;
            std::cout << "Putting data 0x" << std::hex << to_be_sent << std::dec << " on switch "
                      << i + 1 << std::endl;
            dut->in_flit = to_be_sent;
            dut->data_ready_in = 1;
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
