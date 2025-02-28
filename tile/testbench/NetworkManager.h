#ifndef NETWORK_MANAGER_H
#define NETWORK_MANAGER_H

#include "Vtile_wrapper.h"
#include <array>
#include <cstdint>
#include <queue>
#include <span>

#define BUFFER_SIZE 8

// The network manager class maintains queues of flits to be sent into switches and checks values
// across the network
class NetworkManager {
    // std::array<std::queue<std::queue<uint32_t>>, 4> to_be_sent;
    std::array<std::vector<std::queue<uint32_t>>, 4> to_check;
    std::array<uint8_t, 4> curr_id;
    std::array<std::queue<std::pair<uint32_t, uint32_t>>, 4> to_bus_write;
    std::array<std::queue<std::pair<uint32_t, uint32_t>>, 4> to_bus_read;

  public:
    NetworkManager() {}

    void queuePacketSend(uint8_t from, const std::span<uint32_t> &flit);
    void queuePacketCheck(uint8_t to, std::queue<uint32_t> flit);
    void queueBusWrite(uint8_t to, uint32_t addr, uint32_t data);
    void reportRemainingCheck();
    void eval_step();
    void eval_end_step();
    void reset();

    bool isComplete();
};

#endif
