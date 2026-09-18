# precret-stimulus

This repository contains the MATLAB and Psychtoolbox code used to generate and
present the visual stimulus for the **A 9.4 Tesla Dataset for Precision Retinotopy in the Human Brain**.

The stimulus paradigm is adapted from the publicly available code by
[Sam Schwarzkopf](https://osf.io/9tqjn/). Please consult the original resource
for the source implementation and associated documentation. It consists of a flickering
checkerboard bar that moves along the eight cardinal axes. Each bar position is
shown for one repetition time (TR). Rest periods are included at the beginning,
middle, and end of each run.

Please report issues or questions to
[Dana Ramadan](mailto:dana.ramadan@tuebingen.mpg.de).

## Paper and analysis code

A link to the corresponding paper will be available here upon acceptance.

The preprocessing and analysis code are available in the
[`precret-manuscript`](https://github.com/ramadanad/precret-manuscript.git) repository.

## Requirements

The stimulus code was developed and run using:

- MATLAB R2024b
- Psychtoolbox 3.0.20

The code was written for use at the 9.4 T MRI scanner at the Max Planck
Institute for Biological Cybernetics in Tübingen, Germany. Running it on a
different scanner or experimental setup will require changes to the 
display, or scanner-trigger configuration.


## Running the stimulus

The main stimulus script is:

```matlab
bars_dr.m
```

This script can be modified to configure the stimulus run. It calls the
`map_bars.m` function to generate the bar sequence.

A typical function call is:

```matlab
bars_dr(1, 1, bssfp, 1, 0)
```
**Press 'q' to start the stimulus presentation!**

## Aperture and timing

Check the aperture whenever the stimulus design is changed.

**Do not save or modify the aperture during a real experiment!** Saving the
aperture can cause MATLAB or Psychtoolbox to spend additional time writing
frames to disk. This may result in dropped frames, change the effective
flicker frequency, and invalidate the stimulus timing.
