# FPGA-Based True Random Number Generator (TRNG)

An open-source hardware implementation of a True Random Number Generator (TRNG) targeting FPGA platforms, designed for cryptographic and high-entropy applications. This project leverages metastability and high-frequency jitter from Fredkin Gate based ring oscillators, processed through hardware-level post-conditioning blocks to generate robust random bitstreams validated by the NIST SP 800-22 test suite.

## Key Features
* **Entropy Source:** Multi-instance Ring Oscillator (RO) arrays designed with prime-numbered inverter stages and physical placement constraints (`pblocks` / area constraints) to minimize correlation and injection locking.
* **Post-Processing Pipeline:** Hardware-implemented Von Neumann debiaser and decimation/sampling logic to correct bit-bias and reduce sequential dependency.
* **Data Capture & Interface:** Integrated Logic Analyzer (ILA) / UART streaming interfaces to export raw and conditioned bitstreams for statistical validation.
* **Multi-Platform Support:** Synthesizable HDL design for the Xilinx Zynq (PYNQ-Z1) 

## Repository Structure
```text
├── hdl/                  # Verilog / SystemVerilog source files (RO arrays, post-processing)
├── constraints/          # Pin mappings and physical placement / timing constraints (.xdc / .cst) for the PYNQ Z1 board
├── scripts/              # TCL script for data logging and Python script for concatenating output files
└── verification/         # Contains a C based basic and fast verification program
