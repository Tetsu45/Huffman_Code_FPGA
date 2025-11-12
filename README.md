# Huffman_decoder_Code_FPGA
https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
#Overview

This project implements a Huffman Decoder System usign  synthesizabl Verilog-2001 for simulation.
It provides a modular and reusable RTL architecture for decoding variable-length Huffman codes using a barrel-shift register (implemented in the shift_reg.v) controlled by a finite state machine (FSM).

The system we used  accepts encoded bit sequences (1–4 bits at a time), aligns and buffers them internally, and then produces decoded symbols as output. 

In this encoder the following modules were designed;

1. shift_register(Top-level with internal FSM instantiation)
   
Buffers incoming bits, aligns variable-length Huffman codewords, and interfaces with FSM for load/shift control.

2. decoder_fsm
It analyzes buffered bits, detects valid Huffman codewords, issues shift control, and produces decoded symbols.

3. Testbench
Drives encoded input sequences, verifies all codewords (-8 → +7), and logs timing and decoded outputs.

## Module Description 

                             shift_reg.v 
                             
- Bitstream Buffer with Internal FSM
Functionality

The shift_reg module acts as both the data path and control interface for the Huffman decoder.
It buffers incoming 1–4 bits per clock cycle and coordinates with the FSM to:

 -Append new bits into the buffer (load_bits control)
 -Remove bits once a valid symbol is decoded (shift_en control)
 -Maintain real-time count of valid bits (bit_count)
 -Forward decoded symbols (decodedData) with a valid handshake (tvalid)

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

        ┌─────────┐
        │  S_IDLE │◄────────────┐
        └────┬────┘             │
             │ svalid           │
             ▼                  │
        ┌─────────┐             │
    ┌──►│ S_DECODE│─────┐       │
    │   └────┬────┘     │       │
    │        │          │       │
    │  match_flag       │ !match & aready
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
        
        <img width="849" height="655" alt="Screenshot 2025-11-06 140946" src="https://github.com/user-attachments/assets/eaa3e140-a87b-4a0c-9cfd-f9f7e779ae33" />

![Huffman Decoder Simulation Screenshot](https://github.com/user-attachments/assets/eaa3e140-a87b-4a0c-9cfd-f9f7e779ae33)
