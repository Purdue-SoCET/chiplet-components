#include "NetworkManager.h"
#include "Vtile_wrapper.h"
#include "utility.h"
#include <span>
#include <string>

extern Vtile_wrapper *dut;

// `from` is 1-indexed
void NetworkManager::queuePacketSend(uint8_t from, const std::span<uint32_t> &flit) {
    uint32_t addr = 0x2000 + (0x80 * this->curr_id[from - 1]);
    for (auto f : flit) {
        this->to_bus_write[from - 1].push(std::make_pair(addr, f));
        addr += 4;
    }
    this->to_bus_write[from - 1].push(std::make_pair(ENDPOINT_SEND_ADDR, this->curr_id[from - 1]));
    this->curr_id[from - 1] = (this->curr_id[from - 1] + 1) % 4;
}

// `from` is 1-indexed
void NetworkManager::queuePacketCheck(uint8_t from, std::queue<uint32_t> flit) {
    this->to_check[from - 1].push_back(flit);
}

void NetworkManager::queueBusWrite(uint8_t to, uint32_t addr, uint32_t data) {
    this->to_bus_write[to - 1].push(std::make_pair(addr, data));
}

void NetworkManager::reset() {
    this->to_check = {};
    this->curr_id = {};
    this->to_bus_write = {};
    this->to_bus_read = {};
}

void NetworkManager::reportRemainingCheck() {
    for (int tile = 0; tile < 4; tile++) {
        printf("Remaining for tile %d\n", tile + 1);
        /*
        if (this->to_be_sent[tile].size() != 0) {
            printf("Switch %d still has packets to send!\n", tile);
        }
        */
        for (auto packet : this->to_check[tile]) {
            for (; !packet.empty(); packet.pop()) {
                printf("%08x, ", packet.front());
            }
            printf("\n");
        }
        printf("\n");
    }
}

void NetworkManager::eval_step() {
    static bool last_from_bus_write = 0;
    // Handle bus writes
    for (int i = 0; i < 4; i++) {
        if (!dut->ren[i] && !dut->request_stall[i]) {
            if (dut->wen[i]) {
                dut->wen[i] = 0;
                dut->addr[i] = 0;
                if (last_from_bus_write) {
                    this->to_bus_write[i].pop();
                } else {
                    /*
                    this->to_be_sent[i].front().pop();
                    if (this->to_be_sent[i].front().empty()) {
                        this->to_be_sent[i].pop();
                    }
                    */
                }
            } else if (!this->to_bus_write[i].empty()) {
                uint32_t addr = std::get<0>(this->to_bus_write[i].front());
                uint32_t data = std::get<1>(this->to_bus_write[i].front());
                dut->wen[i] = 1;
                dut->wdata[i] = data;
                dut->addr[i] = addr;
                last_from_bus_write = 1;
            } /* else if (!this->to_be_sent[i].empty()) {
                dut->wen[i] = 1;
                dut->wdata[i] = this->to_be_sent[i].front().front();
                dut->addr[i] = 0;
                last_from_bus_write = 0;
            } */
        }
    }
    /*
    // Check outputs
    for (int i = 0; i < 4; i++) {
        dut->packet_sent[i] = 0;
        if (dut->data_ready_out[i] && this->to_check[i].size() > 0) {
            std::vector<uint64_t> expected;
            for (auto possible_packets : this->to_check[i]) {
                expected.push_back(possible_packets.front() & FLIT_MASK);
            }
            std::string test_name = "Expected output from test ";
            test_name += std::to_string(i + 1);
            int found =
                ensure<uint64_t>(dut->out[i] & FLIT_MASK, expected, test_name.c_str(), false);
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
            this->buffer_occupancy[i] += 3 * BUFFER_SIZE / 4;
        }
    }

    // Update any inputs
    for (int i = 0; i < 4; i++) {
        dut->in_flit[i] = 0;
        dut->data_ready_in[i] = 0;
        auto to_be_sent = this->to_be_sent[i].front();
        auto vc = (to_be_sent >> 39) & 1;
        if (!dut->data_ready_in[i] && this->to_be_sent[i].size() &&
            this->buffer_occupancy[vc * 4 + i] > (BUFFER_SIZE / 4)) {
            this->to_be_sent[i].pop();
            this->buffer_occupancy[vc * 4 + i]--;
            // std::cout << "Putting data 0x" << std::hex << to_be_sent << std::dec << " on switch "
            //           << i + 1 << std::endl;
            dut->in_flit[i] = to_be_sent;
            dut->data_ready_in[i] = 1;
        }
    }
    */
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
    for (auto s : this->to_check) {
        to_check += s.size();
    }
    return to_be_sent == 0 && to_check == 0;
}
