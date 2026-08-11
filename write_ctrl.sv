/*
Controlling the input/write stage of the Regset
*/
module write_ctrl(
    input rst_n,
    input logic clk,
    input logic blkIn,

    output logic wbank,
    output logic [1:0] wgroup,
    output logic wena
);
    typedef enum logic [1:0] {
        IDLE,
        LOAD1,
        LOAD2,
        LOAD3
    } state_t;

    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            wbank <= 1'b0;
        end
        else begin
                unique case (state)
                    IDLE: begin
                        if (blkIn)
                            state <= LOAD1;
                        else
                            state <= IDLE;
                        end
                    LOAD1:
                        state <= LOAD2;
                    LOAD2:
                        state <= LOAD3;
                    LOAD3: begin
                        state <= IDLE;
                        wbank <= ~wbank;
                    end
                    default: begin
                        state <= IDLE;
                    end
                endcase
        end
    end

    always_comb begin
        wena = 1'b0;
        wgroup = 2'b0;

        unique case (state)
            IDLE: begin
                wgroup = 2'd0;
                wena = rst_n && blkIn;
            end

            LOAD1: begin
                wgroup = 2'd1;
                wena = 1;
            end

            LOAD2: begin
                wgroup = 2'd2;
                wena = 1;
            end

            LOAD3: begin
                wgroup = 2'd3;
                wena = 1;
            end

            default: begin
                wena = 1'b0;
                wgroup = 2'd0;
            end
        endcase
    end
endmodule
