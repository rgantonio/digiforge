//-------------------------
// Register Header File
// Author: Danknight
//
// Inspirted from the PULP's register header file,
// this file defines register declaration macros
// such that we don't have to repeat typing the same code.
//
// Made our own version as we see fit only.
// More info can be found from:
// https://github.com/pulp-platform/common_cells/blob/master/include/common_cells/registers.svh
//-------------------------

`ifndef REGISTERS_SVH
`define REGISTERS_SVH

`define REG_DEFAULT_CLK clk_i
`define REG_DEFAULT_RST rst_ni


// Flip-Flop with asynchronous active-low reset
// __q: Q output of FF
// __d: D input of FF
// __reset_value: value assigned upon reset
// (__clk: clock input)
// (__arst_n: asynchronous reset, active-low)
`define RegAsyncNrst(__q, __d, __reset_value, __clk = `REG_DEFAULT_CLK, __arst_n = `REG_DEFAULT_RST) \
  always_ff @(posedge (__clk) or negedge (__arst_n)) begin                           \
    if (!__arst_n) begin                                                             \
      __q <= (__reset_value);                                                        \
    end else begin                                                                   \
      __q <= (__d);                                                                  \
    end                                                                              \
  end

`endif
