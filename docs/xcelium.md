# Xcelium Cadence Simulator Guide

To run simple Xcelium:

```bash
xrun -sv ../rtl/common/counter.sv ../tb/common/tb_counter.sv +access+rw
```

With a filelist one can do:

```bash
xrun -sv -f <insert_filelist>
```

To run with a gui in place:

```bash
xrun -sv -gui ../rtl/common/counter.sv ../tb/common/tb_counter.sv +access+rw
```

# GUI Guide

## TODO: