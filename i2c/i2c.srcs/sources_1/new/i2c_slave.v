`timescale 1ns / 1ps

module i2c_slave(
    input clk,            
    input rst,          
    inout sda,             
    input scl,             
    input [6:0] slave_addr, 
    output reg [7:0] data_out,
    output reg data_ready,
    output reg sda_ctrl,
    output reg done 
);


reg sda_out;

reg [3:0] state;
localparam IDLE        = 4'd0;
localparam ADDR        = 4'd1;
localparam ADDR_ACK    = 4'd2;
localparam RECEIVE     = 4'd3;
localparam DATA_ACK    = 4'd4;
localparam STOP_DETECT = 4'd5;

reg [2:0] bit_cnt;
reg [7:0] shift_reg;
reg sda_prev = 0, scl_prev = 0;
wire start_cond = (sda_prev == 1 && sda == 0 && scl == 1);
wire stop_cond  = (sda_prev == 0 && sda == 1 && scl == 1);
assign sda = 1'bz;

// Next state logic
always@(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        
        case(state)
            IDLE: begin
                if(~scl_prev && scl) begin
                    state <= ADDR;
                end
            end
            ADDR: begin
                if(~scl_prev && scl) begin
                    if(bit_cnt == 0)
                        state <= ADDR_ACK;
                    else
                        state <= ADDR;
                end
            end
            ADDR_ACK: begin
                if(~scl_prev && scl) begin
                    if(shift_reg[7:1] == slave_addr) begin
                        state <= RECEIVE;
                    end else
                        state <= IDLE;
                end
            end
            RECEIVE: begin
                if(~scl_prev && scl) begin
                    if(bit_cnt == 0)
                        state <= DATA_ACK;
                    else
                        state <= RECEIVE;
                end
            end
            DATA_ACK: begin
                if(~scl_prev && scl) begin
                    state <= STOP_DETECT;
                end
            end
            STOP_DETECT: begin
                if(stop_cond)
                    state <= IDLE;
            end
        endcase   
    end
end

// Counter
always@(posedge clk, posedge rst) begin
    if(rst) begin
        bit_cnt <= 7;
    end else begin
        scl_prev <= scl;
        sda_prev <= sda;
        if(~scl_prev && scl) begin
            case(state)
                ADDR: begin
                    if (bit_cnt != 0) begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
                RECEIVE: begin
                    if (bit_cnt != 0) begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
                default: 
                    bit_cnt <= 7;
            endcase
        end
    end
end

// Combinational logic
always@(*) begin
    case(state)
        IDLE: begin
            sda_ctrl <= 0;
            sda_prev <= 1;
            bit_cnt <= 7;
            shift_reg <= 0;
            data_out <= 0;
            data_ready <= 0;
            scl_prev <= 1;
            sda_prev <= 1;
            done <= 0;
        end
        ADDR: begin
            shift_reg[bit_cnt] <= sda;
        end
        ADDR_ACK: begin
            if(shift_reg[7:1] == slave_addr) begin
                sda_ctrl <= 1;
            end 
        end
        RECEIVE: begin
            sda_ctrl <= 0;
            shift_reg[bit_cnt] <= sda;
        end
        DATA_ACK: begin
            sda_ctrl <= 1;
            data_out <= shift_reg;
        end
        STOP_DETECT: begin
            sda_ctrl <= 0;
            done <= 1;
        end
    endcase 
end
endmodule