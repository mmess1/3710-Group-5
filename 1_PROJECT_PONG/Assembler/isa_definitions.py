################################################################################
"""
Instruction Builder for 16-bit ISA Assembler
Parses assembly instructions and generates 16-bit machine code.
"""
################################################################################
# isa_definitions.py
# Instruction opcodes (opcode, ext) as 4-bit strings
OPCODES = {
    'ADD':   ('0000', '0101'),
    'ADDU':  ('0000', '0110'),
    'ADDC':  ('0000', '0111'),
    'ADDI':  ('0101', '0000'),
    'ADDUI': ('0110', '0000'),
    'ADDCI': ('0111', '0000'),
    'MOV':   ('0000', '1101'),
    'MOVI':  ('1101', '0000'),
    'MUL':   ('0000', '1110'),
    'MULI':  ('1110', '0000'),
    'SUB':   ('0000', '1001'),
    'SUBC':  ('0000', '1010'),
    'SUBI':  ('1001', '0000'),
    'SUBCI': ('1010', '0000'),
    'CMP':   ('0000', '1011'),
    'CMPI':  ('1011', '0000'),
    'AND':   ('0000', '0001'),
    'OR':    ('0000', '0010'),
    'XOR':   ('0000', '0011'),
    'NOT':   ('0000', '0100'),
    'LSH':   ('0000', '1100'),
    'LSHI':  ('1100', '0000'),
    'RSH':   ('0000', '1000'),
    'RSHI':  ('1000', '0000'),
    'ARSH':  ('0000', '1111'),
    'ARSHI': ('1111', '0000'),
    'WAIT':  ('0000', '0000'),
    'LOAD':  ('0100', '0000'),
    'STORE':  ('0100', '0100'),
    'BCOND':  ('1100', '0000'),
}

# Register mappings (4-bit strings)
REGISTERS = {
    'r0':  '0000',
    'r1':  '0001',
    'r2':  '0010',
    'r3':  '0011',
    'r4':  '0100',
    'r5':  '0101',
    'r6':  '0110',
    'r7':  '0111',
    'r8':  '1000',
    'r9':  '1001',
    'r10': '1010',
    'r11': '1011',
    'r12': '1100',
    'r13': '1101',
    'r14': '1110',
    'r15': '1111',
}
# interger mappings (4-bit strings)
CONDITIONS = {
    '0':  '0000', # =
    '1':  '0001', # !=
    '6':  '0110',   # >
    '7':  '0111',   # <=
    '12':  '1100', # <
    '13':  '1101', # >=
    '14':  '1110', # unconditional

}
################################################################################
"""
    Split an immediate value into high and low 4-bit nibbles.
  
    For an 8-bit immediate, this splits it into two 4-bit values.
    For example: 514 (0x202) would be split into high=2, low=2
    But since we only have 8 bits total, we mask to 0xFF first.
    
    Args:
        immediate (int): The immediate value to split
        
    Returns:
        tuple: (high_nibble, low_nibble) as 4-bit binary strings
        
    Raises:
        ValueError: If immediate is negative or exceeds 255
"""
def split_immediate_to_nibbles_unsigned(immediate):

    if immediate < 0 or immediate > 255:
        raise ValueError(f"Immediate value {immediate} must be between 0 and 255")
    
    # Extract high and low 4 bits
    high_nibble = (immediate >> 4) & 0xF
    low_nibble = immediate & 0xF # only keep lower 4 bits
    
    # Convert to 4-bit binary strings
    high_str = format(high_nibble, '04b')
    low_str = format(low_nibble, '04b')
    
    return high_str, low_str

"""
    Split a signed 8-bit immediate value into high and low 4-bit nibbles.
    
    Uses two's complement representation for negative numbers.
    Range: -128 to 127
    
    For example:
    - 50 → high=0011(3), low=0010(2)
    - -50 → high=1100(12), low=1110(14)  [two's complement]
    
    Args:
        immediate (int): The signed immediate value to split (-128 to 127)
        
    Returns:
        tuple: (high_nibble, low_nibble) as 4-bit binary strings
        
    Raises:
        ValueError: If immediate is outside -128 to 127 range
"""
def split_immediate_to_nibbles_signed(immediate):

    if immediate < -128 or immediate > 127:
        raise ValueError(f"Signed immediate value {immediate} must be between -128 and 127")
    
    # Convert to 8-bit two's complement if negative
    if immediate < 0:
        byte_value = 256 + immediate  # Two's complement: 2^8 + value
    else:
        byte_value = immediate
    
    # Extract high and low 4 bits
    high_nibble = (byte_value >> 4) & 0xF
    low_nibble = byte_value & 0xF
    
    # Convert to 4-bit binary strings
    high_str = format(high_nibble, '04b')
    low_str = format(low_nibble, '04b')
    
    return high_str, low_str

"""
    Parse an operand and determine if it's a register or immediate.
 
    Registers are prefixed with '$' (e.g., '$r3')
    Immediates are plain numbers (e.g., '514')
    
    Args:
        operand (str): The operand string to parse   
    Returns:
        dict: {'type': 'register'|'immediate', 'value': str|int}   
    Raises:
        ValueError: If operand format is invalid
"""
def parse_operand(operand):
    operand = operand.strip()
    
    if operand.startswith('$'):
        # It's a register
        return {
            'type': 'register',
            'value': operand[1:]  # Remove the '$' prefix
        }
    else:
        # It's an immediate
        try:
            value = int(operand)
            return {
                'type': 'immediate',
                'value': value
            }
        except ValueError:
            raise ValueError(f"Invalid operand: {operand}")
 
"""
    Look up a register and return its 4-bit binary string.
    Handles case-insensitivity for register names.
    Args:
        register_name (str): Register name (e.g., 'r3', 'R3')
        REGISTERS (dict): Register mapping dictionary      
    Returns:
        str: 4-bit binary string for the register     
    Raises:
        KeyError: If register does not exist
"""
def get_register_bits(register_name, REGISTERS):
    reg_lower = register_name.lower()  # cast to lower case
    if reg_lower not in REGISTERS:
        raise KeyError(f"Register ${reg_lower} does not exist")
    return REGISTERS[reg_lower]

def get_cond_bits(cond, CONDITIONS):
    if cond not in CONDITIONS:
        raise KeyError(f"Branch Conditions ${cond} does not exist")
    return CONDITIONS[cond]

"""
    Look up an instruction mnemonic and return its opcode and extension.
    Handles case-insensitivity for mnemonics.
    Args:
        mnemonic (str): Instruction mnemonic (e.g., 'MOVI', 'movi')
        OPCODES (dict): Opcode mapping dictionary
    Returns:
        tuple: (opcode_4bits, ext_4bits) as strings  
    Raises:
        KeyError: If mnemonic does not exist
""" 
def get_opcode_bits(mnemonic, OPCODES):
    code = mnemonic.upper() # cast to uppercase
    if code not in OPCODES:
        raise KeyError(f"Instruction {code} does not exist")
    return OPCODES[code]
 
"""
    Parse an assembly instruction line into mnemonic and operands.
    Splits on whitespace and commas, handling both cases.
    Example: "MOVI $r3, 514" → ('MOVI', ['$r3', '514'])
    Args: line (str): A single instruction line (must be pre-cleaned)
    Returns: tuple: (mnemonic, [Rsrc, Rdst])
    Raises: ValueError: If line is empty or malformed
"""
def parse_instruction_line(line):

    if not line or not line.strip():
        raise ValueError("Instruction line is empty")
    # Replace commas with spaces and split
    normalized = line.replace(',', ' ')
    parts = normalized.split()
    if not parts:
        raise ValueError("Instruction line is empty")
    inst = parts[0]
    operands = parts[1:] if len(parts) > 1 else []
    return inst, operands # should return somthing like "MOVI $r3, 514" → ('MOVI', ['$r3', '514'])

"""
    Parse an assembly instruction line and build a 16-bit machine code.
    Instruction format: OpCode(4) + Rdest(4) + OpExt(4) + Rsrc(4)
    For immediate instructions, Rsrc is replaced with Imm_high(4) + Imm_low(4)
    
    Args:
        line (str): Cleaned assembly instruction line
                   Examples: "MOVI $r3, 514", "ADD $r1, $r2, $r3"
        OPCODES (dict): Instruction opcode definitions
        REGISTERS (dict): Register definitions
        
    Returns:
        str: 16-bit binary instruction string (e.g., '1101000100100010')
        
    Raises:
        ValueError: If instruction format or values are invalid
        KeyError: If instruction or register does not exist
"""
def build_instruction(line):
    # Step 1: Parse the instruction line
         # mnemonic = MOVI
         # operands = [$r2, $r3]
    mnemonic, operands = parse_instruction_line(line)
 
    # Step 2: Get opcode and extension
    opcode, ext = get_opcode_bits(mnemonic, OPCODES)
    
    # Step 3: Determine instruction type and parse operands
    # Check if this is an immediate instruction (ends with 'I')
    is_immediate_instr = mnemonic.upper().endswith('I')
    if mnemonic == 'Bcond':
        try:
            # rdest_operand = int(operands[0])
            rdest = get_cond_bits(operands[0], CONDITIONS)
        except ValueError:
            raise ValueError(f"Invalid operand: {operands[0]}")

        imm_operand = parse_operand(operands[1])
        if imm_operand['type'] != 'immediate':
            raise ValueError(f"Second operand must be an immediate value, got {operands[1]}")
        imm_high, imm_low = split_immediate_to_nibbles_signed(imm_operand['value'])
        instruction = opcode + rdest + imm_high + imm_high
    elif is_immediate_instr:
        # Format: OPCODE + RDEST + OPEXT + IMM(8 bits)
        if len(operands) < 2:
            raise ValueError(f"Instruction {mnemonic} requires 2 operands (register, immediate)")
        
        # Parse destination register
        rdest_operand = parse_operand(operands[0])
        if rdest_operand['type'] != 'register':
            raise ValueError(f"First operand must be a register, got {operands[0]}")
        rdest = get_register_bits(rdest_operand['value'], REGISTERS)
        
        # Parse immediate value
        imm_operand = parse_operand(operands[1])
        if imm_operand['type'] != 'immediate':
            raise ValueError(f"Second operand must be an immediate value, got {operands[1]}")
        imm_high, imm_low = split_immediate_to_nibbles_signed(imm_operand['value'])
        
        # Build instruction: opcode + rdest + ext + imm_high + imm_low
        # But format is: opcode(4) + rdest(4)  + imm(8)
        # So: opcode + rdest + imm_high + imm_low
        instruction = opcode + rdest + imm_high + imm_low
    else:
        # Format: OPCODE + RDEST + OPEXT + RSRC
        if len(operands) < 2:
            raise ValueError(f"Instruction {mnemonic} requires at least 2 operands")
        
        # Parse destination register
        rdest_operand = parse_operand(operands[0])
        if rdest_operand['type'] != 'register':
            raise ValueError(f"First operand must be a register, got {operands[0]}")
        rdest = get_register_bits(rdest_operand['value'], REGISTERS)
        
        # Parse source register
        rsrc_operand = parse_operand(operands[1])
        if rsrc_operand['type'] != 'register':
            raise ValueError(f"Second operand must be a register, got {operands[1]}")
        rsrc = get_register_bits(rsrc_operand['value'], REGISTERS)
        
        # Build instruction: opcode + rdest + ext + rsrc
        instruction = opcode + rdest + ext + rsrc
    if len(instruction) != 16:
        raise ValueError(f"Error: Insturction is not 16-bits")
    return instruction



