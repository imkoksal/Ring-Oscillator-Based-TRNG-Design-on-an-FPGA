# FPGA-Based True Random Number Generator (TRNG) using Fredkin Gate Ring Oscillators

An open-source hardware implementation of a True Random Number Generator (TRNG) targeting FPGA platforms. This project leverages metastability, thermal noise, and high-frequency jitter from custom combinatorial ring oscillators built with **Fredkin gates**[cite: 3], processed through hardware-level post-conditioning blocks to generate statistically robust random bitstreams validated by the NIST SP 800-22 test suite.

## Architecture & Design Choices (What We Used and Why)

### 1. Fredkin Gate-Based Ring Oscillators (`fred_gate.sv` & `ro_unit.sv`)
* **What we used:** Custom ring oscillator units constructed using Fredkin (controlled-swap) logic gates[cite: 3] instead of standard inverters or simple LUT loops. Each ring contains a configurable, **prime-numbered stage count** (`STAGE_ARRAY`)[cite: 2, 3].
* **Why we used it:** Standard ring oscillators suffer from frequency locking and harmonic coupling when placed close to one another on an FPGA fabric. Using Fredkin gates with prime-numbered stages across a multi-instance array ensures that each ring operates at a slightly different, non-Harmonic frequency, preventing injection locking and maximizing independent high-frequency jitter generation.

### 2. Synthesis Preservation Attributes (`KEEP` / `DONT_TOUCH`)
* **What we used:** SystemVerilog attributes (`(* KEEP = "true", DONT_TOUCH = "true" *]`) heavily applied to nets, wires, gate instantiations, and module hierarchies[cite: 1, 2, 3].
* **Why we used it:** FPGA synthesis tools (like Vivado or Gowin EDA) aggressively optimize logic by default—they tend to strip out combinatorial loops, treat ring oscillators as redundant logic, or merge identical paths. These attributes force the synthesizer and placer to preserve the raw combinatorial feedback loops necessary for oscillation and jitter.

### 3. Spatial XOR Reduction Tree (`fro_trng_array_top.sv`)
* **What we used:** A parallel reduction tree that combines outputs (`ro_samples_a`, `ro_samples_b`, `ro_samples_c`) across all 31 ring oscillator units using multiple XOR layers into a single `raw_entropy_bit`[cite: 2].
* **Why we used it:** A single ring oscillator output is heavily biased and susceptible to deterministic supply voltage noise. Spatially XORing multiple independent asynchronous rings amplifies the cumulative thermal jitter and flattens out individual systematic biases.

### 4. Jitter Decimation Unit (`fro_trng_array_top.sv`)
* **What we used:** A configurable counter-based decimation block (`DECIMATION_FACTOR = 5`) that sub-samples the high-frequency XOR tree[cite: 2].
* **Why we used it:** Ring oscillators run at hundreds of megahertz. Sampling them on every consecutive clock cycle results in high serial correlation between adjacent bits. Decimation introduces a controlled delay, ensuring that enough thermal jitter accumulates between successive sample captures.

### 5. Von Neumann Debiasing / Whitening Filter (`fro_trng_array_top.sv`)
* **What we used:** A hardware-implemented Von Neumann post-processing algorithm that evaluates non-overlapping consecutive bit pairs (`2'b01` -> `0`, `2'b10` -> `1`, while `2'b00` and `2'b11` are discarded)[cite: 2].
* **Why we used it:** Even with spatial XOR reduction, raw physical entropy sources can possess minor DC bias (unequal probabilities of 0s and 1s). The Von Neumann corrector mathematically eliminates bias, guaranteeing a uniform 50/50 probability distribution for the output stream.

### 6. 32-Bit Word Collector & ILA Debug Integration (`fro_trng_array_top.sv`)
* **What we used:** A shift-register assembler controlled by a `valid` strobe signal, coupled directly with an Integrated Logic Analyzer (`ila_ip`) core[cite: 2].
* **Why we used it:** This structures the whitened serial bits into clean, non-overlapping 32-bit words[cite: 2] and lets you capture live hardware bitstreams synchronously via the FPGA debugging fabric for export and testing against the NIST SP 800-22 statistical test suite.
