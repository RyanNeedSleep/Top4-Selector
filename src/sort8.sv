import pkg::*;


module cas #(parameter bit DESC = 1'b1)(
    input data_t a,
    input data_t b,
    output data_t y0,
    output data_t y1
);

    always_comb begin
        if (DESC) begin
            y0 = (a >= b) ? a : b;
            y1 = (a>= b) ? b : a;
        end
        else begin
            y0 = (a <= b) ? a : b;
            y1 = (a <= b) ? b : a;
        end

    end

endmodule


module sort8 (
    input data_t in [0:7],
    output data_t out [0:7]
);
        data_t s1 [0:7];
    data_t s2 [0:7];
    data_t s3 [0:7];
    data_t s4 [0:7];
    data_t s5 [0:7];

    // Stage 1
    cas #(.DESC(1'b1)) s1_c0 (
        .a(in[0]), .b(in[1]),
        .y0(s1[0]), .y1(s1[1])
    );

    cas #(.DESC(1'b0)) s1_c1 (
        .a(in[2]), .b(in[3]),
        .y0(s1[2]), .y1(s1[3])
    );

    cas #(.DESC(1'b1)) s1_c2 (
        .a(in[4]), .b(in[5]),
        .y0(s1[4]), .y1(s1[5])
    );

    cas #(.DESC(1'b0)) s1_c3 (
        .a(in[6]), .b(in[7]),
        .y0(s1[6]), .y1(s1[7])
    );

    // Stage 2
    cas #(.DESC(1'b1)) s2_c0 (
        .a(s1[0]), .b(s1[2]),
        .y0(s2[0]), .y1(s2[2])
    );

    cas #(.DESC(1'b1)) s2_c1 (
        .a(s1[1]), .b(s1[3]),
        .y0(s2[1]), .y1(s2[3])
    );

    cas #(.DESC(1'b0)) s2_c2 (
        .a(s1[4]), .b(s1[6]),
        .y0(s2[4]), .y1(s2[6])
    );

    cas #(.DESC(1'b0)) s2_c3 (
        .a(s1[5]), .b(s1[7]),
        .y0(s2[5]), .y1(s2[7])
    );

    // Stage 3
    cas #(.DESC(1'b1)) s3_c0 (
        .a(s2[0]), .b(s2[1]),
        .y0(s3[0]), .y1(s3[1])
    );

    cas #(.DESC(1'b1)) s3_c1 (
        .a(s2[2]), .b(s2[3]),
        .y0(s3[2]), .y1(s3[3])
    );

    cas #(.DESC(1'b0)) s3_c2 (
        .a(s2[4]), .b(s2[5]),
        .y0(s3[4]), .y1(s3[5])
    );

    cas #(.DESC(1'b0)) s3_c3 (
        .a(s2[6]), .b(s2[7]),
        .y0(s3[6]), .y1(s3[7])
    );

    // Stage 4
    cas #(.DESC(1'b1)) s4_c0 (
        .a(s3[0]), .b(s3[4]),
        .y0(s4[0]), .y1(s4[4])
    );

    cas #(.DESC(1'b1)) s4_c1 (
        .a(s3[1]), .b(s3[5]),
        .y0(s4[1]), .y1(s4[5])
    );

    cas #(.DESC(1'b1)) s4_c2 (
        .a(s3[2]), .b(s3[6]),
        .y0(s4[2]), .y1(s4[6])
    );

    cas #(.DESC(1'b1)) s4_c3 (
        .a(s3[3]), .b(s3[7]),
        .y0(s4[3]), .y1(s4[7])
    );

    // Stage 5
    cas #(.DESC(1'b1)) s5_c0 (
        .a(s4[0]), .b(s4[2]),
        .y0(s5[0]), .y1(s5[2])
    );

    cas #(.DESC(1'b1)) s5_c1 (
        .a(s4[1]), .b(s4[3]),
        .y0(s5[1]), .y1(s5[3])
    );

    cas #(.DESC(1'b1)) s5_c2 (
        .a(s4[4]), .b(s4[6]),
        .y0(s5[4]), .y1(s5[6])
    );

    cas #(.DESC(1'b1)) s5_c3 (
        .a(s4[5]), .b(s4[7]),
        .y0(s5[5]), .y1(s5[7])
    );

    // Stage 6
    cas #(.DESC(1'b1)) s6_c0 (
        .a(s5[0]), .b(s5[1]),
        .y0(out[0]), .y1(out[1])
    );

    cas #(.DESC(1'b1)) s6_c1 (
        .a(s5[2]), .b(s5[3]),
        .y0(out[2]), .y1(out[3])
    );

    cas #(.DESC(1'b1)) s6_c2 (
        .a(s5[4]), .b(s5[5]),
        .y0(out[4]), .y1(out[5])
    );

    cas #(.DESC(1'b1)) s6_c3 (
        .a(s5[6]), .b(s5[7]),
        .y0(out[6]), .y1(out[7])
    );

endmodule
