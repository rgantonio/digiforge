# :cyclone: Xcelium Cadence Simulator Guide

:cyclone: To run a simple verilator implementation, just do:

```bash
verilator --sv ../rtl/common/counter.sv ../tb/common/tb_counter.sv --binary
```

This will create an `obj_dir` from your current working directory where you invoked the `verilator` command. From there you should see the module of the 1st file you added (in this case `counter` is the 1st module) executable prefixed with `V`. For example, the above would generated `./obj_dir/Vcounter` executable. To run the simulation do `../obj_dir/Vcounter`.

:cyclone: Running with include directory:

```bash
verilator --sv ../tb/uart/tb_uart_txrx.sv ../rtl/uart/uart_rx.sv ../rtl/uart/uart_tx.sv  +incdir+../tb/tasks --binary
```

:cyclone: Disabling linting options that stop compilation:

```bash
verilator --sv ../tb/uart/tb_uart_txrx.sv ../rtl/uart/uart_rx.sv ../rtl/uart/uart_tx.sv  +incdir+../tb/tasks --binary -Wno-CASEINCOMPLETE -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND 
```
Note that these warnings prohibit the Verilator compiler to proceed. In thise case the `CASEINCOMPLETE` and the `WIDTHTRUNC` would report a warning if the `-Wno` was not added. Those warnings are blocking so be sure to add them.

:cyclone: Adding VCD dump:

```bash
verilator --sv ../tb/uart/tb_uart_txrx.sv ../rtl/uart/uart_rx.sv ../rtl/uart/uart_tx.sv  +incdir+../tb/tasks --binary -Wno-CASEINCOMPLETE -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND --trace
```

The `--trace` option allows VCD dumping. However, make sure that your testbench has the `dumpvars` option. If the `dumpvars` exists but the `--trace` is disabled, it will not dump any VCD file. When the `.vcd` file is dumped, you can open with `gtkwave sim.vcd` taking note of whatever `vcd` file you named it in the testbench.

