#include "utility.h"

#include <iostream>
#include <span>

extern int fails;
extern int sim_time;

int ensure(uint32_t actual, const std::span<uint32_t> &expected, const char *test_name) {
    bool found = false;
    int i = 0;
    for (i = 0; i < expected.size(); i++) {
        if (actual == expected[i]) {
            std::cout << "[PASS] "
                      << "Time " << sim_time << "\t" << test_name << std::endl;
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
