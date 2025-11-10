/*
 * Copyright (c) 2025 Jake Drew
 * SPDX-License-Identifier: Apache-2.0
 * 
 * qei.v: Quadrature Encoder Interface
 *
 * Inputs:
 *      - A (ui_in[0])
 *      - B (ui_in[1])
 *
 * Outputs:
 *      - DIR (uo_out[7], where 1 = forwards, 0 = backwards)
 *      - COUNT (uio_out + uo_out[6:0], which is 15 bit count)
 *      
 * Notes:
 *      - DIR is direction relate to last state, so as soon as COUNT starts
 *        decreasing DIR will be 0, it is not a negative.
 *      - Forward = increasing count.
 *      - COUNT is the count since the initial index
 *      
 */

module tt_um_jakedrew_qei (
    input  wire [7:0] ui_in,    // Dedicated user inputs
    output wire [7:0] uo_out,   // Dedicated user outputs
    input  wire [7:0] uio_in,   // IOs: Input path (unused)
    output wire [7:0] uio_out,  // IOs: Output path (unused)
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output) (unused)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // bidirectional pins. Setting as outputs for 8 more bits.
    assign uio_oe  = 8'hFF;

    // two-flip-flop synchronizers for A/B
    reg a1, a2, b1, b2;
    always @(posedge clk) begin
        a1 <= ui_in[0]; a2 <= a1;
        b1 <= ui_in[1]; b2 <= b1;
    end
    wire A = a2, B = b2;

    // quadrature decode
    reg prevA, prevB;
    wire [1:0] currentState  = {A,B}; // current state
    wire [1:0] prevState = {prevA,prevB}; //previous state

    wire forward = (prevState==2'b00 && currentState==2'b01) ||
               (prevState==2'b01 && currentState==2'b11) ||
               (prevState==2'b11 && currentState==2'b10) ||
               (prevState==2'b10 && currentState==2'b00);

    wire backward = (prevState==2'b00 && currentState==2'b10) ||
               (prevState==2'b10 && currentState==2'b11) ||
               (prevState==2'b11 && currentState==2'b01) ||
               (prevState==2'b01 && currentState==2'b00);

    reg [15:0] count;   // 16 bit, internal accumulator
    reg        dir;     // last-step direction: 1=forwards, 0=backwards

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prevA <= 1'b0; prevB <= 1'b0;
            count <= 16'd0; dir <= 1'b0;
        end else begin
            prevA <= A; prevB <= B;
            if (forward)      begin count <= count + 16'd1; dir <= 1'b1; end
            else if (backward) begin count <= count - 16'd1; dir <= 1'b0; end
        end
    end

    // visible pins: keep DIR + 7 LSBs; wraps mod 128 on the pins
    assign uo_out = rst_n ? {dir, count[6:0]} : 8'h00;
    assign uio_out = rst_n ? count[14:7] : 8'h00;   // next 8 bits of the counter

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, clk, rst_n, 1'b0};
    wire _unused_ok = &{ui_in[7:2], uio_in, 1'b0};  

endmodule
