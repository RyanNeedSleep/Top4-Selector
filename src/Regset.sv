import pkg::*;

module Regset (
    input logic clk,

    input logic wbank,
    input logic [1:0] wgroup,
    input logic wena,
    input data_t wdata[0:7],

    input logic rbank,
    input [2:0] rptr [0:3],

    output data_t rdata [0:3]
);
    data_t mem[0:1][0:3][0:7];

    always_ff @(posedge clk) begin
        if (wena) begin
            for (int i = 0; i < 8; i++) begin
                mem[wbank][wgroup][i] <= wdata[i];
            end
        end

    end


    always_comb begin
        for (int i = 0; i < 4; i++) begin
            rdata[i] = mem[rbank][i][rptr[i]];
        end
    end
endmodule
