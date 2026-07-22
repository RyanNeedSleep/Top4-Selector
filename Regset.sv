import pkg::*;

module Regset(
    input logic clk,
    input logic wbank,
    input logic [1:0] wgroup,
    input logic wena,
    input data_t wdata [0:7]
);

    data_t mem [0:1][0:3][0:7];

    always_ff @(posedge clk) begin
        if (wena) begin
            for (int i = 0; i < 8; i++) begin
                mem[wbank][wgroup][i] <= wdata[i];
            end
        end

    end

endmodule
