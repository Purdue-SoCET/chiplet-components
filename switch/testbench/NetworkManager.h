#ifndef NETWORK_MANAGER_H
#define NETWORK_MANAGER_H

#include <array>
#include <cstdint>
#include <queue>
#include <span>

// The network manager class maintains queues of flits to be sent into switches and checks values
// across the network
class NetworkManager {
    std::array<std::queue<uint32_t>, 4> to_be_sent;
    std::array<std::queue<uint32_t>, 4> to_check;

  public:
    NetworkManager() : to_be_sent(), to_check() {}

    void queuePacketSend(uint8_t from, const std::span<uint32_t> &flit);
    void queuePacketCheck(uint8_t to, const std::span<uint32_t> &flit);
    void tick();

    bool isComplete();
};

#endif