# Huffman_decoder_Code_FPGA

#Overview

This project implements a Huffman Decoder System usign  synthesizable Verilog-2001 for simulation.
It provides a modular and reusable RTL architecture for decoding variable-length Huffman codes using a barrel-shift register (implemented in the shift_reg.v) controlled by a finite state machine (FSM).

The system we used  accepts encoded bit sequences (1–4 bits at a time), aligns and buffers them internally, and then produces decoded symbols as output. 

In this encoder the following modules were designed;

1. shift_register(Top-level with internal FSM instantiation)

Reverse and buffers incoming bits, aligns variable-length Huffman codewords, and interfaces with FSM for load/shift control.

2. decoder_fsm
It analyzes buffered bits, detects valid Huffman codewords, issues shift control, and produces decoded symbols.

3. Testbench
Drives encoded input sequences, verifies all codewords (-8 → +7), and logs timing and decoded outputs.

## Module Description 

                             shift_reg.v 
                             
- Bitstream Buffer with Internal FSM
Functionality

The shift_reg module acts as both the data path and control interface for the Huffman decoder.
It reverses and buffers incoming 1–4 bits per clock cycle and coordinates with the FSM to:

 -Append new bits starting from a LSB position into the buffer (load_bits control)
 -Remove bits once a valid symbol is decoded (shift_en control)
 -Maintain real-time count of valid bits (bit_count)
 -Forward decoded symbols (decodedData) with a valid handshake (tvalid)
 
# shift_reg process flow
![SHIFT_REG](https://github.com/Tetsu45/Huffman_Code_FPGA/blob/barrel_shifter_decoder_reversed/huff_shift_page-0001.jpg)

Key Features

   -Barrel-Shift logic (synthesizable) for efficient bit movement

   -Parameterization via MAX_CODE (supports up to 9-bit Huffman codes)

   -FSM co-instantiation internally — fully encapsulated design

| Port               | Direction | Description                             |
| ------------------ | --------- | --------------------------------------- |
| `clk`, `reset`     | Input     | System clock and synchronous reset      |
| `in_bits[3:0]`     | Input     | Incoming encoded bits                   |
| `in_len[2:0]`      | Input     | Number of valid bits in `in_bits`       |
| `sValid`           | Input     | Indicates valid data on `in_bits`       |
| `decodedData[3:0]` | Output    | Final decoded symbol                    |
| `tvalid`           | Output    | High when a decoded symbol is available |


Also, it manages:

-Bitstream pattern recognition

-Bit-length checking (using bit_count)

-Symbol decoding and match flag generation

-Control of the shift register (load_bits, shift_en, and shift_len)


Bit Extraction Logic
After a Huffman code match, the FSM shifts out decoded bits:

else if (shift_en && (bit_count >= shift_len) && (shift_len != 0)) begin
    shift_buf <= shift_buf >> shift_len;
    bit_count <= bit_count - shift_len;
end


**Note**: The `else if` creates mutual exclusion between loading and shifting, preventing simultaneous operations in this implementation.





                  decoder_fsm.v - Control FSM

**Purpose**: Orchestrates bit loading, Huffman matching, and symbol extraction via a finite state machine.
In essence it controls when to load input bits, when to attempt symbol decoding, and when to output a valid decoded symbol.


#### **Key Responsibilities**
- Manage the handshake between input and the shift register.
- Check the bit buffer against known Huffman codes.
- Trigger shift operations when a valid match is detected.
- Generate valid decoded symbols via the `tvalid` signal.


#### **Internal FSM States**
| State | Name | Description |
|:------|:------|:-------------|
| `S_IDLE` | Waits for valid input (`svalid=1`). |
| `S_LOAD` | Loads a new chunk of bits into the shift register. |
| `S_DECODE` | Continuously compares current bit window to known Huffman patterns. |
| `S_SHIFT` | Shifts out the matched number of bits from the buffer. |
| `S_OUTPUT` | Asserts `tvalid` and outputs the decoded symbol. |


        ┌─────────┐
        │  S_IDLE │
        └────┬────┘             
             │ svalid           
             ▼                  
        ┌─────────┐◄────────────┐             
    ┌──►│ S_DECODE│─────┐       │
    │   └────┬────┘     │       │
    │        │          │       │
    │  match_flag       │ !match & aready & svalid
    │        │          │       │
    │        ▼          ▼       │
    │   ┌─────────┐ ┌──────┐   │
    │   │ S_SHIFT │ │S_LOAD│───┘
    │   └────┬────┘ └──────┘
    │        │
    │        ▼
    │   ┌─────────┐
    └───┤ S_OUTPUT│
        └─────────┘
#  FSM Diagram
![FSM Diagram](https://raw.githubusercontent.com/Tetsu45/Huffman_Code_FPGA/barrel_shifter_decoder_reversed/fsm_huff_page-0001.jpg)

    



#### **Matching Logic**
The FSM checks the most-significant bits of `shift_buf` (`shift_buf[8:0]`) based on how many bits are currently valid (`bit_count`):
- **1-bit codes:** `0` → symbol `0`
- **3-bit codes:** `100` → symbol `+1`
- **4-bit codes:** multiple patterns like `1010`, `1100`, etc.
- **5- to 9-bit codes:** for extended range symbols (−8 to +7)

# Overall Design
![Design](https://github.com/Tetsu45/Huffman_Code_FPGA/blob/barrel_shifter_decoder_reversed/huff_page-0001.jpg)

                  tb_shift_reg.v

The Testbench applies sequentially all known Huffman codewords (−8 to +7) to verify decoding correctness and handshake stability.

   Test Sequence
It applies 4-bit chunks to in_bits with controlled delays.
It uses the task send_chunk(bits, len) to ensure consistent timing.

Monitors all internal states, including:
   -shift_buf
   -bit_count
   -shift_en (FSM control signal)
   -decodedData and tvalid outputs



          +--------------------+
          |   Testbench (TB)   |
          |  sends chunks      |
          +--------------------+
                    |
                    v
         +---------------------+
         |    Shift Register   | <-----+
         | shift_buf, bit_cnt  |       |
         +---------------------+       |
                    |                  |
                    v                  |
         +---------------------+       |
         |    Decoder FSM      | ------+
         | Match & Control     |
         +---------------------+
                    |
                    v
         +---------------------+
         |  Decoded Symbol Out |
         +---------------------+
