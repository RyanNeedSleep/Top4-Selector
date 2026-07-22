module merge_ctrl(
    input logic rst_n,
    input logic clk,

    input logic [1:0] winner,
    input logic start,

    output logic [2:0] rptr [0:3],
    output logic out_valid,
    output logic [1:0] outrank
);

    logic busy;
    logic [1:0] count;
    assign outrank = count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= '0;
            count <= 2'b0;

            for (int i = 0; i < 4; i++) begin
                rptr[i] <= 3'b0;
            end
        end
        else begin
            if (start && !busy) begin // first beat
                count <= 2'b0;
                busy <= 1'b1;

                for (int i = 0; i < 4; i++) begin
                    rptr[i] <= 3'b0;
                end

            end else if (busy) begin
                rptr[winner] <= rptr[winner] + 3'd1;
                if (count == 2'd3) begin
                    busy <= 1'b0;
                end
                else begin
                    count <= count + 2'd1;
                end
            end
        end
    end


endmodule
