
module spi_slave(
    input sclk, mosi,cs,
    output [7:0] dout,
    output reg done 
    );
    integer count = 0;
    localparam IDLE = 0;
    localparam SAMPLE = 1;
    reg state = IDLE;

    reg [7:0] data = 0;
    always@(negedge sclk) begin
    case(state)
        IDLE: begin
            done <= 1'b0;
            if(cs == 1'b0)
                state <= SAMPLE;
            else
                state <= IDLE;
        end
        SAMPLE: begin
            if(count < 8) begin
                count <= count + 1;
                data <= {data[6:0],mosi};
                state <= SAMPLE;
            end else begin
                count <= 0;
                state <= IDLE;
                done  <= 1'b1;
            end
        end
        default : state <= IDLE;
    endcase
    end
    assign dout = data;
endmodule
