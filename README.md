# Huffman_decoder_Code_FPGA

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

