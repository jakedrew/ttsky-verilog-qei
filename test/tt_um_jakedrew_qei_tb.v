`timescale 1ns/1ps
module tt_um_jakedrew_qei_tb;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    reg  [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena, clk, rst_n;

    tt_um_jakedrew_qei dut(
        .ui_in(ui_in), .uo_out(uo_out),
        .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe),
        .ena(ena), .clk(clk), .rst_n(rst_n)
    );

    // 100MHz clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // VCD
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tt_um_jakedrew_qei_tb);
    end

    integer junit_fd;
    task junit_pass; begin
        junit_fd = $fopen("results.xml","w");
        if (junit_fd) begin
            $fwrite(junit_fd,
                "<testsuite tests=\"1\"><testcase classname=\"tt_um_jakedrew_qei\" name=\"rtl\"/></testsuite>");
            $fclose(junit_fd);
        end
    end endtask
    task junit_fail; input [1023:0] msg; begin
        junit_fd = $fopen("results.xml","w");
        if (junit_fd) begin
            $fwrite(junit_fd,
                "<testsuite tests=\"1\" failures=\"1\"><testcase classname=\"tt_um_jakedrew_qei\" name=\"rtl\"><failure message=\"%0s\"/></testcase></testsuite>",
                msg);
            $fclose(junit_fd);
        end
    end endtask

    // 15-bit observable count
    function [14:0] full15;
        input [7:0] uo, uio;
        begin full15 = {uio, uo[6:0]}; end
    endfunction

    integer k;
    localparam integer WAIT_CYCLES = 16;

    task wait_sync;
        begin
            for (k = 0; k < WAIT_CYCLES; k = k + 1) @(posedge clk);
        end
    endtask

    task drive_ab; // drive A and B and wait
        input a, b;
        begin
            ui_in[0] = a;
            ui_in[1] = b;
            wait_sync();
        end
    endtask

    // simple forward and backward full cycles functions
    task fwd_cycle;
        begin
            drive_ab(0,1); // 00->01
            drive_ab(1,1); // 01->11
            drive_ab(1,0); // 11->10
            drive_ab(0,0); // 10->00
        end
    endtask

    task bwd_cycle;
        begin
            drive_ab(1,0); // 00->10
            drive_ab(1,1); // 10->11
            drive_ab(0,1); // 11->01
            drive_ab(0,0); // 01->00
        end
    endtask

    // read only 7-bit LSBs (ignore DIR)
    function [6:0] cnt7;
        input [7:0] x; begin cnt7 = x[6:0]; end
    endfunction

    integer before7, after7;
    integer c0, c1;

    // check +1 step and dir=1
    task check_fwd_step;
        input a, b;
        begin
            before7 = cnt7(uo_out);
            drive_ab(a,b);
            after7 = cnt7(uo_out);
            if (((after7 - before7) & 7'h7F) != 7'd1) begin
                $display("FAILED: expected +1 on step to A=%0d B=%0d, delta=%0d",
                         a, b, ((after7 - before7) & 7'h7F));
                junit_fail("step +1 check failed");
                $finish_and_return(1);
            end
            `ifdef GL_TEST
                @(posedge clk);
            `endif
            if (uo_out[7] !== 1'b1) begin
                $display("FAILED: DIR not forward on step to A=%0d B=%0d", a, b);
                junit_fail("dir forward check failed");
                $finish_and_return(1);
            end
        end
    endtask

    // check -1 step and dir=0
    task check_bwd_step;
        input a, b;
        begin
            before7 = cnt7(uo_out);
            drive_ab(a,b);
            after7 = cnt7(uo_out);
            if (((before7 - after7) & 7'h7F) != 7'd1) begin
                $display("FAILED: expected -1 on step to A=%0d B=%0d, delta=%0d",
                         a, b, ((before7 - after7) & 7'h7F));
                junit_fail("step -1 check failed");
                $finish_and_return(1);
            end
            `ifdef GL_TEST
                @(posedge clk);
            `endif
            if (uo_out[7] !== 1'b0) begin
                $display("FAILED: DIR not backward on step to A=%0d B=%0d", a, b);
                junit_fail("dir backward check failed");
                $finish_and_return(1);
            end
        end
    endtask

    // test it
    initial begin
        // reset + settle
        ui_in = 8'h00; uio_in = 8'h00; ena = 1'b1;
        rst_n = 1'b0; repeat (4) @(posedge clk);
        rst_n = 1'b1; wait_sync(); wait_sync();

        // align to 00
        drive_ab(0,0);

        // forwards x4
        check_fwd_step(0,1);
        check_fwd_step(1,1);
        check_fwd_step(1,0);
        check_fwd_step(0,0);

        // backwards x4
        check_bwd_step(1,0);
        check_bwd_step(1,1);
        check_bwd_step(0,1);
        check_bwd_step(0,0);

        // 8 forward cycles = +32 counts
        before7 = cnt7(uo_out);
        repeat (8) fwd_cycle();
        after7 = cnt7(uo_out);
        if (((after7 - before7) & 7'h7F) != 7'd32) begin
            $display("FAILED: 8 forward cycles, delta=%0d",
                     ((after7 - before7) & 7'h7F));
            junit_fail("8 forward cycles check failed");
            $finish_and_return(1);
        end

        // +256 counts
        `ifdef GL_TEST
            begin : pins_256_fwd
                integer p0, p1;
                p0 = full15(uo_out, uio_out);
                repeat (64) fwd_cycle();
                p1 = full15(uo_out, uio_out);
                if (((p1 - p0) & 15'h7FFF) != 15'd256) begin
                    $display("FAILED: +256 via pins (delta=%0d)", ((p1 - p0) & 15'h7FFF));
                    junit_fail("+256 pins check failed");
                    $finish_and_return(1);
                end
            end
        `else
            begin : internal_256_fwd
                integer c0, c1;
                c0 = tt_um_jakedrew_qei_tb.dut.count;
                repeat (64) fwd_cycle();
                c1 = tt_um_jakedrew_qei_tb.dut.count;
                if (((c1 - c0) & 16'hFFFF) != 16'd256) begin
                    $display("FAILED: +256 internal (delta=%0d)", ((c1 - c0) & 16'hFFFF));
                    junit_fail("+256 internal check failed");
                    $finish_and_return(1);
                end
            end
        `endif

        // −256 counts
        `ifdef GL_TEST
            begin : pins_256_bwd
                integer p0, p1;
                p0 = full15(uo_out, uio_out);
                repeat (64) bwd_cycle();
                p1 = full15(uo_out, uio_out);
                if (((p0 - p1) & 15'h7FFF) != 15'd256) begin
                    $display("FAILED: -256 via pins (delta=%0d)", ((p0 - p1) & 15'h7FFF));
                    junit_fail("-256 pins check failed");
                    $finish_and_return(1);
                end
            end
        `else
            begin : internal_256_bwd
                integer c0, c1;
                c0 = tt_um_jakedrew_qei_tb.dut.count;
                repeat (64) bwd_cycle();
                c1 = tt_um_jakedrew_qei_tb.dut.count;
                if (((c0 - c1) & 16'hFFFF) != 16'd256) begin
                    $display("FAILED: -256 internal (delta=%0d)", ((c0 - c1) & 16'hFFFF));
                    junit_fail("-256 internal check failed");
                    $finish_and_return(1);
                end
            end
        `endif

        $display("PASS");
        junit_pass();
        $finish_and_return(0);
    end
endmodule
