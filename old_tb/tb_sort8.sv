`timescale 1ns/1ps

module tb_sort8;

    typedef logic signed [8:0] data_t;

    data_t in  [0:7];
    data_t out [0:7];

    data_t expected [0:7];

    int test_count;
    int error_count;

    sort8 dut (
        .in  (in),
        .out (out)
    );

    // Reference descending sort using bubble sort.
    task automatic reference_sort;
        data_t temp;

        // Copy DUT inputs into the reference array.
        for (int i = 0; i < 8; i++) begin
            expected[i] = in[i];
        end

        // Sort from maximum to minimum.
        for (int i = 0; i < 7; i++) begin
            for (int j = 0; j < 7 - i; j++) begin
                if (expected[j] < expected[j+1]) begin
                    temp          = expected[j];
                    expected[j]   = expected[j+1];
                    expected[j+1] = temp;
                end
            end
        end
    endtask

    task automatic check_result;
        bit failed;

        failed = 1'b0;
        reference_sort();

        // Allow combinational logic to settle.
        #1;

        for (int i = 0; i < 8; i++) begin
            if (out[i] !== expected[i]) begin
                failed = 1'b1;
            end
        end

        if (failed) begin
            error_count++;

            $display("FAIL: test %0d", test_count);

            $write("  input    = ");
            for (int i = 0; i < 8; i++) begin
                $write("%0d ", $signed(in[i]));
            end
            $display("");

            $write("  expected = ");
            for (int i = 0; i < 8; i++) begin
                $write("%0d ", $signed(expected[i]));
            end
            $display("");

            $write("  actual   = ");
            for (int i = 0; i < 8; i++) begin
                $write("%0d ", $signed(out[i]));
            end
            $display("");
        end
    endtask

    task automatic apply_test(
        input data_t v0,
        input data_t v1,
        input data_t v2,
        input data_t v3,
        input data_t v4,
        input data_t v5,
        input data_t v6,
        input data_t v7
    );
        in[0] = v0;
        in[1] = v1;
        in[2] = v2;
        in[3] = v3;
        in[4] = v4;
        in[5] = v5;
        in[6] = v6;
        in[7] = v7;

        test_count++;
        check_result();
    endtask

    initial begin
        test_count  = 0;
        error_count = 0;

        $dumpfile("sort8.vcd");
        $dumpvars(0, tb_sort8);

        // General unsorted input.
        apply_test(3, -5, 7, 2, 0, 9, -1, 4);

        // Already descending.
        apply_test(8, 7, 6, 5, 4, 3, 2, 1);

        // Ascending input.
        apply_test(1, 2, 3, 4, 5, 6, 7, 8);

        // Boundary values.
        apply_test(-256, 255, 0, -1, 1, 127, -128, 254);

        // Duplicate values.
        apply_test(5, 5, -3, 9, 9, -3, 0, 5);

        // All equal.
        apply_test(-20, -20, -20, -20, -20, -20, -20, -20);

        // Random tests.
        for (int t = 0; t < 1000; t++) begin
            for (int i = 0; i < 8; i++) begin
                // Produces values from -256 through 255.
                in[i] = data_t'($urandom_range(0, 511) - 256);
            end

            test_count++;
            check_result();
        end

        if (error_count == 0) begin
            $display("PASS: all %0d tests passed.", test_count);
        end
        else begin
            $display(
                "FAIL: %0d of %0d tests failed.",
                error_count,
                test_count
            );
        end

        $finish;
    end

endmodule
