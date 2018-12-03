// 
// mfp_ahb_const.vh
//
// Verilog include file with AHB definitions
// 

//---------------------------------------------------
// Physical bit-width of memory-mapped I/O interfaces
//---------------------------------------------------
`define MFP_N_LED             16
`define MFP_N_SW              16
`define MFP_N_PB              5
`define MFP_N_RGB_DATA        6
`define MFP_N_RGB_CTRL        6  
`define RGB_DATA_BITS         32
`define RGB_CTRL_BITS         3
`define PWM_WIDTH          8


//---------------------------------------------------
// Memory-mapped I/O addresses
//---------------------------------------------------
`define H_LED_ADDR    			(32'h1f800000)
`define H_SW_ADDR   			(32'h1f800004)
`define H_PB_ADDR   			(32'h1f800008)

`define H_LED_IONUM   			(4'h0)
`define H_SW_IONUM  			(4'h1)
`define H_PB_IONUM  			(4'h2)

//---------------------------------------------------
// Memory-mapped 7 SEG Addr
//---------------------------------------------------
`define H_7SEG_ADDR_MATCH        (7'h7d)

`define H_7SEG_EN_ADDR           (32'h1f700000)
`define H_7SEG_DIGL_ADDR         (32'h1f700008)
`define H_7SEG_DIGH_ADDR         (32'h1f700004)
`define H_7SEG_DP_ADDR           (32'h1f70000C)

//--------------------------------------------------------
// Memory-Mapped RGB LED Addr
//-----------------------------------------------------
`define H_RGB_DATA1_ADDR         (32'h1f900000)
`define H_RGB_CTRL1_ADDR         (32'h1f900004)
`define H_RGB_DATA2_ADDR         (32'h1f900008)
`define H_RGB_CTRL2_ADDR         (32'h1f90000C)


`define H_RGB_ADDR_Match         (7'h7c)

//---------------------------------------------------
// RAM addresses
//---------------------------------------------------
`define H_RAM_RESET_ADDR 		(32'h1fc?????)
`define H_RAM_ADDR	 		    (32'h0???????)
`define H_RAM_RESET_ADDR_WIDTH  (8) 
`define H_RAM_ADDR_WIDTH		(16) 

`define H_RAM_RESET_ADDR_Match  (7'h7f)
`define H_RAM_ADDR_Match 		(1'b0)
`define H_LED_ADDR_Match		(7'h7e)

//---------------------------------------------------
// AHB-Lite values used by MIPSfpga core
//---------------------------------------------------

`define HTRANS_IDLE    2'b00
`define HTRANS_NONSEQ  2'b10
`define HTRANS_SEQ     2'b11

`define HBURST_SINGLE  3'b000
`define HBURST_WRAP4   3'b010

`define HSIZE_1        4'b0000
`define HSIZE_2        4'b0001
`define HSIZE_4        4'b0010
`define HSIZE_8        4'b1000
