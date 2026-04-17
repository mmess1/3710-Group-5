#include <SDL.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

constexpr int VISIBLE_W = 640;
constexpr int VISIBLE_H = 480;
constexpr int DEBUG_H = 92;
constexpr int MEM_WORDS = 1024;

constexpr int DEFAULT_CPU_HZ = 50'000'000;
constexpr int DEFAULT_PIXEL_HZ = 25'000'000;
constexpr double DEFAULT_FRAME_HZ = 60.0;

constexpr int FLAG_L = 4;
constexpr int FLAG_C = 3;
constexpr int FLAG_F = 2;
constexpr int FLAG_Z = 1;
constexpr int FLAG_N = 0;

constexpr uint8_t OP_WAIT = 0x00;
constexpr uint8_t OP_AND = 0x01;
constexpr uint8_t OP_OR = 0x02;
constexpr uint8_t OP_XOR = 0x03;
constexpr uint8_t OP_NOT = 0x04;
constexpr uint8_t OP_ADD = 0x05;
constexpr uint8_t OP_ADDU = 0x06;
constexpr uint8_t OP_ADDC = 0x07;
constexpr uint8_t OP_RSH = 0x08;
constexpr uint8_t OP_SUB = 0x09;
constexpr uint8_t OP_SUBC = 0x0A;
constexpr uint8_t OP_CMP = 0x0B;
constexpr uint8_t OP_LSH = 0x0C;
constexpr uint8_t OP_MOV = 0x0D;
constexpr uint8_t OP_MUL = 0x0E;
constexpr uint8_t OP_ARSH = 0x0F;
constexpr uint8_t OP_LOAD = 0x40;
constexpr uint8_t OP_STORE = 0x44;
constexpr uint8_t OP_ADDI = 0x50;
constexpr uint8_t OP_ADDUI = 0x60;
constexpr uint8_t OP_ADDCI = 0x70;
constexpr uint8_t OP_RSHI = 0x80;
constexpr uint8_t OP_SUBI = 0x90;
constexpr uint8_t OP_SUBCI = 0xA0;
constexpr uint8_t OP_CMPI = 0xB0;
constexpr uint8_t OP_BRANCH = 0xC0; // actual fsm bug collides with lshi
constexpr uint8_t OP_MOVI = 0xD0;
constexpr uint8_t OP_MULI = 0xE0;
constexpr uint8_t OP_ARSHI = 0xF0;

constexpr int PADDLE_W = 10;
constexpr int PADDLE_H = 45;
constexpr int PLAYER1_X = 30;
constexpr int PLAYER2_X = 610;
constexpr int BALL_SIZE = 9;

constexpr int SCORE_Y = 40;
constexpr int SCORE1_X_ONES = 220;
constexpr int SCORE1_X_TENS = SCORE1_X_ONES - 10 * 5;
constexpr int SCORE2_X_TENS = 380;
constexpr int DIGIT_SCALE = 8;
constexpr int DIGIT_W = 5 * DIGIT_SCALE;
constexpr int DIGIT_H = 5 * DIGIT_SCALE;

constexpr int MODE_START = 0;
constexpr int MODE_PLAY = 1;
constexpr int MODE_P1_WIN = 2;
constexpr int MODE_P2_WIN = 3;

enum class PaddleMode {
    Human,
    Ai,
};

struct Options {
    std::string binPath = "pong_c.bin";
    bool play = false;
    PaddleMode leftMode = PaddleMode::Human;
    PaddleMode rightMode = PaddleMode::Ai;
    double fps = DEFAULT_FRAME_HZ;
    int scale = 2;
    int p1 = 200;
    int p2 = 200;
    int paddleSpeed = 8;
    std::uint64_t instructions = 0;
    std::string tracePath;
    int traceRows = 1000;
    bool noAutoStart = false;
    int cpuHz = DEFAULT_CPU_HZ;
    int pixelHz = DEFAULT_PIXEL_HZ;
    int cpuDiv = 256;
    bool hideDebug = false;
    int maxChunkInstr = 20000;
    bool vsync = true;
};

std::uint16_t u16(std::int64_t x) {
    return static_cast<std::uint16_t>(x & 0xFFFF);
}

std::int16_t s16(std::uint16_t x) {
    return static_cast<std::int16_t>(x);
}

std::int8_t s8(std::uint8_t x) {
    return static_cast<std::int8_t>(x);
}

std::string trim(const std::string& s) {
    auto a = s.find_first_not_of(" \t\r\n");
    if (a == std::string::npos) return "";
    auto b = s.find_last_not_of(" \t\r\n");
    return s.substr(a, b - a + 1);
}

bool startsWith(const std::string& s, const std::string& prefix) {
    return s.rfind(prefix, 0) == 0;
}

std::uint16_t bitsToInt(const std::string& input) {
    std::string text = trim(input);
    if (text.empty()) throw std::runtime_error("empty instruction line");

    bool binary = true;
    for (char c : text) {
        if (c != '0' && c != '1') {
            binary = false;
            break;
        }
    }

    std::size_t pos = 0;
    unsigned long value = 0;
    if (binary) {
        value = std::stoul(text, &pos, 2);
    } else {
        value = std::stoul(text, &pos, 0);
    }
    return static_cast<std::uint16_t>(value & 0xFFFFu);
}

std::vector<std::uint16_t> loadProgram(const std::string& path) {
    std::ifstream in(path);
    if (!in) {
        throw std::runtime_error("failed to open bin file: " + path);
    }
    std::vector<std::uint16_t> out;
    std::string line;
    while (std::getline(in, line)) {
        std::string t = trim(line);
        if (t.empty()) continue;
        if (startsWith(t, "//") || startsWith(t, "#")) continue;
        out.push_back(bitsToInt(t));
    }
    return out;
}

struct Decoded {
    std::uint8_t upper = 0;
    std::uint8_t ext = 0;
    std::uint8_t opcode = 0;
    std::uint8_t rdest = 0;
    std::uint8_t rsrc = 0;
    std::uint8_t imm8 = 0;
    std::int16_t imm16 = 0;
};

struct Rgba {
    std::uint8_t r;
    std::uint8_t g;
    std::uint8_t b;
    std::uint8_t a;
};

class Sim {
public:
    explicit Sim(const std::vector<std::uint16_t>& program, int cpuHz, int pixelHz, int p1, int p2, bool autoStart)
        : cpuHz_(cpuHz), pixelHz_(pixelHz) {
        bootMemory_.fill(0);
        for (std::size_t i = 0; i < program.size() && i < bootMemory_.size(); ++i) {
            bootMemory_[i] = program[i];
        }
        reset(p1, p2, autoStart);
    }

    void reset(int p1 = -1, int p2 = -1, bool autoStart = true) {
        memory_ = bootMemory_;
        regs_.fill(0);
        flags_ = 0;
        savedFlags_ = 0;
        pc_ = 0;
        cycle_ = 0;
        retired_ = 0;
        lastInstr_ = 0;
        lastOpcode_ = 0;
        lastInstrCycles_ = 0;

        if (p1 >= 0) p1Input_ = p1 & 0x1FF;
        if (p2 >= 0) p2Input_ = p2 & 0x1FF;
        gameStarted_ = autoStart;
        winnerMode_ = 0;
        mmioFF00_ = static_cast<std::uint16_t>(p1Input_);
        mmioFF01_ = static_cast<std::uint16_t>(p2Input_);
        sampleInputs();
        updateTopWrapper();
    }

    void setInputs(int p1, int p2) {
        p1Input_ = p1 & 0x1FF;
        p2Input_ = p2 & 0x1FF;
        mmioFF00_ = static_cast<std::uint16_t>(p1Input_);
        mmioFF01_ = static_cast<std::uint16_t>(p2Input_);
    }

    void startGame() { gameStarted_ = true; }

    int screenMode() const {
        if (!gameStarted_) return MODE_START;
        if (winnerMode_) return winnerMode_;
        return MODE_PLAY;
    }

    int clampPaddle(int y) const {
        return std::max(0, std::min(VISIBLE_H - PADDLE_H, y));
    }

    int singleStep() { return stepRetiredFast(); }

    void runInstructions(std::uint64_t count) {
        for (std::uint64_t i = 0; i < count; ++i) {
            stepRetiredFast();
        }
    }

    std::uint64_t runCyclesBudget(std::uint64_t budget, int maxChunkInstr) {
        std::uint64_t done = 0;
        while (done < budget) {
            int batch = std::min(maxChunkInstr, std::max(256, static_cast<int>((budget - done) / 3 + 8)));
            std::uint64_t before = cycle_;
            runInstructions(static_cast<std::uint64_t>(batch));
            std::uint64_t delta = cycle_ - before;
            if (delta == 0) break;
            done += delta;
            if (winnerMode_) break;
        }
        return done;
    }

    void saveTraceCsv(const std::string& path, int rows) {
        std::ofstream out(path);
        if (!out) throw std::runtime_error("failed to open trace file: " + path);
        out << "cycle,retired,pc,instr,opcode,flags,saved_flags";
        for (int i = 0; i < 16; ++i) out << ",r" << i;
        out << "\n";
        for (int i = 0; i < rows; ++i) {
            out << cycle_ << ',' << retired_ << ','
                << hex4(pc_) << ',' << hex4(lastInstr_) << ',' << hex2(lastOpcode_) << ','
                << bin5(flags_) << ',' << bin5(savedFlags_);
            for (int r = 0; r < 16; ++r) out << ',' << hex4(regs_[r]);
            out << '\n';
            stepRetiredFast();
        }
    }

    double fpgaTimeSeconds() const {
        return static_cast<double>(cycle_) / static_cast<double>(cpuHz_);
    }

    int cpuHz() const { return cpuHz_; }
    int pixelHz() const { return pixelHz_; }
    std::uint64_t cycle() const { return cycle_; }
    std::uint64_t retired() const { return retired_; }
    std::uint16_t pc() const { return pc_; }
    std::uint16_t lastInstr() const { return lastInstr_; }
    std::uint8_t lastOpcode() const { return lastOpcode_; }
    int lastInstrCycles() const { return lastInstrCycles_; }
    std::uint8_t flags() const { return flags_; }
    std::uint8_t savedFlags() const { return savedFlags_; }
    bool gameStarted() const { return gameStarted_; }
    int winnerMode() const { return winnerMode_; }
    int p1Input() const { return p1Input_; }
    int p2Input() const { return p2Input_; }
    const std::array<std::uint16_t, 16>& regs() const { return regs_; }

private:
    static std::string hex4(std::uint16_t v) {
        std::ostringstream ss;
        ss << "0x" << std::uppercase << std::hex << std::setfill('0') << std::setw(4) << static_cast<unsigned>(v);
        return ss.str();
    }

    static std::string hex2(std::uint8_t v) {
        std::ostringstream ss;
        ss << "0x" << std::uppercase << std::hex << std::setfill('0') << std::setw(2) << static_cast<unsigned>(v);
        return ss.str();
    }

    static std::string bin5(std::uint8_t v) {
        std::string s = "0b00000";
        for (int i = 0; i < 5; ++i) {
            s[6 - i] = ((v >> i) & 1u) ? '1' : '0';
        }
        return s;
    }

    void sampleInputs() {
        regs_[1] = static_cast<std::uint16_t>(p1Input_ & 0x1FF);
        regs_[3] = static_cast<std::uint16_t>(p2Input_ & 0x1FF);
    }

    void updateTopWrapper() {
        if (regs_[4] >= 15) {
            winnerMode_ = MODE_P1_WIN;
        } else if (regs_[5] >= 15) {
            winnerMode_ = MODE_P2_WIN;
        } else {
            winnerMode_ = 0;
        }
    }

    Decoded decode(std::uint16_t word) const {
        Decoded d;
        d.upper = static_cast<std::uint8_t>((word >> 12) & 0xF);
        d.ext = static_cast<std::uint8_t>((word >> 4) & 0xF);
        d.opcode = (d.upper == 0x0 || d.upper == 0x4) ? static_cast<std::uint8_t>((d.upper << 4) | d.ext) : static_cast<std::uint8_t>(d.upper << 4);
        d.rdest = static_cast<std::uint8_t>((word >> 8) & 0xF);
        d.rsrc = static_cast<std::uint8_t>(word & 0xF);
        d.imm8 = static_cast<std::uint8_t>(word & 0xFF);
        d.imm16 = static_cast<std::int16_t>(s8(d.imm8));
        return d;
    }

    std::uint16_t readMmio(std::uint16_t addr) const {
        if (addr == 0xFF00) return static_cast<std::uint16_t>(mmioFF00_ & 0x1FF);
        if (addr == 0xFF01) return static_cast<std::uint16_t>(mmioFF01_ & 0x1FF);
        if (addr == 0xFF10) return static_cast<std::uint16_t>(p1Input_ & 0x1FF);
        if (addr == 0xFF11) return static_cast<std::uint16_t>(p2Input_ & 0x1FF);
        return 0;
    }

    void writeMmio(std::uint16_t addr, std::uint16_t value) {
        if (addr == 0xFF00) mmioFF00_ = static_cast<std::uint16_t>(value & 0x1FF);
        if (addr == 0xFF01) mmioFF01_ = static_cast<std::uint16_t>(value & 0x1FF);
    }

    bool checkFlags(std::uint8_t cond) const {
        std::uint8_t z = (savedFlags_ >> FLAG_Z) & 1u;
        std::uint8_t n = (savedFlags_ >> FLAG_N) & 1u;
        std::uint8_t f = (savedFlags_ >> FLAG_F) & 1u;
        std::uint8_t c = (savedFlags_ >> FLAG_C) & 1u;
        std::uint8_t l = (savedFlags_ >> FLAG_L) & 1u;

        switch (cond) {
            case 0x0: return z == 1;
            case 0x1: return z == 0;
            case 0x2: return c == 1;
            case 0x3: return c == 0;
            case 0x4: return l == 1;
            case 0x5: return l == 0;
            case 0x6: return n == 1;
            case 0x7: return n == 0;
            case 0x8: return f == 1;
            case 0x9: return f == 0;
            case 0xA: return (l == 0) && (z == 0);
            case 0xB: return (l == 1) || (z == 1);
            case 0xC: return (n == 0) && (z == 0);
            case 0xD: return (z == 1) || (n == 1);
            case 0xE: return true;
            default: return false;
        }
    }

    std::uint8_t packFlags(int l, int c, int f, int z, int n) const {
        return static_cast<std::uint8_t>(((l & 1) << FLAG_L) | ((c & 1) << FLAG_C) | ((f & 1) << FLAG_F) | ((z & 1) << FLAG_Z) | ((n & 1) << FLAG_N));
    }

    std::pair<std::uint16_t, std::uint8_t> execAlu(std::uint8_t opcode, std::uint8_t rdest, std::uint8_t rsrc, std::int16_t imm16, std::uint8_t upper) {
        std::uint16_t rd = regs_[rdest];
        std::uint16_t rs = (upper != 0x0 && upper != 0x4) ? static_cast<std::uint16_t>(imm16) : regs_[rsrc];

        if (opcode == OP_ADD || opcode == OP_ADDI) {
            std::uint16_t result = u16(static_cast<std::int32_t>(s16(rd)) + static_cast<std::int32_t>(s16(rs)));
            int overflow = ((((rd ^ rs) & 0x8000u) == 0u) && (((result ^ rd) & 0x8000u) != 0u)) ? 1 : 0;
            return {result, packFlags(rd < rs, 0, overflow, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_ADDU || opcode == OP_ADDUI || opcode == OP_ADDC || opcode == OP_ADDCI) {
            std::uint32_t tmp = static_cast<std::uint32_t>(rd) + static_cast<std::uint32_t>(rs);
            std::uint16_t result = static_cast<std::uint16_t>(tmp & 0xFFFFu);
            int carry = tmp > 0xFFFFu ? 1 : 0;
            return {result, packFlags(rd < rs, carry, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_MOV || opcode == OP_MOVI) {
            std::uint16_t result = rs;
            return {result, packFlags(0, 0, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_MUL || opcode == OP_MULI) {
            std::uint32_t prod = static_cast<std::uint32_t>(rd) * static_cast<std::uint32_t>(rs);
            std::uint16_t result = static_cast<std::uint16_t>(prod & 0xFFFFu);
            int carry = (prod >> 16) ? 1 : 0;
            return {result, packFlags(0, carry, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_SUB || opcode == OP_SUBI) {
            std::uint32_t tmp = (static_cast<std::uint32_t>(rd) - static_cast<std::uint32_t>(rs)) & 0x1FFFFu;
            std::uint16_t result = static_cast<std::uint16_t>(tmp & 0xFFFFu);
            int overflow = ((((rd ^ rs) & 0x8000u) != 0u) && (((result ^ rd) & 0x8000u) != 0u)) ? 1 : 0;
            int carry = (tmp >> 16) & 1u;
            return {result, packFlags(rd < rs, carry, overflow, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_SUBC || opcode == OP_SUBCI) {
            return {0, 0};
        }
        if (opcode == OP_AND) {
            std::uint16_t result = rd & rs;
            return {result, packFlags(0, 0, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_OR) {
            std::uint16_t result = rd | rs;
            return {result, packFlags(0, 0, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_XOR) {
            std::uint16_t result = rd ^ rs;
            return {result, packFlags(0, 0, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_NOT) {
            std::uint16_t result = static_cast<std::uint16_t>(~rd);
            return {result, packFlags(0, 0, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_LSH) {
            std::uint16_t result = static_cast<std::uint16_t>((rd << (rs & 0xF)) & 0xFFFFu);
            return {result, packFlags(0, 0, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_RSH || opcode == OP_RSHI) {
            std::uint16_t result = static_cast<std::uint16_t>(rd >> (rs & 0xF));
            return {result, packFlags(0, 0, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_ARSH || opcode == OP_ARSHI) {
            std::uint16_t result = static_cast<std::uint16_t>(static_cast<std::int16_t>(rd) >> (rs & 0xF));
            return {result, packFlags(0, 0, 0, result == 0, (result >> 15) & 1u)};
        }
        if (opcode == OP_CMP || opcode == OP_CMPI) {
            return {rd, packFlags(rd < rs, 0, 0, rd == rs, s16(rd) < s16(rs))};
        }
        if (opcode == OP_WAIT) {
            return {rd, flags_};
        }
        return {0, 0};
    }

    int stepRetiredFast() {
        if (!gameStarted_ || winnerMode_) {
            sampleInputs();
            updateTopWrapper();
            ++cycle_;
            lastInstr_ = 0;
            lastOpcode_ = 0;
            lastInstrCycles_ = 1;
            return 1;
        }

        std::uint16_t word = memory_[pc_ & 0x03FFu];
        Decoded d = decode(word);
        lastInstr_ = word;
        lastOpcode_ = d.opcode;

        int takenCycles = 3;

        if (d.upper == 0x4 && d.ext == 0x4) {
            std::uint16_t addr = regs_[d.rdest];
            std::uint16_t data = regs_[d.rsrc];
            if (addr >= 0xFF00u) {
                writeMmio(addr, data);
            } else {
                memory_[addr & 0x03FFu] = data;
            }
            pc_ = u16(pc_ + 1);
            takenCycles = 3;
        } else if (d.upper == 0x4 && d.ext == 0x0) {
            std::uint16_t addr = regs_[d.rdest];
            std::uint16_t data = addr >= 0xFF00u ? readMmio(addr) : memory_[addr & 0x03FFu];
            regs_[d.rsrc] = data;
            pc_ = u16(pc_ + 1);
            takenCycles = 4;
        } else if (d.upper == 0xC) {
            if (checkFlags(d.rdest)) {
                pc_ = u16(pc_ + d.imm16);
            } else {
                pc_ = u16(pc_ + 1);
            }
            takenCycles = 3;
        } else {
            auto [result, newFlags] = execAlu(d.opcode, d.rdest, d.rsrc, d.imm16, d.upper);
            flags_ = newFlags;
            if (d.opcode == OP_CMP || d.opcode == OP_CMPI) {
                savedFlags_ = newFlags;
            } else if (d.opcode != OP_WAIT) {
                regs_[d.rdest] = result;
            }
            pc_ = u16(pc_ + 1);
            takenCycles = 3;
        }

        ++retired_;
        cycle_ += static_cast<std::uint64_t>(takenCycles);
        lastInstrCycles_ = takenCycles;
        sampleInputs();
        updateTopWrapper();
        return takenCycles;
    }

    std::array<std::uint16_t, MEM_WORDS> bootMemory_{};
    std::array<std::uint16_t, MEM_WORDS> memory_{};
    std::array<std::uint16_t, 16> regs_{};

    int cpuHz_ = DEFAULT_CPU_HZ;
    int pixelHz_ = DEFAULT_PIXEL_HZ;
    std::uint8_t flags_ = 0;
    std::uint8_t savedFlags_ = 0;
    std::uint16_t pc_ = 0;
    std::uint64_t cycle_ = 0;
    std::uint64_t retired_ = 0;
    std::uint16_t lastInstr_ = 0;
    std::uint8_t lastOpcode_ = 0;
    int lastInstrCycles_ = 0;

    int p1Input_ = 200;
    int p2Input_ = 200;
    bool gameStarted_ = true;
    int winnerMode_ = 0;
    std::uint16_t mmioFF00_ = 0;
    std::uint16_t mmioFF01_ = 0;
};

std::unordered_map<char, std::array<std::uint8_t, 7>> makeFont() {
    return {
        {' ', {0,0,0,0,0,0,0}},
        {'-', {0,0,0,31,0,0,0}},
        {'.', {0,0,0,0,0,12,12}},
        {':', {0,12,12,0,12,12,0}},
        {'/', {1,2,4,8,16,0,0}},
        {'0', {14,17,19,21,25,17,14}},
        {'1', {4,12,4,4,4,4,14}},
        {'2', {14,17,1,2,4,8,31}},
        {'3', {30,1,1,14,1,1,30}},
        {'4', {2,6,10,18,31,2,2}},
        {'5', {31,16,16,30,1,1,30}},
        {'6', {14,16,16,30,17,17,14}},
        {'7', {31,1,2,4,8,8,8}},
        {'8', {14,17,17,14,17,17,14}},
        {'9', {14,17,17,15,1,1,14}},
        {'A', {14,17,17,31,17,17,17}},
        {'B', {30,17,17,30,17,17,30}},
        {'C', {14,17,16,16,16,17,14}},
        {'D', {30,17,17,17,17,17,30}},
        {'E', {31,16,16,30,16,16,31}},
        {'F', {31,16,16,30,16,16,16}},
        {'G', {14,17,16,16,19,17,14}},
        {'H', {17,17,17,31,17,17,17}},
        {'I', {14,4,4,4,4,4,14}},
        {'J', {7,2,2,2,2,18,12}},
        {'K', {17,18,20,24,20,18,17}},
        {'L', {16,16,16,16,16,16,31}},
        {'M', {17,27,21,21,17,17,17}},
        {'N', {17,25,21,19,17,17,17}},
        {'O', {14,17,17,17,17,17,14}},
        {'P', {30,17,17,30,16,16,16}},
        {'Q', {14,17,17,17,21,18,13}},
        {'R', {30,17,17,30,20,18,17}},
        {'S', {15,16,16,14,1,1,30}},
        {'T', {31,4,4,4,4,4,4}},
        {'U', {17,17,17,17,17,17,14}},
        {'V', {17,17,17,17,17,10,4}},
        {'W', {17,17,17,21,21,27,17}},
        {'X', {17,17,10,4,10,17,17}},
        {'Y', {17,17,10,4,4,4,4}},
        {'Z', {31,1,2,4,8,16,31}},
        {'=', {0,31,0,31,0,0,0}},
        {'(', {2,4,8,8,8,4,2}},
        {')', {8,4,2,2,2,4,8}},
    };
}

const std::unordered_map<char, std::array<std::uint8_t, 7>> FONT = makeFont();

void setColor(SDL_Renderer* renderer, const Rgba& c) {
    SDL_SetRenderDrawColor(renderer, c.r, c.g, c.b, c.a);
}

void fillRect(SDL_Renderer* renderer, int x, int y, int w, int h, const Rgba& c) {
    SDL_Rect r{x, y, w, h};
    setColor(renderer, c);
    SDL_RenderFillRect(renderer, &r);
}

void drawRect(SDL_Renderer* renderer, int x, int y, int w, int h, const Rgba& c) {
    SDL_Rect r{x, y, w, h};
    setColor(renderer, c);
    SDL_RenderDrawRect(renderer, &r);
}

void drawChar(SDL_Renderer* renderer, int x, int y, char ch, int scale, const Rgba& c) {
    auto it = FONT.find(static_cast<char>(std::toupper(static_cast<unsigned char>(ch))));
    const auto& glyph = (it == FONT.end()) ? FONT.at(' ') : it->second;
    setColor(renderer, c);
    for (int row = 0; row < 7; ++row) {
        for (int col = 0; col < 5; ++col) {
            if ((glyph[row] >> (4 - col)) & 1u) {
                SDL_Rect r{x + col * scale, y + row * scale, scale, scale};
                SDL_RenderFillRect(renderer, &r);
            }
        }
    }
}

void drawText(SDL_Renderer* renderer, int x, int y, const std::string& text, int scale, const Rgba& c) {
    int cx = x;
    int cy = y;
    for (char ch : text) {
        if (ch == '\n') {
            cy += 8 * scale;
            cx = x;
            continue;
        }
        drawChar(renderer, cx, cy, ch, scale, c);
        cx += 6 * scale;
    }
}

constexpr std::uint8_t SCORE_DIGITS[10][5] = {
    {0b11111, 0b10001, 0b10001, 0b10001, 0b11111},
    {0b00100, 0b01100, 0b00100, 0b00100, 0b01110},
    {0b11111, 0b00001, 0b11111, 0b10000, 0b11111},
    {0b11111, 0b00001, 0b01110, 0b00001, 0b11111},
    {0b10001, 0b10001, 0b11111, 0b00001, 0b00001},
    {0b11111, 0b10000, 0b11111, 0b00001, 0b11111},
    {0b11111, 0b10000, 0b11111, 0b10001, 0b11111},
    {0b11111, 0b00001, 0b00010, 0b00100, 0b00100},
    {0b11111, 0b10001, 0b11111, 0b10001, 0b11111},
    {0b11111, 0b10001, 0b11111, 0b00001, 0b11111},
};

bool scoreDigitPixel(int digit, int row, int col) {
    if (digit < 0 || digit > 9) return false;
    return ((SCORE_DIGITS[digit][row] >> (4 - col)) & 1u) != 0u;
}

void drawScoreDigit(SDL_Renderer* renderer, int x, int y, int digit) {
    const Rgba c{255, 255, 255, 255};
    for (int row = 0; row < 5; ++row) {
        for (int col = 0; col < 5; ++col) {
            if (scoreDigitPixel(digit, row, col)) {
                fillRect(renderer, x + col * DIGIT_SCALE, y + row * DIGIT_SCALE, DIGIT_SCALE, DIGIT_SCALE, c);
            }
        }
    }
}

std::string padLeft(const std::string& s, std::size_t width) {
    if (s.size() >= width) return s;
    return std::string(width - s.size(), ' ') + s;
}

std::string fmtHex(std::uint64_t value, int width) {
    std::ostringstream ss;
    ss << "0x" << std::uppercase << std::hex << std::setfill('0') << std::setw(width) << value;
    return ss.str();
}

std::string fmtBin5(std::uint8_t value) {
    std::string out = "00000";
    for (int i = 0; i < 5; ++i) out[4 - i] = ((value >> i) & 1u) ? '1' : '0';
    return out;
}

std::string fmtFloat(double value, int prec = 6) {
    std::ostringstream ss;
    ss << std::fixed << std::setprecision(prec) << value;
    return ss.str();
}

PaddleMode parseMode(const std::string& s) {
    if (s == "human") return PaddleMode::Human;
    if (s == "ai") return PaddleMode::Ai;
    throw std::runtime_error("invalid paddle mode: " + s);
}

class LiveApp {
public:
    LiveApp(Sim& sim, const Options& opt)
        : sim_(sim), opt_(opt) {
        if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_TIMER) != 0) {
            throw std::runtime_error(std::string("SDL_Init failed: ") + SDL_GetError());
        }

        int flags = SDL_WINDOW_SHOWN;
        window_ = SDL_CreateWindow(
            "pong cpu vga sim",
            SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED,
            VISIBLE_W * opt_.scale,
            (VISIBLE_H + DEBUG_H) * opt_.scale,
            flags
        );
        if (!window_) {
            throw std::runtime_error(std::string("SDL_CreateWindow failed: ") + SDL_GetError());
        }

        int rendererFlags = SDL_RENDERER_ACCELERATED;
        if (opt_.vsync) rendererFlags |= SDL_RENDERER_PRESENTVSYNC;
        renderer_ = SDL_CreateRenderer(window_, -1, rendererFlags);
        if (!renderer_) {
            throw std::runtime_error(std::string("SDL_CreateRenderer failed: ") + SDL_GetError());
        }

        SDL_RenderSetLogicalSize(renderer_, VISIBLE_W, VISIBLE_H + DEBUG_H);
        SDL_SetRenderDrawBlendMode(renderer_, SDL_BLENDMODE_BLEND);

        if (opt_.noAutoStart) sim_.reset(opt_.p1, opt_.p2, false);

        lastPerf_ = std::chrono::steady_clock::now();
        cycleLast_ = sim_.cycle();
        accumCycles_ = 0.0;
    }

    ~LiveApp() {
        if (renderer_) SDL_DestroyRenderer(renderer_);
        if (window_) SDL_DestroyWindow(window_);
        SDL_Quit();
    }

    int run() {
        bool running = true;
        while (running) {
            running = handleEvents();
            tick();
            render();
        }
        return 0;
    }

private:
    bool handleEvents() {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) return false;
            if (e.type == SDL_KEYDOWN && !e.key.repeat) {
                switch (e.key.keysym.sym) {
                    case SDLK_w: leftUp_ = true; break;
                    case SDLK_s: leftDown_ = true; break;
                    case SDLK_UP: rightUp_ = true; break;
                    case SDLK_DOWN: rightDown_ = true; break;
                    case SDLK_SPACE: sim_.startGame(); break;
                    case SDLK_p: paused_ = !paused_; break;
                    case SDLK_r: sim_.reset(sim_.p1Input(), sim_.p2Input(), !opt_.noAutoStart); break;
                    case SDLK_1: optLeftMode_ = (optLeftMode_ == PaddleMode::Human) ? PaddleMode::Ai : PaddleMode::Human; break;
                    case SDLK_2: optRightMode_ = (optRightMode_ == PaddleMode::Human) ? PaddleMode::Ai : PaddleMode::Human; break;
                    case SDLK_o: showDebug_ = !showDebug_; break;
                    case SDLK_PERIOD:
                        if (paused_) {
                            applyInputs();
                            sim_.singleStep();
                        }
                        break;
                    default: break;
                }
            }
            if (e.type == SDL_KEYUP) {
                switch (e.key.keysym.sym) {
                    case SDLK_w: leftUp_ = false; break;
                    case SDLK_s: leftDown_ = false; break;
                    case SDLK_UP: rightUp_ = false; break;
                    case SDLK_DOWN: rightDown_ = false; break;
                    default: break;
                }
            }
        }
        // Poll mouse position for player 1 control
        int mouseX, mouseY;
        SDL_GetMouseState(&mouseX, &mouseY);
        mouseY_ = mouseY / opt_.scale;  // Scale mouse coordinates to game space
        return true;
    }

    int aiTarget() const {
        return sim_.clampPaddle(static_cast<int>(sim_.regs()[7]) - PADDLE_H / 2);
    }

    void applyInputs() {
        int p1 = sim_.p1Input();
        int p2 = sim_.p2Input();

        if (optLeftMode_ == PaddleMode::Ai) {
            int target = aiTarget();
            if (p1 < target) p1 = std::min(target, p1 + opt_.paddleSpeed);
            else if (p1 > target) p1 = std::max(target, p1 - opt_.paddleSpeed);
        } else {
            // Use mouse Y position for player 1
            p1 = std::clamp(mouseY_ - PADDLE_H / 2, 0, VISIBLE_H - PADDLE_H);
        }

        if (optRightMode_ == PaddleMode::Ai) {
            int target = aiTarget();
            if (p2 < target) p2 = std::min(target, p2 + opt_.paddleSpeed);
            else if (p2 > target) p2 = std::max(target, p2 - opt_.paddleSpeed);
        } else {
            if (rightUp_ && !rightDown_) p2 -= opt_.paddleSpeed;
            if (rightDown_ && !rightUp_) p2 += opt_.paddleSpeed;
        }

        sim_.setInputs(sim_.clampPaddle(p1), sim_.clampPaddle(p2));
    }

    void tick() {
        auto now = std::chrono::steady_clock::now();
        double dt = std::chrono::duration<double>(now - lastPerf_).count();
        lastPerf_ = now;
        if (dt > 0.250) dt = 0.250;

        if (!paused_) {
            applyInputs();
            accumCycles_ += dt * static_cast<double>(sim_.cpuHz()) / static_cast<double>(opt_.cpuDiv);
            std::uint64_t budget = static_cast<std::uint64_t>(accumCycles_);
            if (budget > 0) {
                std::uint64_t done = sim_.runCyclesBudget(budget, opt_.maxChunkInstr);
                accumCycles_ -= static_cast<double>(done);
                if (accumCycles_ < 0.0) accumCycles_ = 0.0;
            }
        }

        double wallDt = dt > 1e-9 ? dt : 1e-9;
        std::uint64_t cycleDt = sim_.cycle() - cycleLast_;
        cycleLast_ = sim_.cycle();
        measuredCyclesPerSec_ = static_cast<double>(cycleDt) / wallDt;
        
        // Update FPS measurement
        frameCount_++;
        fpsMeasureTime_ += dt;
        if (fpsMeasureTime_ >= 1.0) {
            measuredFps_ = static_cast<double>(frameCount_) / fpsMeasureTime_;
            frameCount_ = 0;
            fpsMeasureTime_ = 0.0;
        }
    }

    void renderPlayfield() {
        fillRect(renderer_, 0, 0, VISIBLE_W, VISIBLE_H, {0, 0, 0, 255});
        fillRect(renderer_, 0, 0, 5, VISIBLE_H, {255, 255, 255, 255});
        fillRect(renderer_, VISIBLE_W - 5, 0, 5, VISIBLE_H, {255, 255, 255, 255});
        fillRect(renderer_, 0, 0, VISIBLE_W, 5, {255, 255, 255, 255});
        fillRect(renderer_, 0, VISIBLE_H - 5, VISIBLE_W, 5, {255, 255, 255, 255});

        if (sim_.screenMode() == MODE_PLAY) {
            for (int y = 0; y < VISIBLE_H; y += 20) {
                fillRect(renderer_, 320, y, 1, 10, {255, 255, 255, 255});
            }

            int p1y = sim_.clampPaddle(sim_.regs()[1]);
            int p2y = sim_.clampPaddle(sim_.regs()[3]);
            int bx = std::clamp<int>(sim_.regs()[6], 0, VISIBLE_W - BALL_SIZE);
            int by = std::clamp<int>(sim_.regs()[7], 0, VISIBLE_H - BALL_SIZE);
            fillRect(renderer_, PLAYER1_X, p1y, PADDLE_W, PADDLE_H, {255, 255, 255, 255});
            fillRect(renderer_, PLAYER2_X, p2y, PADDLE_W, PADDLE_H, {255, 255, 255, 255});
            fillRect(renderer_, bx, by, BALL_SIZE, BALL_SIZE, {240, 100, 0, 255});

            int score1 = static_cast<int>(sim_.regs()[4]);
            int score2 = static_cast<int>(sim_.regs()[5]);
            int score1_tens = score1 / 10;
            int score1_ones = score1 % 10;
            int score2_tens = score2 / 10;
            int score2_ones = score2 % 10;
            int score2_ones_x = SCORE2_X_TENS + (score2_tens ? DIGIT_W : 0);

            if (score1 >= 10) {
                drawScoreDigit(renderer_, SCORE1_X_TENS, SCORE_Y, score1_tens);
            }
            drawScoreDigit(renderer_, SCORE1_X_ONES, SCORE_Y, score1_ones);
            if (score2 >= 10) {
                drawScoreDigit(renderer_, SCORE2_X_TENS, SCORE_Y, score2_tens);
            }
            drawScoreDigit(renderer_, score2_ones_x, SCORE_Y, score2_ones);
        } else if (sim_.screenMode() == MODE_START) {
            drawText(renderer_, 102, 300, "PRESS SPACE TO START", 4, {255, 255, 255, 255});
            drawText(renderer_, 110, 360, "MOUSE LEFT   UP/DOWN RIGHT", 3, {200, 200, 200, 255});
        } else if (sim_.screenMode() == MODE_P1_WIN) {
            drawText(renderer_, 104, 180, "PLAYER 1 WINS", 5, {255, 255, 255, 255});
            drawText(renderer_, 94, 240, "PRESS R TO RESET", 4, {200, 200, 200, 255});
        } else if (sim_.screenMode() == MODE_P2_WIN) {
            drawText(renderer_, 104, 180, "PLAYER 2 WINS", 5, {255, 255, 255, 255});
            drawText(renderer_, 94, 240, "PRESS R TO RESET", 4, {200, 200, 200, 255});
        }
    }

    void renderDebug() {
        fillRect(renderer_, 0, VISIBLE_H, VISIBLE_W, DEBUG_H, {20, 20, 20, 255});
        drawRect(renderer_, 0, VISIBLE_H, VISIBLE_W, DEBUG_H, {70, 70, 70, 255});
        if (!showDebug_) return;

        double realtime = measuredCyclesPerSec_ / static_cast<double>(sim_.cpuHz());
        std::string line1 = "CPU TARGET " + fmtFloat(sim_.cpuHz() / 1e6, 2) + " MHZ   SIM " + fmtFloat(measuredCyclesPerSec_ / 1e6, 3) + " MHZ   REALTIME " + fmtFloat(realtime, 5) + "   FPS " + fmtFloat(measuredFps_, 1);
        std::string line2 = "FPGA TIME " + fmtFloat(sim_.fpgaTimeSeconds(), 6) + " S   CYCLES " + std::to_string(sim_.cycle()) + "   RETIRED " + std::to_string(sim_.retired()) + "   LAST CYC " + std::to_string(sim_.lastInstrCycles());
        std::string line3 = "PC " + fmtHex(sim_.pc(), 4) + "   INSTR " + fmtHex(sim_.lastInstr(), 4) + "   OPC " + fmtHex(sim_.lastOpcode(), 2) + "   FL " + fmtBin5(sim_.flags()) + "   SAVED " + fmtBin5(sim_.savedFlags());
        std::string line4 = "BALL (" + std::to_string(sim_.regs()[6]) + "," + std::to_string(sim_.regs()[7]) + ")   VEL (" + std::to_string(static_cast<std::int16_t>(sim_.regs()[8])) + "," + std::to_string(static_cast<std::int16_t>(sim_.regs()[9])) + ")   DIV " + std::to_string(opt_.cpuDiv);
        std::string line5 = "LEFT " + std::string(optLeftMode_ == PaddleMode::Human ? "HUMAN" : "AI") + "   RIGHT " + std::string(optRightMode_ == PaddleMode::Human ? "HUMAN" : "AI") + "   P PAUSE  R RESET  1/2 TOGGLE AI  O DEBUG  . STEP";

        drawText(renderer_, 0, VISIBLE_H + 4, line1, 1, {230, 230, 230, 255});
        drawText(renderer_, 0, VISIBLE_H + 16, line2, 1, {230, 230, 230, 255});
        drawText(renderer_, 0, VISIBLE_H + 28, line3, 1, {255, 220, 120, 255});
        drawText(renderer_, 0, VISIBLE_H + 40, line4, 1, {200, 255, 200, 255});
        drawText(renderer_, 0, VISIBLE_H + 52, line5, 1, {180, 200, 255, 255});
    }

    void render() {
        setColor(renderer_, {0, 0, 0, 255});
        SDL_RenderClear(renderer_);
        renderPlayfield();
        renderDebug();
        SDL_RenderPresent(renderer_);
    }

    Sim& sim_;
    Options opt_;
    PaddleMode optLeftMode_ = opt_.leftMode;
    PaddleMode optRightMode_ = opt_.rightMode;
    bool showDebug_ = !opt_.hideDebug;

    SDL_Window* window_ = nullptr;
    SDL_Renderer* renderer_ = nullptr;
    bool paused_ = false;
    bool leftUp_ = false;
    bool leftDown_ = false;
    bool rightUp_ = false;
    bool rightDown_ = false;
    int mouseY_ = 0;

    std::chrono::steady_clock::time_point lastPerf_{};
    std::uint64_t cycleLast_ = 0;
    double measuredCyclesPerSec_ = 0.0;
    double accumCycles_ = 0.0;
    
    int frameCount_ = 0;
    double fpsMeasureTime_ = 0.0;
    double measuredFps_ = 0.0;
};

void printUsage() {
    std::cerr
        << "usage:\n"
        << "  pong_cpu_vga_sim [--bin path/to/binary] [options]\n\n"
        << "  Default binary: pong_c.bin\n\n"
        << "options:\n"
        << "  --bin path             binary path (default: pong_c.bin)\n"
        << "  --play                 open live SDL window\n"
        << "  --left human|ai        left paddle mode\n"
        << "  --right human|ai       right paddle mode\n"
        << "  --fps 60               target window refresh rate\n"
        << "  --scale 2              window scale\n"
        << "  --p1 200               initial left paddle input\n"
        << "  --p2 200               initial right paddle input\n"
        << "  --paddle-speed 8       live paddle speed per frame\n"
        << "  --instructions N       headless: run retired instructions\n"
        << "  --trace file.csv       save trace csv\n"
        << "  --trace-rows 1000      trace rows\n"
        << "  --no-auto-start        keep start screen until space\n"
        << "  --cpu-hz 50000000      simulated cpu clock\n"
        << "  --pixel-hz 25000000    simulated pixel clock\n"
        << "  --cpu-div 256          live divider for responsiveness\n"
        << "  --hide-debug           hide debug panel text\n"
        << "  --max-chunk-instr N    live batch size\n"
        << "  --no-vsync             disable present vsync\n";
}

Options parseArgs(int argc, char** argv) {
    Options opt;
    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        auto needValue = [&](const std::string& flag) -> std::string {
            if (i + 1 >= argc) throw std::runtime_error("missing value for " + flag);
            return argv[++i];
        };

        if (a == "--bin") opt.binPath = needValue(a);
        else if (a == "--play") opt.play = true;
        else if (a == "--left") opt.leftMode = parseMode(needValue(a));
        else if (a == "--right") opt.rightMode = parseMode(needValue(a));
        else if (a == "--fps") opt.fps = std::stod(needValue(a));
        else if (a == "--scale") opt.scale = std::stoi(needValue(a));
        else if (a == "--p1") opt.p1 = std::stoi(needValue(a));
        else if (a == "--p2") opt.p2 = std::stoi(needValue(a));
        else if (a == "--paddle-speed") opt.paddleSpeed = std::stoi(needValue(a));
        else if (a == "--instructions") opt.instructions = static_cast<std::uint64_t>(std::stoull(needValue(a)));
        else if (a == "--trace") opt.tracePath = needValue(a);
        else if (a == "--trace-rows") opt.traceRows = std::stoi(needValue(a));
        else if (a == "--no-auto-start") opt.noAutoStart = true;
        else if (a == "--cpu-hz") opt.cpuHz = std::stoi(needValue(a));
        else if (a == "--pixel-hz") opt.pixelHz = std::stoi(needValue(a));
        else if (a == "--cpu-div") opt.cpuDiv = std::max(1, std::stoi(needValue(a)));
        else if (a == "--hide-debug") opt.hideDebug = true;
        else if (a == "--max-chunk-instr") opt.maxChunkInstr = std::stoi(needValue(a));
        else if (a == "--no-vsync") opt.vsync = false;
        else if (a == "-h" || a == "--help") {
            printUsage();
            std::exit(0);
        } else {
            throw std::runtime_error("unknown arg: " + a);
        }
    }
    return opt;
}

} // namespace

int main(int argc, char** argv) {
    try {
        Options opt = parseArgs(argc, argv);
        std::vector<std::uint16_t> program = loadProgram(opt.binPath);
        Sim sim(program, opt.cpuHz, opt.pixelHz, opt.p1, opt.p2, !opt.noAutoStart);

        if (opt.instructions > 0) sim.runInstructions(opt.instructions);
        if (!opt.tracePath.empty()) sim.saveTraceCsv(opt.tracePath, opt.traceRows);

        if (opt.play) {
            LiveApp app(sim, opt);
            return app.run();
        }

        std::cout << "cpu_hz=" << sim.cpuHz() << " pixel_hz=" << sim.pixelHz() << "\n";
        std::cout << "cycle=" << sim.cycle() << " retired=" << sim.retired() << " pc=" << fmtHex(sim.pc(), 4) << "\n";
        std::cout << "fpga_time_seconds=" << std::fixed << std::setprecision(9) << sim.fpgaTimeSeconds() << "\n";
        std::cout << "regs:";
        for (int i = 0; i < 16; ++i) std::cout << ' ' << 'r' << i << '=' << fmtHex(sim.regs()[i], 4);
        std::cout << "\n";
        std::cout << "flags=0b" << fmtBin5(sim.flags()) << " saved_flags=0b" << fmtBin5(sim.savedFlags()) << "\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "error: " << e.what() << "\n\n";
        printUsage();
        return 1;
    }
}
