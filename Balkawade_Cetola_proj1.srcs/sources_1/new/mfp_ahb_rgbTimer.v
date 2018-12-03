`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2018 12:24:05 PM
// Design Name: 
// Module Name: mfp_ahb_rgbTimer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mfp_ahb_rgbTimer(
                     input            clk,
                     input            resetn,
                     input     [`RGB_DATA_BITS - 1:0] RGB1_digits,
                     input     [`RGB_DATA_BITS - 1:0] RGB2_digits,
                     input     [`RGB_CTRL_BITS - 1:0] RGB1_CTRL,
                     input     [`RGB_CTRL_BITS - 1:0] RGB2_CTRL,
                     output    [ 5:0] LEDENOUT,
                     output    [ 7:0] LEDOUT);

  wire [15:0] cnt16;
  wire [ 2:0] cntSel;
  wire [ 7:0] enb1, eng1, enr1, enb2, eng2, enr2;
  wire [ 7:0] colorOut;

  assign enb1 = (RGB1_CTRL | 3'b001);        //blue 1
  assign eng1 = (RGB1_CTRL | 3'b010);        //green 1
  assign enr1 = (RGB1_CTRL | 3'b100);        //red 1
  assign enb2 = (RGB2_CTRL | 3'b001);        //blue 2
  assign eng2 = (RGB2_CTRL | 3'b010);        //green 2
  assign enr2 = (RGB2_CTRL | 3'b100);        //red 2




  counter_rgb #(16) counter16RGB(clk, resetn, cnt16);
  counter_rgb #(3)  counterSelect(cnt16[15], resetn, cntSel);

  mux8_rgb    #(3) 	mux8_rgbCtrl(enb1, eng1, enr1, enb2, eng2, enr2,
                            cntSel, LEDENOUT);
                            
  mux8_rgb    #(8) 	mux8_rgbDigits(
                               RGB1_digits[7:0],
                               RGB1_digits[15:8],
                               RGB1_digits[23:16],
                               RGB2_digits[7:0],
                               RGB2_digits[15:8],
                               RGB2_digits[23:16],
                               cntSel, LEDOUT);

endmodule


// parameterized counter
module counter_rgb
#(parameter WIDTH=8)
(     input                    clk,
      input                    resetn,
      output reg [(WIDTH-1):0] cnt);

  always @(posedge clk, negedge resetn)
    if (~resetn) cnt <= 0;
    else         cnt <= cnt + 1;

endmodule


// 8-bit multiplexer
module mux8_rgb #(parameter WIDTH = 8)
             (input  [WIDTH-1:0]     d0, d1, d2, d3, d4, d5,
              input  [2:0]           s, 
              output reg [WIDTH-1:0] y);

  always @(*)
    case (s)
      3'b000:    y = d0;
      3'b001:    y = d1;
      3'b010:    y = d2;
      3'b011:    y = d3;
      3'b100:    y = d4;
      3'b101:    y = d5;
  
      default:   y = d0;
    endcase

endmodule


