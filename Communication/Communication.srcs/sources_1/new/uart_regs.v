`include "uart_defs.vh"
module uart_regs(
    input clk, rst,
    input wr_i,rd_i,
    input rx_fifo_empty_i,
    input rx_oe, rx_pe, rx_fe, rx_bi, 
    input [2:0] addr_i,
    input [7:0] din,
    
    output tx_push_o, 
    output rx_pop_o, 
    
    output baud_out,
    
    output tx_rst, rx_rst,
    output [3:0] rx_fifo_threshold,
    
    output reg [7:0] dout_o,
    
    output [31:0] csr_o,
    input [7:0] rx_fifo_in
);

    reg [7:0] fcr_reg;
    reg [7:0] lcr_reg;
    reg [7:0] scr_reg;
    reg [7:0] dlsb, dmsb;

    wire tx_fifo_wr;
 
    assign tx_fifo_wr = wr_i & (addr_i == 3'b000) & (lcr_reg[`LCR_DLAB] == 1'b0);
    assign tx_push_o = tx_fifo_wr;  /// go to tx fifo
    
    wire rx_fifo_rd;
    
    assign rx_fifo_rd = rd_i & (addr_i == 3'b000) & (lcr_reg[`LCR_DLAB] == 1'b0);
    assign rx_pop_o = rx_fifo_rd; ///read data from rx fifo --> go to rx fifo
    
    reg [7:0] rx_data;
    
    always@(posedge clk)
    begin
    if(rx_pop_o)
      begin
      rx_data <= rx_fifo_in;
      end
    end

    // Baud values set and generation

    reg [15:0] baud_cnt;
    reg update_baud;

    always@(posedge clk) begin
      update_baud <=  wr_i & (lcr_reg[`LCR_DLAB] == 1'b1) & ((addr_i == 3'b000) | (addr_i == 3'b001));
      if (wr_i && addr_i == 3'b000 && lcr_reg[`LCR_DLAB])
        dlsb <= din;
      if (wr_i && addr_i == 3'b001 && lcr_reg[`LCR_DLAB])
        dmsb <= din;
    end

    always@(posedge clk) begin
      if(rst)
        baud_cnt <= 16'h0;
      else if (update_baud || baud_cnt == 16'h0000)
        baud_cnt <= {dmsb, dlsb};
      else
        baud_cnt <= baud_cnt - 1;
    end
    assign baud_out = |{dmsb, dlsb} & ~|baud_cnt;


    // FIFO values set and threshold output

    always@(posedge clk or posedge rst) begin
      if(rst)
        fcr_reg <= 8'h00;
      else begin
        if(wr_i && addr_i == 3'h2) begin
          fcr_reg[`FCR_ENA] <= din [0];
          fcr_reg[`FCR_RX_RST] <= din [1];
          fcr_reg[`FCR_TX_RST] <= din [2];
          fcr_reg[`FCR_DMA_MODE] <= din [3];
          fcr_reg[`FCR_RX_TRIG] <= din [7:6];
        end
        else begin
          fcr_reg[`FCR_RX_RST] <= 0;
          fcr_reg[`FCR_TX_RST] <= 0;
        end
      end
    end
    assign tx_rst = fcr_reg[`FCR_TX_RST];
    assign rx_rst = fcr_reg[`FCR_RX_RST];

    reg [3:0] fifo_threshold_t = 0;
    always@(*) begin
      if(fcr_reg[`FCR_ENA] == 0)
        fifo_threshold_t = 4'd0;
      else begin
        case(fcr_reg[`FCR_RX_TRIG])
          2'b00: fifo_threshold_t = 4'd1;
          2'b01: fifo_threshold_t = 4'd4;
          2'b10: fifo_threshold_t = 4'd8;
          2'b11: fifo_threshold_t = 4'd14;
        endcase
      end
    end
    assign rx_fifo_threshold = fifo_threshold_t;

    // LCR register values set and read
    always @(posedge clk, posedge rst) begin
      if(rst) begin
        lcr_reg <= 8'h00;
      end 
      else if (wr_i == 1'b1 && addr_i == 3'h3) begin
        lcr_reg <= din;
      end
    end
    wire read_lcr;
    reg [7:0]lcr_reg_t;
    assign read_lcr = ((rd_i == 1) && (addr_i == 3'h3));
    always@(posedge clk) begin
      if(read_lcr)
        lcr_reg_t <= lcr_reg;
    end

    //LSR register
    reg [7:0]lsr_reg;
    reg [7:0]lsr_reg_t;
    wire read_lsr;
    always@(posedge clk, posedge rst) begin
      if(rst)
        lsr_reg <= 0;
      else begin
        lsr_reg[`LSR_DR] <= ~rx_fifo_empty_i;
        lsr_reg[`LSR_OE] <= rx_oe;
        lsr_reg[`LSR_PE] <= rx_pe;
        lsr_reg[`LSR_FE] <= rx_fe;
        lsr_reg[`LSR_BI] <= rx_bi;
      end
    end
    assign read_lsr = (rd_i == 1) & (addr_i == 3'h5); 
    always@(posedge clk) begin
      if(read_lsr)
        lsr_reg_t <= lsr_reg;
    end

    // Scratch pad register 
    always@(posedge clk or posedge rst) begin
      if(rst)
        scr_reg <= 0;
      else if (wr_i && addr_i == 3'h7) begin
        scr_reg <= din;
      end
    end
      reg [7:0] scr_t; 
      wire read_scr;
      assign read_scr = (rd_i == 1) & (addr_i == 3'h7); 
 
      always@(posedge clk)
      begin
      if(read_scr)
      begin
        scr_t <= scr_reg; 
      end
      end


    always@(posedge clk)
    begin
      case(addr_i)
        0: dout_o <= lcr_reg[`LCR_DLAB] ? dlsb : rx_data;
        1: dout_o <= lcr_reg[`LCR_DLAB] ? dmsb : 8'h00; /// csr.ier
        2: dout_o <= 8'h00; /// iir
        3: dout_o <= lcr_reg_t; /// lcr
        4: dout_o <= 8'h00; //mcr;
        5: dout_o <= lsr_reg_t; ///lsr
        6: dout_o <= 8'h00; // msr
        7: dout_o <= scr_t; // scr
        default: ;
      endcase
    end
 
    assign csr_o = {fcr_reg, lcr_reg_t,lsr_reg_t, scr_t};
endmodule