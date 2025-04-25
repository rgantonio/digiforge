# :zap: Synthesis Guide :zap:

In this directory you will find useful tips and tricks for synthesis. 

## :zap: Goals for Synthesis

:zap: Main goal: Synthesize RTL to produce logic-gate (pre-GDS library) design
:zap: Fix target synthesis setup violations here
:zap: Generate and link special macros (e.g., memories, clock gates, clock logic, latches, and other IP)

## :sparkles: Best Practices

:star2: Over constrain your synthesis frequency to be 20-30% more than target signoff frequency
- E.g., Signoff frequency is at 800 MHz, then at the minimum your synthesis frequency needs to be 1 GHz

:star2: Use slow (SS) corner with high temperature as your baseline frequency

:star2: Properly set your SDC constraints
- Making sure your clock domain crossings, false paths, critical paths, are well defined.
- Also, very important, make sure to define all clocks that are used!
- Make sure to synchronize the IO ports for those where timing matters
- **Make sure to understand static timing analysis (STA) really well**.

:star2: Avoid latches!
- This is very situational only but as much as possible do not use latches.
- Clock gates use latches for this matter.

:star2: Read manuals (Synopsys or Cadence) to know proper optimization switches
- E.g., Understand how the tools do their optimizations. In DC compiler (Synopsys), the tool optimizes for the worst-negative slack (WNS) of each path group. Therefore, for the worst critical paths, make sure to constrain it to a unique path group so the synthesis tool can optimize for that path.

:star2: Timing reports are your friends and get used to reading these.
- One of the most useful metrics is the quality report (QoR) where it displays the WNS and total negative slack (TNS).
- Get used to using `report_timing -from <insert source> -to <insert destination>` reports as this are useful for debugging where critical paths are.

:star2: You **DO NOT** fix hold violations here.

:star2: Synthesis is just the *initial* design and therefore do not overspend too much time on this.


## :warning: Loose Shortcuts

Do these things at your own risk. The only way these actions are reasonable is if there is a *good* reason to skip the best practice.

:warning: Be *loose* on timing
- E.g., If target synthesis frequency was 1 GHz, you can get away with 900 MHz. 1GHz is 1 ns in period, while 900 MHz is 1.11 ns. That is just 0.11 ns difference in time which can be very small depending on the technology you are using.

:warning: Using typical (TT) corner as your baseline rather than the SS corner.
- The argument here is that, at least for academic purposes, we can always cale frequency down if we get SS corner samples.
- Most of the time, we get TT corner.