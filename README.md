# RV-TX — Configurable RISC-V Vector/Tensor Compute Engine

> 🚧 **Status: Work in Progress** — This project is under active development. See [Progress](#progress) below for what's done so far.

RV-TX is a custom educational/research SoC architecture that combines a RISC-V scalar core, a configurable vector execution unit, and a TPU-style systolic tensor engine — built from scratch in SystemVerilog with an industry-style UVM verification environment.

It is inspired by (but does not attempt to fully implement):
- The RISC-V base ISA (RV32I) and the ratified RISC-V Vector extension (v1.0)
- GPU/SIMD-style vector execution
- Google TPU-style systolic array tensor compute (BF16 in, FP32 accumulate)
- Modern accelerator memory hierarchies (scratchpad + cache)
- Production-grade SystemVerilog/UVM verification methodology

This is a long-term flagship project (~650–900 hours), not a weekend build. The goal is to end up with something that looks like a miniature ASIC development + verification workflow — architecture docs, parameterized RTL, testbenches, coverage reports — rather than just a pile of source files.

---

## Architecture Overview

```
                              RV-TX
                                |
                +---------------+---------------+
                |                               |
        RISC-V Scalar Core                 Accelerator
                |                               |
          RV32I execution           +-----------+-----------+
                |                   |                       |
          Control Unit         Vector Unit             Tensor Unit
                |                   |                       |
                |               SIMD ALUs             Systolic Array
                |                   |                       |
                +-------------------+-----------------------+
                                    |
                            Memory Subsystem
                                    |
                        +-----------+-----------+
                        |                       |
                   Scratchpad                 Cache
                        |                       |
                        +-----------+-----------+
                                    |
                            AXI-like Interface
                                    |
                                 Memory
```

### Tensor Unit (Systolic Array)

```
        A matrix                 B matrix
           |                        |
           v                        v
   +-------------------------------------+
   |            N x N Systolic Array      |
   |                                       |
   |   MAC -> MAC -> MAC -> MAC ...        |
   |    v      v      v      v             |
   |   MAC -> MAC -> MAC -> MAC             |
   |    v      v      v      v             |
   |   ...                                 |
   +-------------------------------------+
                    |
                    v
              FP32 accumulator
```

Google's production TPU MXUs use 128×128 (or larger) systolic arrays; RV-TX starts deliberately small with an **8×8 / 16×16** configurable array as an educational implementation of the same dataflow concept.

---

## Design Goals

- **Scalar core:** A working RV32I pipeline (5-stage: IF → ID → EX → MEM → WB) with hazard detection, forwarding, and stalls.
- **Vector unit:** A configurable SIMD vector engine (parameterized `VLEN`, `LANES`, `ELEMENT_WIDTH`) loosely modeled on RISC-V "V" terminology — vector add/sub/mul, logical ops, comparisons, shifts, reductions, masking, and vector load/store.
- **Tensor unit:** A parameterized systolic array (starting 4×4 → 8×8 → optionally 16×16) performing `C = A × B` with BF16 inputs and FP32 accumulation, including input/weight/output buffering and valid/ready backpressure.
- **Memory subsystem:** L1 I-cache / D-cache for the scalar core plus a dedicated scratchpad and vector/tensor buffers, connected via an AXI-like handshake interface.
- **Verification:** A full SystemVerilog testbench (generator → driver → DUT → monitor → scoreboard → coverage) evolving into a proper UVM environment with CPU / vector / tensor agents, a reference model, assertions, and functional + code coverage closure (target >95%).

---

## Repository Structure *(planned / evolving)*

```
rv-tx/
├── rtl/
│   ├── core/          # RV32I scalar pipeline
│   ├── vector/         # Vector register file + vector ALU
│   ├── tensor/          # Systolic array + PE array + accumulators
│   ├── memory/          # Cache, scratchpad, buffers
│   └── interconnect/     # AXI-like interfaces
├── verif/
│   ├── tb/             # Non-UVM SystemVerilog testbenches
│   ├── uvm/             # UVM env: agents, sequences, scoreboard, ref model
│   └── coverage/        # Coverage plans + reports
├── docs/
│   ├── architecture/   # Diagrams, ISA subset notes, microarch specs
│   └── verification/    # Verification plan, test lists
└── README.md
```

---

## Roadmap

| Phase | Topic | Hours | Status |
|-------|-------|-------|--------|
| 0 | Verilog RTL foundation | 60 | ⬜ |
| 1 | SystemVerilog RTL | 50 | ⬜ |
| 2 | Computer Architecture | 100 | ⬜ |
| 3 | RISC-V ISA (RV32I / RV32M) | 45 | ⬜ |
| 4 | RV32I CPU RTL (5-stage pipeline) | 70 | ⬜ |
| 5 | Vector Architecture | 60 | ⬜ |
| 6 | Vector RTL | 50 | ⬜ |
| 7 | Tensor / Systolic Architecture | 60 | ⬜ |
| 8 | Tensor RTL | 60 | ⬜ |
| 9 | Memory Architecture | 60 | ⬜ |
| 10 | Interfaces / AXI concepts | 25 | ⬜ |
| 11 | SystemVerilog Verification (OOP, randomization, assertions, coverage) | 50 | ⬜ |
| 12 | Non-UVM Verification Environment | 40 | ⬜ |
| 13 | UVM | 70 | ⬜ |
| 14 | UVM Environment for RV-TX | 70 | ⬜ |
| 15 | Full Verification (CPU + Vector + Tensor + System tests) | 50 | ⬜ |
| 16 | Coverage Closure (>95% code/functional, 100% assertion) | 30 | ⬜ |
| | **Total** | **~900 h** | |

*(Mark phases ✅ as they're completed — update this table as the project progresses.)*

---

## Progress

> Update this section as you go — it's the first thing a visitor/recruiter will look at.

- [ ] Verilog/SystemVerilog RTL foundation (ALU, regfile, FIFO, RAM, UART, FSM, pipelined multiplier)
- [ ] RV32I single/multi-cycle datapath design
- [ ] RV32I 5-stage pipelined core
- [ ] Vector unit (design)
- [ ] Vector unit (RTL)
- [ ] Tensor / systolic unit (design)
- [ ] Tensor / systolic unit (RTL)
- [ ] Memory subsystem (cache + scratchpad)
- [ ] Non-UVM SystemVerilog testbench
- [ ] UVM verification environment
- [ ] Coverage closure

**Currently working on:** *(fill in — e.g. "Phase 0: building foundational RTL blocks (ALU, register file, FIFO) before starting the RV32I core")*

---

## Key References

Used deliberately and deeply rather than collecting many shallow tutorials:

- **RISC-V Specifications** — [riscv.org/technical/specifications](https://riscv.org/technical/specifications/) — RV32I base ISA and the ratified RISC-V Vector Extension v1.0
- **IEEE 1800 (SystemVerilog LRM)** — the authoritative language reference
- **Hennessy & Patterson**, *Computer Architecture: A Quantitative Approach* — pipelining, ILP, caches, memory hierarchy, OoO
- **[Ibex](https://github.com/lowRISC/ibex)** — production-quality, parameterized RISC-V core in SystemVerilog; used as a structural/verification reference (not copied from)
- **[Google Cloud TPU architecture docs](https://cloud.google.com/tpu/docs/system-architecture-tpu-vm)** — TensorCore, MXU, systolic arrays, BF16/FP32 accumulation
- **Accellera UVM** — [accellera.org/downloads/standards/uvm](https://www.accellera.org/downloads/standards/uvm) and [Verification Academy](https://verificationacademy.com/)
- **[Google riscv-dv](https://github.com/google/riscv-dv)** — randomized instruction-level verification reference
- **[Spike](https://github.com/riscv-software-src/riscv-isa-sim)** — RISC-V ISA simulator, used as a golden reference model for co-simulation

---

## Why This Project

This is being built as a serious RTL/DV portfolio project — the intent is to demonstrate, end to end: parameterized SystemVerilog RTL design, RISC-V microarchitecture, vector/tensor accelerator design, and professional-grade verification (assertions, functional coverage, UVM) — the same skill set used in real ASIC/accelerator teams (e.g. CPU, GPU, and TPU-adjacent design/verification roles).

## License

*(Add your license here, e.g. MIT — see [choosealicense.com](https://choosealicense.com/))*
