from __future__ import annotations

import argparse
import csv
import time
from pathlib import Path
from typing import Optional

try:
    import tkinter as tk
except Exception:
    tk = None

VISIBLE_W = 640
VISIBLE_H = 480
MEM_WORDS = 1024

# cpu / board timing
DEFAULT_CPU_HZ = 50_000_000  # de1-soc fpga board clock input
DEFAULT_PIXEL_HZ = 25_000_000  # common vga pixel clock from 50 mhz / 2
DEFAULT_FRAME_HZ = 60.0

# flag bits
FLAG_L = 4
FLAG_C = 3
FLAG_F = 2
FLAG_Z = 1
FLAG_N = 0

# opcodes
OP_WAIT = 0x00
OP_AND = 0x01
OP_OR = 0x02
OP_XOR = 0x03
OP_NOT = 0x04
OP_ADD = 0x05
OP_ADDU = 0x06
OP_ADDC = 0x07
OP_RSH = 0x08
OP_SUB = 0x09
OP_SUBC = 0x0A
OP_CMP = 0x0B
OP_LSH = 0x0C
OP_MOV = 0x0D
OP_MUL = 0x0E
OP_ARSH = 0x0F
OP_LOAD = 0x40
OP_STORE = 0x44
OP_ADDI = 0x50
OP_ADDUI = 0x60
OP_ADDCI = 0x70
OP_RSHI = 0x80
OP_SUBI = 0x90
OP_SUBCI = 0xA0
OP_CMPI = 0xB0
OP_BRANCH = 0xC0  # actual fsm bug collides with lshi
OP_MOVI = 0xD0
OP_MULI = 0xE0
OP_ARSHI = 0xF0

PADDLE_W = 10
PADDLE_H = 45
PLAYER1_X = 30
PLAYER2_X = 610
BALL_SIZE = 10

MODE_START = 0
MODE_PLAY = 1
MODE_P1_WIN = 2
MODE_P2_WIN = 3

DIGIT_MAP = {
    "0": "11111 10001 10001 10001 11111",
    "1": "00100 01100 00100 00100 01110",
    "2": "11111 00001 11111 10000 11111",
    "3": "11111 00001 01110 00001 11111",
    "4": "10001 10001 11111 00001 00001",
    "5": "11111 10000 11111 00001 11111",
    "6": "11111 10000 11111 10001 11111",
    "7": "11111 00001 00010 00100 00100",
    "8": "11111 10001 11111 10001 11111",
    "9": "11111 10001 11111 00001 11111",
}


def u16(x: int) -> int:
    return x & 0xFFFF


def s16(x: int) -> int:
    x &= 0xFFFF
    return x - 0x10000 if x & 0x8000 else x


def s8(x: int) -> int:
    x &= 0xFF
    return x - 0x100 if x & 0x80 else x


def bits_to_int(text: str) -> int:
    text = text.strip()
    if not text:
        raise ValueError("empty instruction line")
    if all(ch in "01" for ch in text):
        return int(text, 2)
    if text.lower().startswith("0x"):
        return int(text, 16)
    return int(text, 16)


class PongArchSim:
    def __init__(
        self,
        program: list[int],
        *,
        p1_input: int = 200,
        p2_input: int = 200,
        auto_start: bool = True,
        cpu_hz: int = DEFAULT_CPU_HZ,
        pixel_hz: int = DEFAULT_PIXEL_HZ,
    ) -> None:
        self.boot_memory = [0] * MEM_WORDS
        for i, word in enumerate(program[:MEM_WORDS]):
            self.boot_memory[i] = u16(word)

        self.cpu_hz = int(cpu_hz)
        self.pixel_hz = int(pixel_hz)
        self.reset(p1_input=p1_input, p2_input=p2_input, auto_start=auto_start)

    @classmethod
    def from_bin_file(
        cls,
        bin_path: str | Path,
        *,
        p1_input: int = 200,
        p2_input: int = 200,
        auto_start: bool = True,
        cpu_hz: int = DEFAULT_CPU_HZ,
        pixel_hz: int = DEFAULT_PIXEL_HZ,
    ) -> "PongArchSim":
        path = Path(bin_path)
        program: list[int] = []
        for raw in path.read_text().splitlines():
            line = raw.strip()
            if not line or line.startswith("//") or line.startswith("#"):
                continue
            program.append(bits_to_int(line))
        return cls(program, p1_input=p1_input, p2_input=p2_input, auto_start=auto_start, cpu_hz=cpu_hz, pixel_hz=pixel_hz)

    def reset(self, *, p1_input: Optional[int] = None, p2_input: Optional[int] = None, auto_start: Optional[bool] = None) -> None:
        self.memory = list(self.boot_memory)
        self.regs = [0] * 16
        self.flags = 0
        self.saved_flags = 0
        self.pc = 0
        self.cycle = 0
        self.retired = 0
        self.last_instr = 0
        self.last_opcode = 0
        self.last_instr_cycles = 0

        if p1_input is not None:
            self.p1_input = int(p1_input) & 0x1FF
        else:
            self.p1_input = getattr(self, "p1_input", 200)
        if p2_input is not None:
            self.p2_input = int(p2_input) & 0x1FF
        else:
            self.p2_input = getattr(self, "p2_input", 200)

        self.game_started = bool(auto_start if auto_start is not None else getattr(self, "game_started", True))
        self.winner_mode = 0
        self.mmio_regs = {0xFF00: self.p1_input, 0xFF01: self.p2_input}
        self._sample_inputs()
        self.update_top_wrapper()

    def _sample_inputs(self) -> None:
        self.regs[1] = self.p1_input & 0x1FF
        self.regs[3] = self.p2_input & 0x1FF

    def set_inputs(self, p1: Optional[int] = None, p2: Optional[int] = None) -> None:
        if p1 is not None:
            self.p1_input = int(p1) & 0x1FF
        if p2 is not None:
            self.p2_input = int(p2) & 0x1FF
        self.mmio_regs[0xFF00] = self.p1_input
        self.mmio_regs[0xFF01] = self.p2_input

    def start_game(self) -> None:
        self.game_started = True

    def screen_mode(self) -> int:
        if not self.game_started:
            return MODE_START
        if self.winner_mode:
            return self.winner_mode
        return MODE_PLAY

    def update_top_wrapper(self) -> None:
        if self.regs[4] >= 15:
            self.winner_mode = MODE_P1_WIN
        elif self.regs[5] >= 15:
            self.winner_mode = MODE_P2_WIN
        else:
            self.winner_mode = 0

    def decode(self, word: int) -> tuple[int, int, int, int, int, int, int]:
        upper = (word >> 12) & 0xF
        ext = (word >> 4) & 0xF
        opcode = ((upper << 4) | ext) if upper in (0x0, 0x4) else (upper << 4)
        rdest = (word >> 8) & 0xF
        rsrc = word & 0xF
        imm8 = word & 0xFF
        imm16 = s8(imm8)
        return upper, ext, opcode, rdest, rsrc, imm8, imm16

    def read_mmio(self, addr: int) -> int:
        addr = u16(addr)
        if addr == 0xFF00:
            return self.mmio_regs.get(0xFF00, 0) & 0x1FF
        if addr == 0xFF01:
            return self.mmio_regs.get(0xFF01, 0) & 0x1FF
        if addr == 0xFF10:
            return self.p1_input & 0x1FF
        if addr == 0xFF11:
            return self.p2_input & 0x1FF
        return 0

    def write_mmio(self, addr: int, value: int) -> None:
        addr = u16(addr)
        if addr in (0xFF00, 0xFF01):
            self.mmio_regs[addr] = value & 0x1FF

    def check_flags(self, cond: int) -> bool:
        flags = self.saved_flags
        z = (flags >> FLAG_Z) & 1
        n = (flags >> FLAG_N) & 1
        f = (flags >> FLAG_F) & 1
        c = (flags >> FLAG_C) & 1
        l = (flags >> FLAG_L) & 1
        if cond == 0x0:
            return z == 1
        if cond == 0x1:
            return z == 0
        if cond == 0x2:
            return c == 1
        if cond == 0x3:
            return c == 0
        if cond == 0x4:
            return l == 1
        if cond == 0x5:
            return l == 0
        if cond == 0x6:
            return n == 1
        if cond == 0x7:
            return n == 0
        if cond == 0x8:
            return f == 1
        if cond == 0x9:
            return f == 0
        if cond == 0xA:
            return (l == 0) and (z == 0)
        if cond == 0xB:
            return (l == 1) or (z == 1)
        if cond == 0xC:
            return (n == 0) and (z == 0)
        if cond == 0xD:
            return (z == 1) or (n == 1)
        if cond == 0xE:
            return True
        return False

    def _flags(self, l: int, c: int, f: int, z: int, n: int) -> int:
        return ((l & 1) << FLAG_L) | ((c & 1) << FLAG_C) | ((f & 1) << FLAG_F) | ((z & 1) << FLAG_Z) | ((n & 1) << FLAG_N)

    def exec_alu(self, opcode: int, rdest: int, rsrc: int, imm16: int, upper: int) -> tuple[int, int]:
        rd = self.regs[rdest] & 0xFFFF
        rs = (imm16 & 0xFFFF) if upper not in (0x0, 0x4) else (self.regs[rsrc] & 0xFFFF)

        if opcode in (OP_ADD, OP_ADDI):
            result = u16(s16(rd) + s16(rs))
            overflow = int((((rd ^ rs) & 0x8000) == 0) and (((result ^ rd) & 0x8000) != 0))
            return result, self._flags(int(rd < rs), 0, overflow, int(result == 0), (result >> 15) & 1)
        if opcode in (OP_ADDU, OP_ADDUI, OP_ADDC, OP_ADDCI):
            tmp = rd + rs
            result = tmp & 0xFFFF
            carry = 1 if tmp > 0xFFFF else 0
            return result, self._flags(int(rd < rs), carry, 0, int(result == 0), (result >> 15) & 1)
        if opcode in (OP_MOV, OP_MOVI):
            result = rs & 0xFFFF
            return result, self._flags(0, 0, 0, int(result == 0), (result >> 15) & 1)
        if opcode in (OP_MUL, OP_MULI):
            prod = (rd * rs) & 0xFFFFFFFF
            result = prod & 0xFFFF
            carry = 1 if (prod >> 16) & 0xFFFF else 0
            return result, self._flags(0, carry, 0, int(result == 0), (result >> 15) & 1)
        if opcode in (OP_SUB, OP_SUBI):
            tmp = (rd - rs) & 0x1FFFF
            result = tmp & 0xFFFF
            overflow = int((((rd ^ rs) & 0x8000) != 0) and (((result ^ rd) & 0x8000) != 0))
            carry = (tmp >> 16) & 1
            return result, self._flags(int(rd < rs), carry, overflow, int(result == 0), (result >> 15) & 1)
        if opcode in (OP_SUBC, OP_SUBCI):
            return 0, 0
        if opcode == OP_AND:
            result = rd & rs
            return result, self._flags(0, 0, 0, int(result == 0), (result >> 15) & 1)
        if opcode == OP_OR:
            result = rd | rs
            return result, self._flags(0, 0, 0, int(result == 0), (result >> 15) & 1)
        if opcode == OP_XOR:
            result = rd ^ rs
            return result, self._flags(0, 0, 0, int(result == 0), (result >> 15) & 1)
        if opcode == OP_NOT:
            result = (~rd) & 0xFFFF
            return result, self._flags(0, 0, 0, int(result == 0), (result >> 15) & 1)
        if opcode == OP_LSH:
            result = (rd << (rs & 0xF)) & 0xFFFF
            return result, self._flags(0, 0, 0, int(result == 0), (result >> 15) & 1)
        if opcode == OP_RSH or opcode == OP_RSHI:
            result = (rd >> (rs & 0xF)) & 0xFFFF
            return result, self._flags(0, 0, 0, int(result == 0), (result >> 15) & 1)
        if opcode == OP_ARSH or opcode == OP_ARSHI:
            result = u16(s16(rd) >> (rs & 0xF))
            return result, self._flags(0, 0, 0, int(result == 0), (result >> 15) & 1)
        if opcode in (OP_CMP, OP_CMPI):
            return rd, self._flags(int(rd < rs), 0, 0, int(rd == rs), int(s16(rd) < s16(rs)))
        if opcode == OP_WAIT:
            return rd, self.flags
        return 0, 0

    def step_retired_fast(self) -> int:
        if not self.game_started or self.winner_mode:
            self._sample_inputs()
            self.update_top_wrapper()
            self.cycle += 1
            self.last_instr = 0
            self.last_opcode = 0
            self.last_instr_cycles = 1
            return 1

        word = self.memory[self.pc & 0x3FF]
        upper, ext, opcode, rdest, rsrc, imm8, imm16 = self.decode(word)
        self.last_instr = word
        self.last_opcode = opcode

        if upper == 0x4 and ext == 0x4:
            addr = self.regs[rdest] & 0xFFFF
            data = self.regs[rsrc] & 0xFFFF
            if addr >= 0xFF00:
                self.write_mmio(addr, data)
            else:
                self.memory[addr & 0x3FF] = data
            self.pc = u16(self.pc + 1)
            taken_cycles = 3

        elif upper == 0x4 and ext == 0x0:
            addr = self.regs[rdest] & 0xFFFF
            if addr >= 0xFF00:
                data = self.read_mmio(addr)
            else:
                data = self.memory[addr & 0x3FF]
            self.regs[rsrc] = data & 0xFFFF
            self.pc = u16(self.pc + 1)
            taken_cycles = 4

        elif upper == 0xC:
            if self.check_flags(rdest):
                self.pc = u16(self.pc + imm16)
            else:
                self.pc = u16(self.pc + 1)
            taken_cycles = 3

        else:
            result, flags = self.exec_alu(opcode, rdest, rsrc, imm16, upper)
            self.flags = flags
            if opcode in (OP_CMP, OP_CMPI):
                self.saved_flags = flags
            elif opcode != OP_WAIT:
                self.regs[rdest] = result & 0xFFFF
            self.pc = u16(self.pc + 1)
            taken_cycles = 3

        self.retired += 1
        self.cycle += taken_cycles
        self.last_instr_cycles = taken_cycles
        self._sample_inputs()
        self.update_top_wrapper()
        return taken_cycles

    def run_instructions(self, count: int) -> None:
        for _ in range(count):
            self.step_retired_fast()

    def run_cycles_budget(self, cycle_budget: int) -> int:
        done = 0
        while done < cycle_budget:
            done += self.step_retired_fast()
        return done

    def save_trace_csv(self, out_path: str | Path, rows: int = 1000) -> Path:
        out_path = Path(out_path)
        with out_path.open("w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["cycle", "retired", "pc", "instr", "opcode", "flags", "saved_flags"] + [f"r{i}" for i in range(16)])
            for _ in range(rows):
                writer.writerow([
                    self.cycle,
                    self.retired,
                    f"0x{self.pc:04X}",
                    f"0x{self.last_instr:04X}",
                    f"0x{self.last_opcode:02X}",
                    f"0b{self.flags:05b}",
                    f"0b{self.saved_flags:05b}",
                    *[f"0x{x:04X}" for x in self.regs],
                ])
                self.step_retired_fast()
        return out_path

    def fpga_time_seconds(self) -> float:
        return self.cycle / float(self.cpu_hz)


class LiveWindow:
    def __init__(
        self,
        sim: PongArchSim,
        *,
        scale: int = 1,
        fps: float = 60.0,
        left_mode: str = "human",
        right_mode: str = "ai",
        paddle_speed: int = 8,
        no_auto_start: bool = False,
        show_debug: bool = True,
        cpu_div: int = 1,
        max_chunk_instr: int = 20000,
    ) -> None:
        if tk is None:
            raise RuntimeError("tkinter is not available in this python build")

        self.sim = sim
        self.scale = max(1, int(scale))
        self.fps = float(fps)
        self.left_mode = left_mode
        self.right_mode = right_mode
        self.paddle_speed = int(paddle_speed)
        self.show_debug = bool(show_debug)
        self.cpu_div = max(1, int(cpu_div))
        self.max_chunk_instr = max(1000, int(max_chunk_instr))
        self.paused = False
        self.left_up = False
        self.left_down = False
        self.right_up = False
        self.right_down = False
        self.wall_last = time.perf_counter()
        self.cycle_last = self.sim.cycle

        if no_auto_start:
            self.sim.game_started = False

        self.root = tk.Tk()
        self.root.title("pong cpu sim")

        self.canvas = tk.Canvas(
            self.root,
            width=VISIBLE_W * self.scale,
            height=VISIBLE_H * self.scale,
            bg="black",
            highlightthickness=0,
        )
        self.canvas.pack()

        self.info = tk.Label(self.root, text="", anchor="w", justify="left", font=("Menlo", 10))
        self.info.pack(fill="x")

        s = self.scale
        self.canvas.create_rectangle(0, 0, VISIBLE_W * s - 1, VISIBLE_H * s - 1, outline="white", width=max(1, 4 * s))
        self.center_line = []
        for y in range(0, VISIBLE_H, 20):
            item = self.canvas.create_rectangle(320 * s, y * s, 321 * s, min(y + 9, VISIBLE_H - 1) * s, fill="white", outline="white")
            self.center_line.append(item)

        self.p1 = self.canvas.create_rectangle(0, 0, 0, 0, fill="white", outline="white")
        self.p2 = self.canvas.create_rectangle(0, 0, 0, 0, fill="white", outline="white")
        self.ball = self.canvas.create_rectangle(0, 0, 0, 0, fill="#ff7a00", outline="#ff7a00")
        self.score_text = self.canvas.create_text(VISIBLE_W * s // 2, 50 * s, text="", fill="white", font=("Courier", 28 * s // 1, "bold"))
        self.msg_text = self.canvas.create_text(VISIBLE_W * s // 2, VISIBLE_H * s // 2, text="", fill="white", font=("Courier", 20 * s // 1, "bold"))

        self.root.bind("<KeyPress>", self.on_key_press)
        self.root.bind("<KeyRelease>", self.on_key_release)
        self.root.protocol("WM_DELETE_WINDOW", self.root.destroy)

    def on_key_press(self, event: tk.Event) -> None:
        k = event.keysym.lower()
        if k == "w":
            self.left_up = True
        elif k == "s":
            self.left_down = True
        elif k == "up":
            self.right_up = True
        elif k == "down":
            self.right_down = True
        elif k == "space":
            self.sim.start_game()
        elif k == "p":
            self.paused = not self.paused
        elif k == "r":
            self.sim.reset(auto_start=self.sim.game_started)
        elif k == "1":
            self.left_mode = "ai" if self.left_mode == "human" else "human"
        elif k == "2":
            self.right_mode = "ai" if self.right_mode == "human" else "human"
        elif k == "o":
            self.show_debug = not self.show_debug
        elif k == "period":
            if self.paused:
                self.apply_inputs()
                self.sim.step_retired_fast()
                self.redraw()

    def on_key_release(self, event: tk.Event) -> None:
        k = event.keysym.lower()
        if k == "w":
            self.left_up = False
        elif k == "s":
            self.left_down = False
        elif k == "up":
            self.right_up = False
        elif k == "down":
            self.right_down = False

    def clamp_paddle(self, y: int) -> int:
        return max(0, min(VISIBLE_H - PADDLE_H, int(y)))

    def ai_target(self) -> int:
        return self.clamp_paddle(int(self.sim.regs[7]) - PADDLE_H // 2)

    def apply_inputs(self) -> None:
        p1 = self.sim.p1_input
        p2 = self.sim.p2_input

        if self.left_mode == "ai":
            target = self.ai_target()
            if p1 < target:
                p1 = min(target, p1 + self.paddle_speed)
            elif p1 > target:
                p1 = max(target, p1 - self.paddle_speed)
        else:
            if self.left_up and not self.left_down:
                p1 -= self.paddle_speed
            elif self.left_down and not self.left_up:
                p1 += self.paddle_speed

        if self.right_mode == "ai":
            target = self.ai_target()
            if p2 < target:
                p2 = min(target, p2 + self.paddle_speed)
            elif p2 > target:
                p2 = max(target, p2 - self.paddle_speed)
        else:
            if self.right_up and not self.right_down:
                p2 -= self.paddle_speed
            elif self.right_down and not self.right_up:
                p2 += self.paddle_speed

        self.sim.set_inputs(self.clamp_paddle(p1), self.clamp_paddle(p2))

    def redraw(self) -> None:
        s = self.scale
        mode = self.sim.screen_mode()
        p1y = self.clamp_paddle(self.sim.regs[1])
        p2y = self.clamp_paddle(self.sim.regs[3])
        bx = max(0, min(VISIBLE_W - BALL_SIZE, int(self.sim.regs[6])))
        by = max(0, min(VISIBLE_H - BALL_SIZE, int(self.sim.regs[7])))

        self.canvas.coords(self.p1, PLAYER1_X * s, p1y * s, (PLAYER1_X + PADDLE_W) * s, (p1y + PADDLE_H) * s)
        self.canvas.coords(self.p2, PLAYER2_X * s, p2y * s, (PLAYER2_X + PADDLE_W) * s, (p2y + PADDLE_H) * s)
        self.canvas.coords(self.ball, bx * s, by * s, (bx + BALL_SIZE) * s, (by + BALL_SIZE) * s)

        if mode == MODE_PLAY:
            self.canvas.itemconfigure(self.p1, state="normal")
            self.canvas.itemconfigure(self.p2, state="normal")
            self.canvas.itemconfigure(self.ball, state="normal")
            self.canvas.itemconfigure(self.score_text, text=f"{int(self.sim.regs[4])}     {int(self.sim.regs[5])}")
            self.canvas.itemconfigure(self.msg_text, text="")
            for item in self.center_line:
                self.canvas.itemconfigure(item, state="normal")
        else:
            self.canvas.itemconfigure(self.score_text, text="")
            self.canvas.itemconfigure(self.p1, state="hidden")
            self.canvas.itemconfigure(self.p2, state="hidden")
            self.canvas.itemconfigure(self.ball, state="hidden")
            for item in self.center_line:
                self.canvas.itemconfigure(item, state="hidden")
            if mode == MODE_START:
                self.canvas.itemconfigure(self.msg_text, text="PRESS SPACE TO START")
            elif mode == MODE_P1_WIN:
                self.canvas.itemconfigure(self.msg_text, text="PLAYER 1 WINS\nPRESS R TO RESET")
            elif mode == MODE_P2_WIN:
                self.canvas.itemconfigure(self.msg_text, text="PLAYER 2 WINS\nPRESS R TO RESET")

        now = time.perf_counter()
        wall_dt = max(1e-9, now - self.wall_last)
        cycle_dt = self.sim.cycle - self.cycle_last
        self.wall_last = now
        self.cycle_last = self.sim.cycle
        cps = cycle_dt / wall_dt
        realtime = cps / self.sim.cpu_hz

        if self.show_debug:
            self.info.config(
                text=(
                    f"cpu target: {self.sim.cpu_hz/1e6:.2f} MHz   simulated: {cps/1e6:.3f} MHz   realtime ratio: {realtime:.5f}\n"
                    f"fpga time: {self.sim.fpga_time_seconds():.6f}s   cycles: {self.sim.cycle}   retired: {self.sim.retired}   last cycles: {self.sim.last_instr_cycles}\n"
                    f"pc: 0x{self.sim.pc:04X}   instr: 0x{self.sim.last_instr:04X}   opcode: 0x{self.sim.last_opcode:02X}   flags: 0b{self.sim.flags:05b} saved: 0b{self.sim.saved_flags:05b}\n"
                    f"left: {self.left_mode}   right: {self.right_mode}   paused: {self.paused}   cpu_div: {self.cpu_div}   max_chunk_instr: {self.max_chunk_instr}"
                )
            )
        else:
            self.info.config(text="")

    def tick(self) -> None:
        if not self.paused:
            self.apply_inputs()
            desired_cycles = int(self.sim.cpu_hz / self.cpu_div / self.fps)
            done = 0
            while done < desired_cycles:
                batch_instr = min(self.max_chunk_instr, max(1000, (desired_cycles - done) // 3 + 2))
                before = self.sim.cycle
                self.sim.run_instructions(batch_instr)
                done += self.sim.cycle - before
                if self.sim.screen_mode() != MODE_PLAY and self.sim.game_started is False:
                    break
                if self.sim.winner_mode:
                    break
        self.redraw()
        delay_ms = max(1, int(1000 / self.fps))
        self.root.after(delay_ms, self.tick)

    def run(self) -> None:
        self.redraw()
        self.root.after(1, self.tick)
        self.root.mainloop()


def main() -> None:
    parser = argparse.ArgumentParser(description="simulate the custom 16-bit pong cpu")
    parser.add_argument("--bin", required=True, help="path to binary program file")
    parser.add_argument("--play", action="store_true", help="open a live interactive window")
    parser.add_argument("--left", choices=["human", "ai"], default="human")
    parser.add_argument("--right", choices=["human", "ai"], default="ai")
    parser.add_argument("--fps", type=float, default=60.0)
    parser.add_argument("--scale", type=int, default=1)
    parser.add_argument("--p1", type=int, default=200)
    parser.add_argument("--p2", type=int, default=200)
    parser.add_argument("--paddle-speed", type=int, default=8)
    parser.add_argument("--instructions", type=int, default=0, help="headless: run this many retired instructions")
    parser.add_argument("--trace", default=None, help="save trace csv")
    parser.add_argument("--trace-rows", type=int, default=1000)
    parser.add_argument("--no-auto-start", action="store_true")
    parser.add_argument("--cpu-hz", type=int, default=DEFAULT_CPU_HZ)
    parser.add_argument("--pixel-hz", type=int, default=DEFAULT_PIXEL_HZ)
    parser.add_argument("--cpu-div", type=int, default=256, help="live mode clock divider for responsiveness. 1 means aim for full 50 mhz, which python cannot reach. 256 is a practical default.")
    parser.add_argument("--hide-debug", action="store_true")
    parser.add_argument("--max-chunk-instr", type=int, default=20000, help="live mode batch size. higher is faster but less responsive")
    args = parser.parse_args()

    sim = PongArchSim.from_bin_file(
        args.bin,
        p1_input=args.p1,
        p2_input=args.p2,
        auto_start=not args.no_auto_start,
        cpu_hz=args.cpu_hz,
        pixel_hz=args.pixel_hz,
    )

    if args.instructions:
        sim.run_instructions(args.instructions)
    if args.trace:
        sim.save_trace_csv(args.trace, rows=args.trace_rows)

    if args.play:
        LiveWindow(
            sim,
            scale=args.scale,
            fps=args.fps,
            left_mode=args.left,
            right_mode=args.right,
            paddle_speed=args.paddle_speed,
            no_auto_start=args.no_auto_start,
            show_debug=not args.hide_debug,
            cpu_div=args.cpu_div,
            max_chunk_instr=args.max_chunk_instr,
        ).run()
        return

    print(f"cpu_hz={sim.cpu_hz} pixel_hz={sim.pixel_hz}")
    print(f"cycle={sim.cycle} retired={sim.retired} pc=0x{sim.pc:04X}")
    print(f"fpga_time_seconds={sim.fpga_time_seconds():.9f}")
    print("regs:", " ".join(f"r{i}=0x{v:04X}" for i, v in enumerate(sim.regs)))
    print(f"flags=0b{sim.flags:05b} saved_flags=0b{sim.saved_flags:05b}")


if __name__ == "__main__":
    main()
