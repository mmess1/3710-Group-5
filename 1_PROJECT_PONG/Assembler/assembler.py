"""
16-bit ISA Assembler - Main Assembly Driver
============================================

This module serves as the main entry point for the assembler. It reads assembly
code from a source file, processes each instruction, and writes the resulting
machine code to a destination file in either binary or hexadecimal format.

Author: Aliou Tippett
Date: 2026
"""

from isa_definitions import build_instruction

# Global file paths for source and destination files
# Important: Change these File Paths
src_file = "/Users/alioutippett/Downloads/Assembler/src_file"
dst_file = "/Users/alioutippett/Downloads/Assembler/dst_file"

"""
    Main entry point for the assembler.
    
    Reads assembly instructions from the source file line by line,
    cleans each line (removes comments), converts to machine code,
    and writes the binary or hexadecimal output to the destination file.
    
    Workflow:
    1. Clear the destination file
    2. Read each line from source file
    3. Clean the line (remove comments and whitespace)
    4. Build machine instruction from cleaned line
    5. Write machine code to destination file
"""
def main():
    
    # 1) clear dest file:
    clear_file(dst_file)

    # 2) loope each line:
    with open(src_file, "r") as f:
        for line in f:
            line = line.strip()  # removes trailing newline and spaces
            instruction = clean_line(line)
            if instruction: # only use non blank lines
                instruction = build_instruction(instruction)
                # write_next_line_hex(dst_file, instruction)
                write_next_line_binary(dst_file, instruction)

"""
    Clean a single assembly instruction line by removing comments.
    
    Removes any text after comment symbols (#, /, \\) and strips
    leading/trailing whitespace.
        
    Returns:
        str: Cleaned instruction line, or empty string if line was blank/comment-only
"""
def clean_line(line):
    
    # Remove anything after #, /, or \
    for symbol in ['#', '/', '\\']:
        if symbol in line:
            line = line.split(symbol)[0]
            # Strip whitespace
            line = line.strip()
    return line

"""
    Append a machine code instruction to a file in hexadecimal format.
    
    Converts the binary string to hexadecimal and writes it as a new line.
    Format: 0xABCD

"""
def write_next_line_hex(filename, text):
    with open(filename, "a") as f:
        f.write(f"0x{int(text, 2):04X}" + "\n")

"""
    Append a machine code instruction to a file in binary format.

    Writes the binary string as a new line.
    Format: 1101000100100010
"""
def write_next_line_binary(filename, text):
    with open(filename, "a") as f:
        f.write(text + "\n")

"""
    Clear the contents of a file by opening it in write mode.
    Useful for resetting the destination file before writing new data.
"""
def clear_file(filename):
    with open(filename, "w"):
        pass  # opening in "w" mode clears the file

"""
    Debug utility function for testing assembly code parsing.
    
    Reads instructions from a test file, cleans them, and prints
    the assembly code and resulting machine code (binary and hex).
    Useful for debugging individual instructions without full file I/O.
    
    Returns:
        None
"""
def debug_console():
     # ========== CHANGE THESE INSTRUCTIONS TO TEST ==========
    result = clean_file_lines("/Users/alioutippett/Downloads/Assembler/assemberTest")

    # ======================================================
    
    print("=" * 60)
    print("16-bit ISA Assembler - Instruction Builder Test")
    print("=" * 60)
    print()
    
    for i, instruction in enumerate(result, 1):
        print(f"[{i}] Input:  {instruction}")
        
        try:
            machine_code = build_instruction(instruction)
            print(f"     Output: {machine_code}")
            print(f"     Hex:    0x{int(machine_code, 2):04X}")
            print()
        except Exception as e:
            print(f"     ERROR:  {e}")
            print()

    
if __name__ == "__main__":
    main()