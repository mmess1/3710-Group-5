cmake_minimum_required(VERSION 3.16)
project(pong_cpu_vga_sim LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(pong_cpu_vga_sim
    src/pong_cpu_vga_sim.cpp
)

# try the official SDL2 config package first
find_package(SDL2 CONFIG QUIET)
if (TARGET SDL2::SDL2)
    target_link_libraries(pong_cpu_vga_sim PRIVATE SDL2::SDL2)
else()
    # homebrew often works best through pkg-config on macos
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(SDL2 REQUIRED IMPORTED_TARGET sdl2)
    target_link_libraries(pong_cpu_vga_sim PRIVATE PkgConfig::SDL2)
endif()

if (MSVC)
    target_compile_options(pong_cpu_vga_sim PRIVATE /W4)
else()
    target_compile_options(pong_cpu_vga_sim PRIVATE -Wall -Wextra -Wpedantic)
endif()
