#pragma once

class SmallWrite {
  public:
    uint64_t len : 4;
    uint64_t addr : 19;
    uint64_t dest : 5;
    uint64_t fmt : 4;
    uint64_t req : 5;
    uint64_t id : 2;
    bool vc;

  public:
    SmallWrite(uint8_t req, uint8_t dest, uint8_t len, uint32_t addr, bool vc)
        : fmt(0x9), dest(dest), addr(addr >> 2), len(len == 16 ? 0 : len), req(req), id(0), vc(vc) {
    }

    operator uint64_t() {
        return (((uint64_t)this->vc) << 39) | (((uint64_t)this->id) << 37) |
               (((uint64_t)this->req) << 32) | (((uint64_t)this->fmt) << 28) |
               (((uint64_t)this->dest) << 23) | (((uint64_t)this->addr) << 4) |
               (((uint64_t)this->len));
    }
} __attribute__((packed)) __attribute__((aligned(8)));

class ConfigPkt {
  public:
    uint64_t data_lo : 7;
    uint8_t addr;
    uint8_t data_hi;
    uint64_t dest : 5;
    uint64_t fmt : 4;
    uint64_t req : 5;
    uint64_t id : 2;
    bool vc;
    uint64_t reserved : 24;

  public:
    ConfigPkt(uint8_t req, uint8_t dest, uint8_t addr, uint16_t data)
        : fmt(0x4), dest(dest), data_hi(data >> 7), addr(addr), data_lo(data & 0x7F), req(req),
          id(0), vc(0), reserved(0) {}

    operator uint64_t() {
        return (((uint64_t)this->vc) << 39) | (((uint64_t)this->id) << 37) |
               (((uint64_t)this->req) << 32) | (((uint64_t)this->fmt) << 28) |
               (((uint64_t)this->dest) << 23) | (((uint64_t)this->data_hi) << 15) |
               (((uint64_t)this->addr) << 7) | (((uint64_t)this->data_lo));
    }
} __attribute__((packed)) __attribute__((aligned(8)));
