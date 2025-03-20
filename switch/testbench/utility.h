#pragma once

#include <cstdint>
#include <iostream>
#include <span>

#define FLIT_MASK 0x7FFFFFFFFF

#define DATELINE_ADDR 0x11
#define NODE_ID_ADDR 0x12

template <typename T>
int ensure(T actual, const std::span<T> &expected, const char *test_name, bool print_on_success) {
    extern uint64_t fails;
    extern uint64_t sim_time;
    bool found = false;
    int i = 0;
    for (i = 0; i < expected.size(); i++) {
        if (actual == expected[i]) {
            if (print_on_success) {
                std::cout << "[PASS] "
                          << "Time " << sim_time << "\t" << test_name << std::endl;
            }
            found = true;
            break;
        }
    }
    if (!found) {
        std::cout << "[FAIL] "
                  << "Time " << sim_time << "\t" << test_name << std::hex << ": Actual: " << actual
                  << std::dec << "\nExpected:" << std::endl;
        for (auto e : expected) {
            std::cout << std::hex << e << std::dec << std::endl;
        }
        fails++;
        i = -1;
    }
    return i;
}
