# :battery: Synthesis Guide :battery:

In this directory you will find useful tips and tricks for power analysis using PrimeTime. 

## :battery: Goals for Power Analysis

:battery: To have a delay annotated power analysis of a design and good enough accuracy on the measurement.

## :battery: Best Practices

:battery: Take note of the difference between time-based and average-based power analysis. Time-based measures peak and average performance, while keeping track of when the peak occurs. So usually, you use `.vcd` files here because there is also timing information. Average, just looks into the average toggling or switching which are provided in `.saif` files.

:battery: Make sure to know how to obtain `.vcd` and `.saif` files from simulators. Also, take note that you need to analyze a synthesized or PnR'd design. Not an RTL one. You also need to make sure `.sdf` annotation is applied for accurate switching, toggling, and glitching effects. As much as possible, your SDf annotation should be 100% complete and error free. Warnings are acceptable but you need to double check.

:battery: When you have a synthesis directory, make sure to also have the power analysis scripts beside it. Better if you organize all files together and accordingly.


