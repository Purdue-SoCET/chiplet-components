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
    if (to == 2) {
        this->to_check[to - 1].push_back(flit);
    }
}

void NetworkManager::reset() {
    this->to_be_sent = {};
    this->to_check = {};
    this->buffer_occupancy = {8, 8, 8, 8, 8, 8, 8, 8};
}

void NetworkManager::tick() {
    static int packets_taken = 0;
    // Check outputs
    dut->packet_sent = 0;
    dut->credit_granted = 0;
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
        packets_taken++;
        if (packets_taken == 6) {
            dut->credit_granted = 1;
            packets_taken = 0;
        }
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
                    dut->wdata = this->curr_id;
                    this->curr_id = (this->curr_id + 1) % 4;
                }
            } else {
                if (!dut->wen) dut->addr = 0x2000 + (0x80 * this->curr_id);
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
        this->to_be_sent[1].front().pop();
        if (this->to_be_sent[1].front().empty()) {
            this->to_be_sent[1].pop();
        }
        this->buffer_occupancy[vc * 4 + 1]--;
        std::cout << "Putting data 0x" << std::hex << to_be_sent << std::dec << " on switch " << 2
                  << std::endl;
        dut->in_flit = to_be_sent;
        dut->data_ready_in = 1;
    }
}

void NetworkManager::reportRemainingCheck() {
    for (int sw = 0; sw < 2; sw++) {
        printf("Remaining for switch %d\n", sw + 1);
        if (this->to_be_sent[sw].size() != 0) {
            printf("Switch %d still has %d packets to send!\n", sw, this->to_be_sent[sw].size());
        }
        for (auto packet : this->to_check[sw]) {
            for (; !packet.empty(); packet.pop()) {
                printf("%08llx, ", packet.front());
            }
            printf("\n");
        }
        printf("\n");
    }
}

bool NetworkManager::isComplete() {
    uint32_t to_be_sent = 0;
    uint32_t to_check = 0;
    for (auto s : this->to_be_sent) {
        to_be_sent += s.size();
    }
    for (auto s : this->to_check) {
        for (auto ss : s) {
            to_check += ss.size();
        }
    }
    return to_be_sent == 0 && to_check == 0;
}
