# pong cpu + vga simulator

this python script mirrors the custom 16-bit pong cpu in the uploaded zip closely enough to debug real binary programs.

## what it models
- 16 registers
- 1024 words of ram with 10-bit addressing
- the fetch decode execute load store branch fsm
- the current branch quirk logic from `pong_cpu_fsm.v`
- the current `alu.v` behavior including odd broken cases
- `r1` and `r3` being effectively hardwired to external paddle inputs every cpu clock
- mmio reads and writes at `0xFF00` and above
- vga style rendering from `r1 r3 r4 r5 r6 r7`
- start and win glyphs from the provided hex files
- original boot memory restore on reset

## important hardware quirks preserved
- every instruction with upper nibble `0xC` is treated as a branch by the fsm
- that means `lshi` is effectively broken in hardware and is treated like branch behavior
- branch conditions follow the actual fsm logic not the intended textbook meaning
- `subc` and `subci` are effectively unsupported in the current alu and fall through to zero result behavior
- loads write into the `rsrc` register field because that is how `S5_DOUT` is wired

## live play mode
open a real time window and control the paddles from the keyboard:

```bash
python /mnt/data/pong_cpu_vga_sim.py \
  --bin /mnt/data/pongzip/3710-Group-5/2_Quartus_Project/PONG.bin \
  --play \
  --scale 1 \
  --ipf 300 \
  --fps 60
```

### controls
- `w` and `s` move the left paddle
- `up` and `down` move the right paddle
- `space` starts from the start screen when using `--no-auto-start`
- `r` resets to the original boot memory image
- `p` pauses and unpauses
- `.` runs one live frame while paused
- `1` toggles left paddle between human and ai
- `2` toggles right paddle between human and ai
- `o` toggles the on screen debug overlay

### useful live options
- `--left human|ai`
- `--right human|ai`
- `--paddle-speed 7`
- `--no-auto-start`
- `--no-overlay`

example one player against ai:

```bash
python /mnt/data/pong_cpu_vga_sim.py \
  --bin /mnt/data/pongzip/3710-Group-5/2_Quartus_Project/PONG.bin \
  --play \
  --left human \
  --right ai \
  --ipf 300
```

## offline use
single frame after some runtime:

```bash
python /mnt/data/pong_cpu_vga_sim.py \
  --bin /path/to/program.bin \
  --instructions 50000 \
  --frame /path/to/frame.png
```

animated gif:

```bash
python /mnt/data/pong_cpu_vga_sim.py \
  --bin /path/to/program.bin \
  --gif /path/to/out.gif \
  --frames 20 \
  --ipf 5000
```

cycle trace:

```bash
python /mnt/data/pong_cpu_vga_sim.py \
  --bin /path/to/program.bin \
  --trace /path/to/trace.csv \
  --trace-rows 1000
```

## paddle modes for offline rendering
- `--paddles follow` tracks the ball automatically
- `--paddles static` holds both paddles at `--p1` and `--p2`

## outputs
- png frame render
- gif animation
- csv trace with cycle state pc instr flags and all registers
- live interactive debug window
