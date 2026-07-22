module CompTree(
    input data_t idata [0:3],
    output data_t max_val,
    output logic [1:0] winner
);
    data_t a, b;
    logic [1:0] i, j;

    always_comb begin
        a = (idata[0] > idata[1]) ? idata[0] : idata[1];
        i = (idata[0] > idata[1]) ? 2'd0 : 2'd1;

        b = (idata[2] > idata[3]) ? idata[2] : idata[3];
        j = (idata[2] > idata[3]) ? 2'd2 : 2'd3;

        max_val = (a > b) ? a : b;
        winner = (a > b) ? i : j;
    end
endmodule
