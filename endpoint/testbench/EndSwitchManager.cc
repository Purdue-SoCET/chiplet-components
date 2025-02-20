#include "EndSwitchManager.h"
#include "Vswitch_endpoint_wrapper.h"
#include "utility.h"
#include <span>
#include <string>

extern Vswitch_endpoint_wrapper *dut;

// `from` is 1-indexed
void NetworkManager::queuePacketSend(uint8_t from, std::queue<uint32_t> flit) {
    this->to_be_sent[from - 1].push(flit);
}

// `from` is 1-indexed
void NetworkManager::queuePacketCheck(uint8_t to, std::queue<uint32_t> flit) {
    this->to_check[to - 1].push_back(flit);
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
        int found = ensure<uint32_t>(dut->out_flit & FLIT_MASK, expected, test_name.c_str());
        if (found >= 0) {
            this->to_check[1][found].pop();
            if (this->to_check[1][found].empty()) {
                this->to_check[1].erase(this->to_check[1].begin() + found);
            }
        }
        dut->packet_sent = 1;
    }

    // Update any inputs
    // Handle bus side
    if (!dut->ren && !dut->request_stall) {
        if (this->to_be_sent[0].size()) {
            if (this->to_be_sent[0].front().empty()) {
                if (dut->addr == 0x1004) {
                    dut->wen = 0;
                    this->to_be_sent[0].pop();
                } else {
                    dut->addr = 0x1004;
                    dut->wen = 1;
                    dut->wdata = 1;
                }
            } else {
                if (!dut->wen) dut->addr = 0x2000;
                else dut->addr += 4;
                dut->wen = 1;
                dut->wdata = this->to_be_sent[0].front().front();
                this->to_be_sent[0].front().pop();
            }
        }
    }

    // Handle direct switch side
    dut->data_ready_in = 0;
    if (this->to_be_sent[1].size()) {
        auto to_be_sent = this->to_be_sent[1].front().front();
        auto vc = 0;
        if (this->buffer_occupancy[vc * 4 + 1] > 2) {
            this->to_be_sent[1].pop();
            this->buffer_occupancy[vc * 4 + 1]--;
            std::cout << "Putting data 0x" << std::hex << to_be_sent << std::dec << " on switch "
                      << 2 << std::endl;
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
