import pkg::*;

module integrate_tb;
    logic clk;
    logic rst_n;


    initial begin
        clk = 0;
    end

    always #5 clk = ~clk;

    logic blkIn;

    logic wbank;
    logic [1:0] wgroup;
    logic wena;

    data_t input_data [0:7];
    data_t sorted_data [0:7];

    fsm u_fsm(
        .rst_n(rst_n),
        .clk(clk),
        .blkIn(blkIn),
        .wbank(wbank),
        .wgroup(wgroup),
        .wena(wena)
    );


    sort8 u_sort8(
        .in(input_data),
        .out(sorted_data)
    );

    Regset u_reg(
        .clk(clk),
        .wbank(wbank),
        .wgroup(wgroup),
        .wena(wena),
        .wdata(sorted_data)
    );


    initial begin
        $dumpfile("integrate_tb.vcd");
        $dumpvars(0, integrate_tb);

        rst_n     = 1'b0;
        blkIn     = 1'b0;


        // reset 至少跨過幾個 posedge
        repeat (2) @(posedge clk);

        // 不在 posedge 上解除 reset
        @(negedge clk);

        rst_n <= 1'b1;
        @(posedge clk);


        // g0
        blkIn <= 1'b1;
        input_data = '{9, 3, 7, 1, 8, 2, 6, 4};
        @(posedge clk);

        // g1
        blkIn <= 1'b0;
        input_data = '{5, 2, 8, 1, 10, 4, 6, 3};
        @(posedge clk);


        // g2
        input_data = '{11, 1, 5, 7, 3, 8, 2, 6};
        @(posedge clk);

        // g3
        input_data = '{4, 12, 1, 6, 8, 2, 7, 3};


        #1000
        $finish;

    end

    initial begin
        #2000;
        $fatal(1, "timeout!!");
    end



    initial begin
        #500;

        for (int b = 0; b < 2; b++) begin
            for (int g = 0; g < 4; g++) begin

                $write("bank=%0d group=%0d : ", b, g);

                for (int i = 0; i < 8; i++) begin
                    $write("%0d ", u_reg.mem[b][g][i]);
                end

                $display("");

            end
        end
    end
endmodule
