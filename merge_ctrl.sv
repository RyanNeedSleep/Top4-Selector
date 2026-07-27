module merge_ctrl(
    input logic rst_n,
    input logic clk,

    input logic [1:0] winner,
    input logic start,

    output logic [2:0] rptr [0:3],
    output logic out_valid,
    output logic [1:0] outrank
);

    typedef enum logic [2:0]{
        IDLE,
        OUT0,
        OUT1,
        OUT2,
        OUT3
    } state_t;

    state_t state;
    state_t next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            for (int i = 0; i < 4; i++) begin
                rptr[i] <= 3'b0;
            end
        end else begin
            state <= next_state;
            case(state)
                IDLE: begin
                    if (start) begin
                        for (int i = 0; i < 4; i++) begin
                            rptr[i] <= 3'b0;
                        end
                    end
                end
                OUT0,
                OUT1,
                OUT2: begin
                    rptr[winner] <= rptr[winner] + 3'd1;
                end

                OUT3: begin
                    if (start) begin
                        for (int i = 0; i < 4; i++) begin
                            rptr[i] <= 3'b0;
                        end
                    end
                end
            endcase
        end

    end

    always_comb begin
        next_state = state;

        case(state)
            IDLE: begin
                if (start) begin
                    next_state = OUT0;
                end
            end
            OUT0: next_state = OUT1;
            OUT1: next_state = OUT2;
            OUT2: next_state = OUT3;
            OUT3: begin
                if (start) begin
                    next_state = OUT0;
                end
                else begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    always_comb begin
        case (state)
            OUT0: begin
                outrank = 2'd0;
                out_valid = 1'b1;
            end

            OUT1: begin
                outrank = 2'd1;
                out_valid = 1'b1;
            end

            OUT2: begin
                outrank = 2'd2;
                out_valid = 1'b1;
            end

            OUT3: begin
                outrank = 2'd3;
                out_valid = 1'b1;
            end

            default: begin
                outrank = 2'd0;
                out_valid = 1'b0;
            end
        endcase
    end
endmodule


// module merge_ctrl(
//     input logic rst_n,
//     input logic clk,

//     input logic [1:0] winner,
//     input logic start,

//     output logic [2:0] rptr [0:3],
//     output logic out_valid,
//     output logic [1:0] outrank
// );

//     logic busy;
//     logic [1:0] count;
//     assign outrank = count;
//     assign out_valid = busy;

//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             busy <= '0;
//             count <= 2'b0;

//             for (int i = 0; i < 4; i++) begin
//                 rptr[i] <= 3'b0;
//             end
//         end
//         else begin
//             if (start && busy && (count == 2'd3)) begin
//                 count <= 2'b0;
//                 busy <= 1'b1;
//                 for (int i = 0; i < 4; i++) begin
//                     rptr[i] <= 3'b0;
//                 end
//             end
//             else if (start && !busy) begin // first beat
//                 count <= 2'b0;
//                 busy <= 1'b1;

//                 for (int i = 0; i < 4; i++) begin
//                     rptr[i] <= 3'b0;
//                 end

//             end else if (busy) begin
//                 rptr[winner] <= rptr[winner] + 3'd1;
//                 if (count == 2'd3) begin
//                     busy <= 1'b0;
//                 end
//                 else begin
//                     count <= count + 2'd1;
//                 end
//             end
//         end
//     end


// endmodule
