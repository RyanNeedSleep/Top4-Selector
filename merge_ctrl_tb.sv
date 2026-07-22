`timescale 1ns / 1ps

module merge_ctrl_tb;

    logic       rst_n;
    logic       clk;
    logic [1:0] winner;
    logic       start;

    logic [2:0] rptr [0:3];

    integer error_count;

    // ============================================================
    // DUT
    // ============================================================

    merge_ctrl dut (
        .rst_n  (rst_n),
        .clk    (clk),
        .winner (winner),
        .start  (start),
        .rptr   (rptr)
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
        $dumpfile("merge_ctrl.vcd");
        $dumpvars(0, merge_ctrl_tb);
    end

    // ============================================================
    // Checker
    // ============================================================

    task automatic check_state (
        input logic [2:0] expected_rptr0,
        input logic [2:0] expected_rptr1,
        input logic [2:0] expected_rptr2,
        input logic [2:0] expected_rptr3,
        input logic       expected_busy,
        input logic [1:0] expected_count,
        input string      description
    );
        begin
            if ((rptr[0]   !== expected_rptr0) ||
                (rptr[1]   !== expected_rptr1) ||
                (rptr[2]   !== expected_rptr2) ||
                (rptr[3]   !== expected_rptr3) ||
                (dut.busy  !== expected_busy)  ||
                (dut.count !== expected_count)) begin

                $error("%s | expected rptr={%0d,%0d,%0d,%0d} busy=%b count=%0d, actual rptr={%0d,%0d,%0d,%0d} busy=%b count=%0d",
                       description,
                       expected_rptr0,
                       expected_rptr1,
                       expected_rptr2,
                       expected_rptr3,
                       expected_busy,
                       expected_count,
                       rptr[0],
                       rptr[1],
                       rptr[2],
                       rptr[3],
                       dut.busy,
                       dut.count);

                error_count = error_count + 1;
            end
            else begin
                $display("[PASS] time=%0t | %s | rptr={%0d,%0d,%0d,%0d} busy=%b count=%0d",
                         $time,
                         description,
                         rptr[0],
                         rptr[1],
                         rptr[2],
                         rptr[3],
                         dut.busy,
                         dut.count);
            end
        end
    endtask

    // ============================================================
    // Start a new merge
    //
    // start 在 negedge 拉高，下一個 posedge 被 DUT 取樣。
    // 該 posedge 只負責：
    //   busy <= 1
    //   count <= 0
    //   rptr  <= 0
    //
    // 不會在 start 那個 posedge 更新 winner pointer。
    // ============================================================

    task automatic begin_merge (
        input string description
    );
        begin
            @(negedge clk);
            start = 1'b1;

            @(posedge clk);
            #1;

            check_state(
                3'd0,
                3'd0,
                3'd0,
                3'd0,
                1'b1,
                2'd0,
                description
            );
        end
    endtask

    // ============================================================
    // Consume one winner
    //
    // 在 negedge：
    //   1. 將 start 拉低
    //   2. 設定 winner
    //
    // 下一個 posedge，DUT 才會執行：
    //
    //   rptr[winner] <= rptr[winner] + 1;
    // ============================================================

    task automatic consume_winner (
        input logic [1:0] selected_winner
    );
        begin
            @(negedge clk);
            start  = 1'b0;
            winner = selected_winner;

            @(posedge clk);
            #1;
        end
    endtask

    // ============================================================
    // Main test
    // ============================================================

    initial begin
        rst_n       = 1'b0;
        start       = 1'b0;
        winner      = 2'd0;
        error_count = 0;

        $display("========================================");
        $display("merge_ctrl simulation started");
        $display("========================================");

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (2) @(posedge clk);
        #1;

        check_state(
            3'd0,
            3'd0,
            3'd0,
            3'd0,
            1'b0,
            2'd0,
            "During reset"
        );

        // 在 negedge 解除 reset，避免與 DUT posedge 發生 race
        @(negedge clk);
        rst_n = 1'b1;

        @(posedge clk);
        #1;

        check_state(
            3'd0,
            3'd0,
            3'd0,
            3'd0,
            1'b0,
            2'd0,
            "Idle after reset"
        );

        // ========================================================
        // First merge
        //
        // winner sequence:
        //
        //     2, 0, 2, 1
        //
        // final:
        //
        //     rptr[0] = 1
        //     rptr[1] = 1
        //     rptr[2] = 2
        //     rptr[3] = 0
        // ========================================================

        begin_merge("Start first merge");

        // Update 1: winner = 2
        consume_winner(2'd2);

        check_state(
            3'd0,
            3'd0,
            3'd1,
            3'd0,
            1'b1,
            2'd1,
            "First merge update 1, winner=2"
        );

        // Update 2: winner = 0
        consume_winner(2'd0);

        check_state(
            3'd1,
            3'd0,
            3'd1,
            3'd0,
            1'b1,
            2'd2,
            "First merge update 2, winner=0"
        );

        // Update 3: winner = 2
        consume_winner(2'd2);

        check_state(
            3'd1,
            3'd0,
            3'd2,
            3'd0,
            1'b1,
            2'd3,
            "First merge update 3, winner=2"
        );

        // Update 4: winner = 1
        consume_winner(2'd1);

        check_state(
            3'd1,
            3'd1,
            3'd2,
            3'd0,
            1'b0,
            2'd3,
            "First merge update 4, merge completed"
        );

        // --------------------------------------------------------
        // Verify pointer does not update while idle
        // --------------------------------------------------------

        consume_winner(2'd3);

        check_state(
            3'd1,
            3'd1,
            3'd2,
            3'd0,
            1'b0,
            2'd3,
            "No pointer update while idle"
        );

        // ========================================================
        // Second merge
        //
        // start 應該把所有 pointer 清回 0。
        //
        // winner sequence:
        //
        //     3, 3, 3, 3
        //
        // final:
        //
        //     rptr = {0,0,0,4}
        // ========================================================

        begin_merge("Start second merge and clear pointers");

        // Update 1
        consume_winner(2'd3);

        check_state(
            3'd0,
            3'd0,
            3'd0,
            3'd1,
            1'b1,
            2'd1,
            "Second merge update 1, winner=3"
        );

        // Update 2
        consume_winner(2'd3);

        check_state(
            3'd0,
            3'd0,
            3'd0,
            3'd2,
            1'b1,
            2'd2,
            "Second merge update 2, winner=3"
        );

        // Update 3
        consume_winner(2'd3);

        check_state(
            3'd0,
            3'd0,
            3'd0,
            3'd3,
            1'b1,
            2'd3,
            "Second merge update 3, winner=3"
        );

        // Update 4
        consume_winner(2'd3);

        check_state(
            3'd0,
            3'd0,
            3'd0,
            3'd4,
            1'b0,
            2'd3,
            "Second merge update 4, merge completed"
        );

        // ========================================================
        // Final result
        // ========================================================

        $display("========================================");

        if (error_count == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d error(s)", error_count);

        $display("========================================");

        #10;
        $finish;
    end

    // ============================================================
    // Timeout protection
    // ============================================================

    initial begin
        #1000;
        $fatal(1, "Simulation timeout");
    end

endmodule
