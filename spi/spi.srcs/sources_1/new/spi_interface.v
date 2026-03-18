`timescale 1ns / 1ps

module spi_master(
    input clk, rst, tx_enable,
    input cpol, cpha,
    output reg mosi, 
    output reg cs,
    output sclk
    );
    
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam SEND = 2'b10;
    localparam END = 2'b11;
    
    reg state = IDLE;
    reg next_state = IDLE;
    reg [2:0]count = 0;
    reg [3:0] bit_count = 0;
    reg start_sclk = 0;
    reg [7:0] din = 8'b10101010;
    always @(*) begin
        // Default Values
        cs = 1'b1;
        sclk = 1'b0; // CPOL = 0
        mosi = 1'b0;

        case(state)
            IDLE: begin
                cs = 1'b1;
            end
            START: begin
                cs = 1'b0;
                sclk = (count > 3'b011);
            end
            SEND: begin
                cs = 1'b0;
                sclk = (count <= 3'b011); 
                if (bit_count < 8) mosi = din[7 - bit_count];
            end
            END: begin
                cs = 1'b0;
                mosi = 1'b0;
            end
        endcase
    end
    always@(posedge clk) begin
        case(state)
            IDLE:begin
                start_sclk <= 0;
            end
            default: start_sclk <= 1;
        endcase
    end
    
    // Next state decoder
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end
    always @(*) begin
        next_state = state;
        case(state)
            IDLE:  if (tx_enable) next_state = START;
            START: if (count == 3'b111) next_state = SEND;
            SEND:  if (bit_count == 8)  next_state = END;
            END:   if (count == 3'b111) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    always@(posedge clk) begin
        case(state)
            IDLE: begin
                count <= 0;
                bit_count <= 0;
            end
            START: begin
                count <= count + 1;
            end
            SEND: begin
                if(bit_count != 8) begin
                   if(count < 3'b111)
                     count <= count + 1;
                   else begin
                     count <= 0;
                     bit_count <= bit_count + 1;
                   end
                end
            end
            END: begin
                count     <= count + 1;
                bit_count <= 0;
            end
            default: begin
                count <= 0;
                bit_count <= 0;
            end
            
        endcase
    end
endmodule
