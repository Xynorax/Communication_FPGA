`timescale 1ns/1ps

module i2c_master(
    input clk,
    input rst,
    input start,
    input [6:0] address,
    input rw,
    input [7:0] data_in,
    
    output reg [7:0] data_out,
    output reg busy,
    output reg scl,
    inout sda,
    output reg sda_ctrl
        
);

reg sda_out;

parameter CLK_DIV = 250;
reg [15:0]clk_cnt;
reg scl_en;
assign sda = 1'bz;

always@(posedge clk or posedge rst) begin
    if(rst) begin
        clk_cnt <= 0;
        scl <= 1;
        scl_en <= 0;
    end else if (busy) begin
        if (clk_cnt == CLK_DIV) begin
            clk_cnt <= 0;
            scl <= ~scl; // toggle SCL
            scl_en <= 1;
        end else begin
            clk_cnt <= clk_cnt + 1;
            scl_en <= 0;
        end
    end else begin
        scl <= 1;
        clk_cnt <= 0;
        scl_en <= 0;
    end
end

reg [3:0] state;
localparam IDLE       = 4'd0;
localparam START_BIT  = 4'd1;
localparam SEND_ADDR  = 4'd2;
localparam ADDR_ACK   = 4'd3;
localparam SEND_DATA  = 4'd4;
localparam DATA_ACK   = 4'd5;
localparam STOP_BIT   = 4'd6;
localparam DONE       = 4'd7;

reg [3:0] bit_cnt;
reg [7:0] shift_reg;
    
always@(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        busy <= 0;
        sda_ctrl <= 0;
        bit_cnt <= 7;
        shift_reg <= 0;
    end else begin
        case(state)
            IDLE: begin
                sda_ctrl <= 0;
                busy <= 0;
                if (start) begin
                    busy <= 1;
                    state <= START_BIT;
                end
            end
            
            START_BIT: begin
                sda_ctrl <= 1;
                busy <= 1;
                if (scl_en && scl) begin
                    shift_reg <= {address, rw}; // 7-bit address + R/W
                    bit_cnt <= 7;
                    state <= SEND_ADDR;
                end
            end
            
            SEND_ADDR: begin
                sda_ctrl <= ~shift_reg[7]; 
                if (scl_en && scl) begin
                    if (bit_cnt == 0) begin
                        state <= ADDR_ACK;
                        sda_ctrl <= 0;
                    end else
                        bit_cnt <= bit_cnt - 1;
                    shift_reg <= {shift_reg[6:0], 1'b0}; 
                end
            end
            
            ADDR_ACK: begin
                if (scl_en && scl) begin
                    shift_reg <= data_in;
                    bit_cnt <= 7;
                    if(sda) begin
                        state <= IDLE;
                    end else begin
                        state <= SEND_DATA;
                    end
                end
            end
            SEND_DATA: begin
                sda_ctrl <= ~shift_reg[7]; 
                if (scl_en && scl) begin
                    shift_reg <= {shift_reg[6:0], 1'b0}; 
                    if (bit_cnt == 0)
                        state <= DATA_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                end
            end
            DATA_ACK: begin
                sda_ctrl <= 0;
                if (scl_en && scl) begin
                    state <= STOP_BIT;
                end
            end
            STOP_BIT: begin
                
                if (scl_en && scl) begin
                    sda_ctrl <= 0; 
                    state <= DONE;
                end else
                    sda_ctrl <= 1; 
            end
            DONE: begin
                busy <= 0;
                state <= IDLE;
            end
            default: state <= IDLE;
        endcase
    end
end
    
endmodule