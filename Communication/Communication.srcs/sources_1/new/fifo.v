module fifo#(parameter DATA_WIDTH = 8, parameter DEPTH = 16)(
    input clk, rst, en, push_in, pop_in,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output reg overrun, underrun,
    output empty, full,
    input [3:0] threshold,
    output reg thre_trigger 
);
    
    localparam ADDR_WIDTH = $clog2(DEPTH);
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    wire push,pop;
    reg [ADDR_WIDTH:0] wptr, rptr; 
    assign empty = (wptr == rptr);
    assign full = (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]) && (wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0]);
    // Write and read logic
    always@(posedge clk, posedge rst) begin
        if (rst) begin
            wptr <= 0;
            rptr <= 0;
        end else begin
            if (push_in && !full) begin
                mem[wptr[ADDR_WIDTH-1:0]] <= din;
                wptr <= wptr + 1;
            end
            if (pop_in && !empty) begin
                dout <= mem[rptr[ADDR_WIDTH-1:0]];
                rptr <= rptr + 1;
            end
        end
        
    end
    
    // Underrun and Overrun and threshold logic
    reg underrun_t;
    reg overrun_t;
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            underrun_t <= 0;
            overrun_t <= 0;
            thre_trigger <= 0;
        end else begin
            overrun <= full && push_in;
            underrun <= empty && pop_in;
            thre_trigger <= ((wptr-rptr) >= threshold ) ? 1'b1 : 1'b0;
        end
    end
    
endmodule