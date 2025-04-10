# :snowflake: Xcelium Cadence Simulator Guide

:snowflake: To run simple Xcelium:

```bash
xrun -sv ../rtl/common/counter.sv ../tb/common/tb_counter.sv +access+rw
```

:snowflake: With a filelist one can do:

```bash
xrun -sv -f <insert_filelist>
```

:snowflake: To run with a gui in place:

```bash
xrun -sv -gui ../rtl/common/counter.sv ../tb/common/tb_counter.sv +access+rw
```

:snowflake: In case there are some ``include` options, we need to add the include directory:

```bash
xrun -sv ../rtl/common/counter.sv ../tb/common/tb_counter.sv +access+rw -incdir ../tb/tasks
```

:snowflake: When you simulate with functions like `$urandom` or `$random`, usually the seed is fixed. To enforce random seed you need to add `-seed random`:

```bash
xrun -sv -gui ../rtl/common/counter.sv ../tb/common/tb_counter.sv +access+rw -seed random
```

# GUI Guide

## TODO: