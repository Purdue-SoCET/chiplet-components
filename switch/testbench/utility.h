#pragma once

#include <span>
#include <stdint>

int ensure(uint32_t actual, const std::span<uint32_t> &expected, const char *test_name);
