import pkg::*;

module Top4(
    input logic clk,
    input logic rst_n,

    input logic blkIn,

    input data_t idata [0:7],

    output logic [1:0] outrank,
    output data_t result,
    output logic out_valid
);

    data_t sorted_data [0:7];
    logic wbank;
    logic [1:0] wgroup;
    logic wena;

    logic [2:0] rptr [0:3];
    logic rbank;
    assign rbank = ~wbank;

    logic [1:0] winner;
    data_t rdata [0:3];

    logic merge_start;
    assign merge_start = wena && (wgroup == 2'd3);

    data_t max_val;
    assign result = (out_valid) ? max_val : '0;


    sort8 u_sort8(
        .in(idata),
        .out(sorted_data)
    );

    Regset u_reg(
        .clk(clk),
        .wbank(wbank),
        .wgroup(wgroup),
        .wena(wena),
        .wdata(sorted_data),
        .rbank(rbank),
        .rptr(rptr),
        .rdata(rdata)
    );

    write_ctrl u_write_ctrl(
        .rst_n(rst_n),
        .clk(clk),
        .blkIn(blkIn),
        .wbank(wbank),
        .wgroup(wgroup),
        .wena(wena)
    );

    merge_ctrl u_merge_ctrl(
        .rst_n(rst_n),
        .clk(clk),
        .winner(winner),
        .start(merge_start),
        .rptr(rptr),
        .out_valid(out_valid),
        .outrank(outrank)
    );

    CompTree u_comp_tree(
        .idata(rdata),
        .max_val(max_val),
        .winner(winner)
    );


endmodule
