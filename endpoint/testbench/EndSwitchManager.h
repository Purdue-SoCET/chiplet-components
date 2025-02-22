#ifndef NETWORK_MANAGER_H
#define NETWORK_MANAGER_H

#include <array>
#include <cstdint>
#include <queue>
#include <span>

#define BUFFER_SIZE 8

// The network manager class maintains queues of flits to be sent into switches and checks values
// across the network
class NetworkManager {
    std::array<std::queue<std::queue<uint32_t>>, 2> to_be_sent;
    std::array<uint16_t, 8> buffer_occupancy;
    std::array<std::vector<std::queue<uint32_t>>, 2> to_check;
    uint8_t curr_id;

  public:
    NetworkManager()
        : to_be_sent(), buffer_occupancy({BUFFER_SIZE, BUFFER_SIZE, BUFFER_SIZE, BUFFER_SIZE,
                                          BUFFER_SIZE, BUFFER_SIZE, BUFFER_SIZE, BUFFER_SIZE}),
          to_check(), curr_id(0) {}

    void queuePacketSend(uint8_t from, std::queue<uint32_t> flit);
    void queuePacketCheck(uint8_t to, std::queue<uint32_t> flit);
    void reportRemainingCheck();
    void tick();
    void reset();

    bool isComplete();
};

#endif
