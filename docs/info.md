<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

qei.v: Quadrature Encoder Interface

Inputs:
    - A (ui_in[0])
    - B (ui_in[1])

Outputs:
    - DIR (uo_out[7], where 1 = forwards, 0 = backwards)
    - COUNT (uio_out + uo_out[6:0], which is 15 bit count)
    
Notes:
    - DIR is direction relate to last state, so as soon as COUNT starts
    decreasing DIR will be 0, it is not a negative.
    - Forward = increasing count.
    - COUNT is the count since the initial index
      
## How to test

Connect a quadrature output to A and B, and then read COUNT / DIR.

## External hardware

Quadrature interface device
