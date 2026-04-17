# pong cpu vga sim cpp

build on macos with homebrew:

```bash
brew install sdl2 cmake pkg-config
cd /Users/mishaalalali/3710-Group-5/SIMULATION
cmake -S . -B build -DCMAKE_PREFIX_PATH=/opt/homebrew
cmake --build build -j
```

run:

```bash
./build/pong_cpu_vga_sim \
  --bin /Users/mishaalalali/3710-Group-5/2_Quartus_Project/PONG.bin \
  --play \
  --left human \
  --right ai \
  --scale 2 \
  --cpu-div 256
```
