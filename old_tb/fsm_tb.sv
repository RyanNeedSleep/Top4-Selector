/*
Checking the correctness of the FSM transition
*/
`timescale 1ns / 1ps

module fsm_tb;

    logic       rst_n;
    logic       clk;
    logic       blkIn;

    logic       wbank;
    logic [1:0] wgroup;
    logic       wena;

    integer error_count;

    // ============================================================
    // DUT
    // ============================================================

    fsm dut (
        .rst_n  (rst_n),
        .clk    (clk),
        .blkIn  (blkIn),
        .wbank  (wbank),
        .wgroup (wgroup),
        .wena   (wena)
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
        $dumpfile("fsm.vcd");
        $dumpvars(0, fsm_tb);
    end

    // ============================================================
    // Output checker
    // ============================================================

    task automatic check_outputs (
        input logic       expected_wena,
        input logic [1:0] expected_wgroup,
        input logic       expected_wbank,
        input string      description
    );
        begin
            if ((wena   !== expected_wena)   ||
                (wgroup !== expected_wgroup) ||
                (wbank  !== expected_wbank)) begin

                $error("%s: expected wena=%b wgroup=%0d wbank=%b, actual wena=%b wgroup=%0d wbank=%b",
                       description,
                       expected_wena,
                       expected_wgroup,
                       expected_wbank,
                       wena,
                       wgroup,
                       wbank);

                error_count = error_count + 1;
            end
            else begin
                $display("[PASS] time=%0t | %s | blkIn=%b wena=%b wgroup=%0d wbank=%b",
                         $time,
                         description,
                         blkIn,
                         wena,
                         wgroup,
                         wbank);
            end
        end
    endtask
    // ============================================================
    // Send multiple blocks with no idle cycle between blocks
    //
    // Example for two blocks:
    //
    // blkIn:  1 0 0 0 1 0 0 0
    // group:  G0 G1 G2 G3 G0 G1 G2 G3
    //
    // At the posedge that completes previous G3:
    // - DUT enters IDLE
    // - wbank toggles
    // - testbench sets blkIn=1 using NBA
    //
    // Therefore the following half-cycle immediately presents
    // the next block's G0, with no wena=0 cycle in between.
    // ============================================================

    task automatic send_back_to_back_blocks (
        input integer     first_block_number,
        input integer     number_of_blocks,
        input logic       first_bank
    );

        logic expected_bank;
        integer block_number;

        begin
            expected_bank = first_bank;

            for (integer b = 0; b < number_of_blocks; b++) begin
                block_number = first_block_number + b;

                // ------------------------------------------------
                // Group 0
                // ------------------------------------------------
                //
                // For b > 0, this posedge simultaneously:
                // 1. completes the previous block's group 3
                // 2. toggles wbank
                // 3. raises blkIn for the new block
                //
                // Because blkIn uses <=, the DUT still sees the old
                // blkIn value at this edge. After the edge, it is in
                // IDLE with blkIn=1, so G0 is decoded immediately.
                // ------------------------------------------------

                @(posedge clk);
                blkIn <= 1'b1;

                @(negedge clk);
                check_outputs(
                    1'b1,
                    2'd0,
                    expected_bank,
                    $sformatf(
                        "Block %0d group 0",
                        block_number
                    )
                );

                // ------------------------------------------------
                // Group 1
                // ------------------------------------------------

                @(posedge clk);
                blkIn <= 1'b0;

                @(negedge clk);
                check_outputs(
                    1'b1,
                    2'd1,
                    expected_bank,
                    $sformatf(
                        "Block %0d group 1",
                        block_number
                    )
                );

                // ------------------------------------------------
                // Group 2
                // ------------------------------------------------

                @(posedge clk);

                @(negedge clk);
                check_outputs(
                    1'b1,
                    2'd2,
                    expected_bank,
                    $sformatf(
                        "Block %0d group 2",
                        block_number
                    )
                );

                // ------------------------------------------------
                // Group 3
                // ------------------------------------------------

                @(posedge clk);

                @(negedge clk);
                check_outputs(
                    1'b1,
                    2'd3,
                    expected_bank,
                    $sformatf(
                        "Block %0d group 3",
                        block_number
                    )
                );

                // 下一個 block 使用另一個 bank
                expected_bank = ~expected_bank;
            end

            // 最後一個 block 沒有下一個相鄰 block，
            // 因此讓最後的 LOAD_G3 在此 posedge 回到 IDLE。
            @(posedge clk);
            blkIn <= 1'b0;

            @(negedge clk);
            check_outputs(
                1'b0,
                2'd0,
                expected_bank,
                $sformatf(
                    "Block %0d completed, return to IDLE",
                    first_block_number + number_of_blocks - 1
                )
            );
        end
    endtask

    // ============================================================
    // Main test sequence
    // ============================================================

    initial begin
        rst_n       = 1'b0;
        blkIn       = 1'b0;
        error_count = 0;

        $display("========================================");
        $display("FSM simulation started");
        $display("========================================");

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (2) @(posedge clk);

        @(negedge clk);
        check_outputs(
            1'b0,
            2'd0,
            1'b0,
            "During reset"
        );

        // 在 negedge 解除 reset，避開 DUT 的 active posedge。
        rst_n = 1'b1;

        @(posedge clk);

        @(negedge clk);
        check_outputs(
            1'b0,
            2'd0,
            1'b0,
            "IDLE after reset"
        );

        // --------------------------------------------------------
        // Test 1:
        // Three adjacent/back-to-back blocks
        //
        // Bank sequence:
        // Block 1 -> bank 0
        // Block 2 -> bank 1
        // Block 3 -> bank 0
        // --------------------------------------------------------

        send_back_to_back_blocks(
            1,      // first block number
            3,      // number of adjacent blocks
            1'b0    // first write bank
        );

        // 完成三個 block 後：
        // bank 0 -> bank 1 -> bank 0 -> bank 1
        // 所以現在 wbank 應為 1。

        // --------------------------------------------------------
        // Test 2:
        // Remain idle for two cycles
        // --------------------------------------------------------

        repeat (2) begin
            @(posedge clk);

            @(negedge clk);
            check_outputs(
                1'b0,
                2'd0,
                1'b1,
                "Remain in IDLE"
            );
        end

        // --------------------------------------------------------
        // Test 3:
        // Send one block after idle gap
        // --------------------------------------------------------

        send_back_to_back_blocks(
            4,      // block number
            1,      // one block
            1'b1    // current bank
        );

        // Block 4 寫完後，wbank 應切回 0。

        // --------------------------------------------------------
        // Result
        // --------------------------------------------------------

        $display("========================================");

        if (error_count == 0) begin
            $display("TEST PASSED");
        end
        else begin
            $display(
                "TEST FAILED: %0d error(s)",
                error_count
            );
        end

        $display("========================================");

        #10;
        $finish;
    end

    // ============================================================
    // Timeout protection
    // ============================================================

    initial begin
        #2000;
        $fatal(1, "Simulation timeout");
    end

endmodule
