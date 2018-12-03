`timescale 1ns / 1ps

module mfp_ahb_7seg(
    input                        HCLK,
    input                        HRESETn,
    input      [ 31          :0] HADDR,
    input      [  1          :0] HTRANS,
    input      [ 31          :0] HWDATA,
    input                        HWRITE,
    input                        HSEL,
    output reg [ 31          :0] HRDATA,

    // 7 segment write-only data
    output [7:0] IO_7SEGEN_N,
    output [7:0] IO_7SEG_N
    );
        
    reg  [31:0]  HADDR_d;
    reg         HWRITE_d;
    reg         HSEL_d;
    reg  [1:0]  HTRANS_d;
    wire        we;

    reg [7:0] en;
    reg [63:0] digits;
    reg [7:0] dp;
    
    // set the registers based on the bus data
    always @ (posedge HCLK) 
    begin
      HADDR_d  <= HADDR;
      HWRITE_d <= HWRITE;
      HSEL_d   <= HSEL;
      HTRANS_d <= HTRANS;
    end

    // set the write enable line just like the other modules
    // HTRANS_d must not be set to "idle" (b00), select and write must be high
    assign we = (HTRANS_d != `HTRANS_IDLE) & HSEL_d & HWRITE_d;
    
    // setup a synchronous reset
    always @(posedge HCLK or negedge HRESETn)
       
       if (~HRESETn) begin
         en <= 0;
         digits <= 0;
         dp <= 0; 
       end else if (we)
         case (HADDR_d)
         
           // set the enable lines
           `H_7SEG_EN_ADDR: en <= HWDATA[7:0];
           
           // set the upper and lower digit segements
           `H_7SEG_DIGL_ADDR: digits[31:0] <= HWDATA;
           `H_7SEG_DIGH_ADDR: digits[63:32] <= HWDATA;
           
           // set the decimal points
           `H_7SEG_DP_ADDR: dp <= HWDATA[7:0];
           
           // latch
           default: begin
            en <= en;
            digits <= digits;
            dp <= dp;
           end
         endcase

// hook up the timer
mfp_ahb_sevensegtimer sevensegtimer(.clk(HCLK),     
       .resetn(HRESETn),  
       .EN(en),      
       .DIGITS(digits),  
       .dp(dp),      
       .DISPENOUT(IO_7SEGEN_N),
       .DISPOUT(IO_7SEG_N));

endmodule
