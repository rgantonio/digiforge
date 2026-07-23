# Exercise #1 — Parameterized Register File

**Phase:** 1 — RTL Foundations
**Level:** 1
**Track:** A — Foundations
**Prerequisites:** None

---

## 1. Learning Objectives

- Understand synchronous active-low reset and standard port naming conventions
- Write clean, parameterized RTL using `parameter` (Verilog) and generator classes (Chisel)
- Handle simultaneous read/write port conflicts correctly
- Build intuition for how register files map to flip-flop arrays in synthesis

---

## 2. Specification

### 2.1 Overview

Design a parameterized, synchronous register file with:

- `NUM_RD_PORTS` independent read ports (asynchronous / combinational read)
- `NUM_WR_PORTS` independent write ports (synchronous write, rising-edge clocked)
- Synchronous, **active-low** reset (`rst_ni`): all registers cleared to 0 when `rst_ni` is deasserted low
- Write-before-read (aka "new data") conflict resolution when a read and write address match in the same cycle

Register 0 is **hardwired to zero** — writes to address 0 are silently ignored and reads from address 0 always return 0. This mirrors the RISC-V x0 convention and is a useful design discipline.

Port naming convention:

| Language    | Rule |
|-------------|------|
| SystemVerilog | `_i` suffix on all inputs, `_o` suffix on all outputs, `_n` infix on active-low signals (e.g. `rst_ni`) |
| Chisel      | Idiomatic camelCase; direction is encoded in `Input(...)`/`Output(...)` types so `_i`/`_o` suffixes are redundant. Reset uses Chisel's implicit `reset` signal (active-high by default) — no explicit reset port is declared in the IO bundle |

---

### 2.2 Parameters

| Name           | Type    | Default | Valid Range | Description                       |
|----------------|---------|---------|-------------|-----------------------------------|
| `DATA_W`       | integer | 32      | 1–128       | Width of each register in bits    |
| `ADDR_W`       | integer | 5       | 1–8         | Address width; depth = 2^ADDR_W   |
| `NUM_RD_PORTS` | integer | 2       | 1–8         | Number of simultaneous read ports |
| `NUM_WR_PORTS` | integer | 1       | 1–4         | Number of simultaneous write ports|

Derived: `DEPTH = 2 ** ADDR_W`

---

### 2.3 Port List

```
Module: reg_file

Inputs:
  clk_i                                      -- system clock
  rst_ni                                     -- synchronous active-low reset

  -- Write ports (one set per write port, indexed 0..NUM_WR_PORTS-1)
  wr_en_i   [NUM_WR_PORTS-1:0]               -- write enable, one bit per port
  wr_addr_i [NUM_WR_PORTS-1:0][ADDR_W-1:0]  -- write address per port
  wr_data_i [NUM_WR_PORTS-1:0][DATA_W-1:0]  -- write data per port

  -- Read ports (one set per read port, indexed 0..NUM_RD_PORTS-1)
  rd_addr_i [NUM_RD_PORTS-1:0][ADDR_W-1:0]  -- read address per port

Outputs:
  rd_data_o [NUM_RD_PORTS-1:0][DATA_W-1:0]  -- read data per port (combinational)
```

> **Note:** All 2-D packed arrays use SystemVerilog syntax. In Chisel use `Vec(NUM_WR_PORTS, UInt(ADDR_W.W))`.

---

### 2.4 Functional Behaviour

#### Reset

On the rising edge where `rst_ni` is **low**, all `DEPTH` registers are cleared to 0.
Normal operation resumes when `rst_ni` is **high**.

#### Write (synchronous)

On each rising clock edge (when `rst_ni` is high):

- For each write port `i` where `wr_en_i[i]` is high:
  - If `wr_addr_i[i] != 0`: write `wr_data_i[i]` into register `wr_addr_i[i]`
  - If `wr_addr_i[i] == 0`: no-op (register 0 stays 0)
- If two write ports target the same address simultaneously, **port with the higher index wins** (priority: port `NUM_WR_PORTS-1` > … > port 0).

#### Read (asynchronous / combinational)

- For each read port `j`:
  - **Write-before-read (WBR) forwarding:** If any enabled write port `i` targets the same address as `rd_addr_i[j]` in the same cycle, `rd_data_o[j]` returns the *new* (to-be-written) value, not the stored value.
  - If multiple write ports match the same read address, the highest-index write port is forwarded.
  - If `rd_addr_i[j] == 0`: always returns 0, regardless of WBR.
  - Otherwise: returns the current register value.

---

### 2.5 Timing Diagram

1-write-port, 1-read-port example with `DATA_W=8`, `ADDR_W=2` (4 registers):

```wavedrom
{ "signal": [
  { "name": "clk_i",     "wave": "P......." },
  { "name": "rst_ni",    "wave": "01......" },
  { "name": "wr_en_i",   "wave": "0.10.10." },
  { "name": "wr_addr_i", "wave": "x.2x.2x.", "data": ["0x1","0x1"] },
  { "name": "wr_data_i", "wave": "x.2x.2x.", "data": ["0xAB","0xCD"] },
  {},
  { "name": "rd_addr_i", "wave": "x.2.....", "data": ["0x1"] },
  { "name": "rd_data_o", "wave": "x.345.6.", "data": ["0x00","0xAB(WBR)","0xAB","0xCD(WBR)"] }
]}
```

Key moments:

| Cycle | Event |
|-------|-------|
| 0 | `rst_ni` low — all registers cleared to 0 |
| 1 | `rst_ni` high — normal operation begins |
| 2 | `wr_en_i` high, addr=0x1, data=0xAB. Read of 0x1 sees **0xAB via WBR** |
| 3 | `wr_en_i` low. Read of 0x1 returns stored **0xAB** |
| 4–5 | No write. Read returns **0xAB** |
| 5 | Second write to 0x1 with 0xCD. Read sees **0xCD via WBR** |

> Render this diagram at [wavedrom.com](https://wavedrom.com) or via the VS Code WaveDrom plugin.

---

## 3. Implementation Notes

### 3.1 Verilog

```verilog
module reg_file #(
    parameter int DATA_W       = 32,
    parameter int ADDR_W       = 5,
    parameter int NUM_RD_PORTS = 2,
    parameter int NUM_WR_PORTS = 1
)(
    input  logic                                        clk_i,
    input  logic                                        rst_ni,
    // Write ports
    input  logic [NUM_WR_PORTS-1:0]                    wr_en_i,
    input  logic [NUM_WR_PORTS-1:0][ADDR_W-1:0]        wr_addr_i,
    input  logic [NUM_WR_PORTS-1:0][DATA_W-1:0]        wr_data_i,
    // Read ports
    input  logic [NUM_RD_PORTS-1:0][ADDR_W-1:0]        rd_addr_i,
    output logic [NUM_RD_PORTS-1:0][DATA_W-1:0]        rd_data_o
);

    localparam int DEPTH = 1 << ADDR_W;

    // Register array — index 0 is never written
    logic [DATA_W-1:0] mem [DEPTH];

    // -------------------------------------------------------------------------
    // Write logic (synchronous, active-low reset)
    // Lower-priority ports written first so higher-index wins on address collision
    // -------------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            for (int i = 0; i < DEPTH; i++)
                mem[i] <= '0;
        end else begin
            for (int i = 0; i < NUM_WR_PORTS; i++) begin
                if (wr_en_i[i] && (wr_addr_i[i] != '0))
                    mem[wr_addr_i[i]] <= wr_data_i[i];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read logic (combinational, with WBR forwarding)
    // TODO: implement this section.
    //
    // For each read port j (0..NUM_RD_PORTS-1):
    //   1. Default: rd_data_o[j] = mem[rd_addr_i[j]]
    //   2. Override with WBR: for each write port i where wr_en_i[i] is high
    //      and wr_addr_i[i] == rd_addr_i[j], forward wr_data_i[i].
    //      Highest-index write port wins on collision.
    //   3. Guard: if rd_addr_i[j] == '0, always return '0.
    // -------------------------------------------------------------------------

endmodule
```

### 3.2 Chisel

In Chisel, `clock` and `reset` are **implicit ports** and are not declared in the IO bundle.
Reset is Chisel's built-in `reset` signal (synchronous, active-high by default) — use it
directly inside `when(reset.asBool)` without adding any explicit port. Port names use
idiomatic camelCase since `Input(...)`/`Output(...)` already encode direction.

```scala
import chisel3._
import chisel3.util._

class RegFile(
    dataW:      Int = 32,
    addrW:      Int = 5,
    numRdPorts: Int = 2,
    numWrPorts: Int = 1
) extends Module {

    val depth = 1 << addrW

    val io = IO(new Bundle {
        val wrEn   = Input(Vec(numWrPorts, Bool()))
        val wrAddr = Input(Vec(numWrPorts, UInt(addrW.W)))
        val wrData = Input(Vec(numWrPorts, UInt(dataW.W)))
        val rdAddr = Input(Vec(numRdPorts, UInt(addrW.W)))
        val rdData = Output(Vec(numRdPorts, UInt(dataW.W)))
    })

    // Mem = asynchronous (combinational) read — matches the spec.
    // SyncReadMem = synchronous read — would change WBR forwarding semantics.
    val mem = Mem(depth, UInt(dataW.W))

    // -------------------------------------------------------------------------
    // Write logic (synchronous, uses implicit reset)
    // -------------------------------------------------------------------------
    // TODO: use when(reset.asBool) / .otherwise inside a sequential context.
    // Guard each write: when(io.wrEn(i) && io.wrAddr(i) =/= 0.U) { mem.write(...) }
    // Lower-index ports first so higher-index wins on collision.

    // -------------------------------------------------------------------------
    // Read logic (combinational, with WBR forwarding)
    // -------------------------------------------------------------------------
    // TODO: for each read port j, build a priority mux over write ports.
    // Hint: start from mem.read(io.rdAddr(j)) as the default,
    // then fold over write ports 0..numWrPorts-1, overriding on address match.
    // Final guard: force 0.U when io.rdAddr(j) === 0.U
}
```

---

## 4. Testbench Requirements

Verify all of the following test cases:

| ID    | Description |
|-------|-------------|
| TC-01 | Asserting `rst_ni` low clears all registers to 0 |
| TC-02 | Basic write then read (no forwarding) returns the written value |
| TC-03 | Write to register 0 is silently ignored; read from 0 always returns 0 |
| TC-04 | WBR forwarding: read and write to the same address in the same cycle returns new data |
| TC-05 | Two write ports targeting different addresses both commit correctly |
| TC-06 | Two write ports targeting the same address: higher-index port wins |
| TC-07 | WBR with multiple write ports: the highest-index matching write port is forwarded |
| TC-08 | Two read ports return independent data simultaneously |
| TC-09 | Stress: randomized read/write sequences cross-checked against a software reference model |

For TC-09, implement a simple integer array in your testbench language as a golden reference model and compare outputs cycle-by-cycle.

---

## 5. Study Questions

### Conceptual

1. What is the difference between write-before-read (WBR) and read-before-write (RBW) semantics? Which does a typical FPGA block RAM use by default?
2. Why is hardwiring register 0 to zero useful in a processor context?
3. What are the tradeoffs between active-high and active-low reset in an ASIC flow? Why does much of the industry standardize on active-low?

### Design Decisions

4. How would adding a `rd_en_i` per read port affect timing and area?
5. What changes if you replace `Mem` with `SyncReadMem` in Chisel? How must the WBR forwarding logic change?
6. If `NUM_WR_PORTS = 2` and both ports write to the same address in the same cycle, your priority scheme ensures determinism. What alternative priority schemes exist, and what are their tradeoffs?

### Analysis & Estimation

7. For default parameters (`DATA_W=32`, `ADDR_W=5`, `NUM_RD_PORTS=2`, `NUM_WR_PORTS=1`), how many flip-flops do you expect in the synthesized netlist? Verify against your synthesis report.
8. How does increasing `NUM_RD_PORTS` affect area? Is the relationship linear? Why or why not?

### Synthesis & Implementation

9. Does your synthesis tool infer flip-flops or distributed/block RAM for the register array? What synthesis directive or attribute controls this on your target?
10. Examine the critical path in your timing report. Is it in the read (combinational) path or the write (sequential) path? Why?

## 6. Extensions (Optional)

- Add byte-write enables: `wr_be_i [DATA_W/8-1:0]` for sub-word writes
- Add a `rd_en_i` enable per read port (returns 0 when disabled)
- Parameterize the write-port conflict resolution policy (first-wins vs. last-wins via a parameter)
- Add an ECC (SECDED) layer over the register array

---

## 7. Reflection

*(Complete after finishing your implementation)*

1. What was the trickiest part of the WBR forwarding logic to get right?

<details>
<summary>Answer</summary>

Having to make sure that the read is MUX'd into the output read ports when the write and read address are the same.

</details>

2. Did your synthesis tool infer flip-flops or distributed RAM? What controlled that inference?

<details>
<summary>Answer</summary>

Synthesizing with a custom standard cell library would generate flip-flops.

</details>

3. How did the Chisel implementation compare to Verilog in terms of expressing parameterization and the forwarding priority mux?

<details>
<summary>Answer</summary>

Chisel utilizes the MUX but in Verilog, it was doable with simple logic. Although both can work or be implemented similar ways.

</details>

4. What would you do differently if you were integrating this register file into a 5-stage RISC pipeline?

<details>
<summary>Answer</summary>

In a 5-stage RISC pipeline, typically it is only a single-write and dual read ports. Not unless it is customized.

</details>
