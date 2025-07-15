# :european_castle: :fire: The Digital Forge :fire: :european_castle:

 Welcome to the digital forge! 

This repository is a collection of designs, scripts, and documents for digital designs.
It is a design repository that acts like a journal for building upon knowledge and expertise.

# Repository Structure

- :computer: `rtl`: Contains several RTL designs ranging from essential components to complex systems. Some of these designs have tutorials and notes on their structure.
- :wrench: `tb`: Test benches for various designs. Used for proper replication of some experiments.
- :blue_book: `docs`: Tutorials, guides, and other useful information are found here. Other guides may be within their own respective directories.
- :hammer: :fire: `synthoria`: Useful scripts for running flows. Most useful especially for back-end tutorials.

# Quick Start

- The main open-source simulator is [Verilator](https://www.veripool.org/verilator/). To build a sample simulation, pick one of the test benches:

```bash
 make TEST_MODULE=tb_counter all
```

- This builds an executable stored inside the `bin` directory with the name of the testbench you called. To execute the simulation just call the binary:

```bash
bin/tb_counter
```

- For builds to be successful make sure you have:
    - The necessary `rtl` files under the `rtl` directory.
    - The necessary `tb` files under the `tb` directory.
    - The filelist listed in hierarchical order of all the files under the `flists` directory.
    - Make sure to name the `flist` accourding to the testbench name so that the `make` executes accordingly.