`timescale 1ns / 1ps

import pkg::*;

module Top4_tb;

    logic clk;
    logic rst_n;
    logic blkIn;

    data_t idata [0:7];

    logic [1:0] outrank;
    data_t      result;
    logic       out_valid;

    // ============================================================
    // DUT
    // ============================================================

    Top4 dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .blkIn     (blkIn),
        .idata     (idata),
        .outrank   (outrank),
        .result    (result),
        .out_valid (out_valid)
    );

    // ============================================================
    // Clock: 10 ns period
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Waveform
    // ============================================================

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, Top4_tb, "+all");
    end

    // ============================================================
    // Send one block
    //
    // 一個 block 有四個 groups。
    // 每個 group 在一個 cycle 送入八筆資料。
    //
    // group 0: base+0, base+4,  base+8,  ...
    // group 1: base+1, base+5,  base+9,  ...
    // group 2: base+2, base+6,  base+10, ...
    // group 3: base+3, base+7,  base+11, ...
    //
    // 整個 block 包含 base ~ base+31。
    // ============================================================

    task automatic send_block(input integer base);

        integer group;
        integer lane;

        begin
            for (group = 0; group < 4; group = group + 1) begin
                @(negedge clk);

                // blkIn 只在 group 0 拉高
                blkIn = (group == 0);

                for (lane = 0; lane < 8; lane = lane + 1) begin
                    idata[lane] = base + lane * 4 + group;
                end
            end
        end

    endtask

    // ============================================================
    // Insert idle cycles
    // ============================================================

    task automatic idle_cycles(input integer cycles);

        integer cycle;
        integer lane;

        begin
            for (cycle = 0; cycle < cycles; cycle = cycle + 1) begin
                @(negedge clk);

                blkIn = 1'b0;

                for (lane = 0; lane < 8; lane = lane + 1) begin
                    idata[lane] = '0;
                end
            end
        end

    endtask

    // ============================================================
    // Main stimulus
    // ============================================================

    initial begin
        rst_n = 1'b0;
        blkIn = 1'b0;

        for (int i = 0; i < 8; i++) begin
            idata[i] = '0;
        end

        // Hold reset
        repeat (2) @(posedge clk);

        // Release reset at negedge
        @(negedge clk);
        rst_n = 1'b1;

        // --------------------------------------------------------
        // Block 0: values 0 ~ 31
        //
        // Expected output:
        // 31, 30, 29, 28
        // --------------------------------------------------------

        send_block(0);

        // --------------------------------------------------------
        // Block 1 緊接 Block 0
        //
        // values 100 ~ 131
        // Expected output:
        // 131, 130, 129, 128
        // --------------------------------------------------------

        send_block(100);

        // --------------------------------------------------------
        // 中間空三個 cycles
        // --------------------------------------------------------

        idle_cycles(3);

        // --------------------------------------------------------
        // Block 2: values -32 ~ -1
        //
        // Expected output:
        // -1, -2, -3, -4
        // --------------------------------------------------------

        send_block(-32);

        // --------------------------------------------------------
        // 中間空兩個 cycles
        // --------------------------------------------------------

        idle_cycles(2);

        // --------------------------------------------------------
        // Block 3: values 50 ~ 81
        //
        // Expected output:
        // 81, 80, 79, 78
        // --------------------------------------------------------

        send_block(50);

        // Return interface to idle
        idle_cycles(1);

        // Wait for the final output burst
        repeat (12) @(posedge clk);

        $finish;
    end

endmodule
