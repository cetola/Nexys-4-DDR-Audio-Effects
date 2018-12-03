// mfp_nexys4_ddr.v
// January 1, 2017
//
// Instantiate the mipsfpga system and rename signals to
// match the GPIO, LEDs and switches on Digilent's (Xilinx)
// Nexys4 DDR board

// Outputs:
// 16 LEDs (IO_LED) 
// 8 7-SEG displays
// 2 RGB LEDs
// Inputs:
// 16 Slide switches (IO_Switch),
// 5 Pushbuttons (IO_PB): {BTNU, BTND, BTNL, BTNC, BTNR}
//

`include "mfp_ahb_const.vh"

module mfp_nexys4_ddr( 
                      input                   CLK100MHZ,
                        input                   CPU_RESETN,
                        input                   BTNU, BTND, BTNL, BTNC, BTNR, 
                        input  [`MFP_N_SW-1 :0] SW,
                        output [`MFP_N_LED-1:0] LED,
                        inout  [ 8          :1] JB,
                        output [ 7          :0] AN,
                        output                  CA, CB, CC, CD, CE, CF, CG, DP,
                        output [`MFP_N_RGB_DATA - 1:0]           IO_RGB_DATA,
                        
                        output wire tx_mclk,
                        output wire tx_lrck,
                        output wire tx_sclk,
                        output wire tx_data,
                        output wire rx_mclk,
                        output wire rx_lrck,
                        output wire rx_sclk,
                        input  wire rx_data,
                       
                        input                   UART_TXD_IN);

  // Press btnCpuReset to reset the processor. 
        
  wire clk_out; 
  wire [3:0] tmpvol;
  wire axis_clk;
  wire tck_in, tck;
  wire [`MFP_N_RGB_CTRL   - 1       :0]  IO_RGB_CTRL;
  
    clk_wiz_0 clk_wiz_0(
        // Clock out ports
        .clk_out1(clk_out),     // output clk_out1
        .axis_clk(axis_clk),     // output axis_clk
        // Clock in ports
        .clk_in1(CLK100MHZ));      // input clk_in1
    
  IBUF IBUF1(.O(tck_in),.I(JB[4]));
  BUFG BUFG1(.O(tck), .I(tck_in));
  
  wire [5:0] btn_db;
  wire [15:0] sw_db;
  
  wire [23:0] axis_tx_data;
  wire axis_tx_valid;
  wire axis_tx_ready;
  wire axis_tx_last;
  
  wire [23:0] axis_rx_data;
  wire axis_rx_valid;
  wire axis_rx_ready;
  wire axis_rx_last;
  
  wire [23:0] volume_data;
  wire [23:0] distort_data;
  
  debounce debounce(
                     .clk(clk_out),
                     .pbtn_in({CPU_RESETN,BTNU,BTND,BTNL,BTNC,BTNR}),
                     .switch_in(SW),
                     .pbtn_db(btn_db),
                     .swtch_db(sw_db));

  mfp_sys mfp_sys(
			        .SI_Reset_N(btn_db[5]),
                    .SI_ClkIn(clk_out),
                    .HADDR(),
                    .HRDATA(),
                    .HWDATA(),
                    .HWRITE(),
					.HSIZE(),
                    .EJ_TRST_N_probe(JB[7]),
                    .EJ_TDI(JB[2]),
                    .EJ_TDO(JB[3]),
                    .EJ_TMS(JB[1]),
                    .EJ_TCK(tck),
                    .SI_ColdReset_N(JB[8]),
                    .EJ_DINT(1'b0),
                    .IO_Switch(sw_db),
                    .IO_PB(btn_db[4:0]),
                    .IO_LED(LED),
                    .IO_7SEGEN_N(AN),
                    .IO_7SEG_N({DP,CA,CB,CC,CD,CE,CF,CG}), 
                    .IO_RGB_DATA(IO_RGB_DATA),
                
                   // .IO_RGB_CTRL(IO_RGB_CTRL), 
                    .UART_RX(UART_TXD_IN));
                    
    axis_i2s2 m_i2s2 (
                        .axis_clk(axis_clk),
                        .axis_resetn(CPU_RESETN),
                    
                        .tx_axis_s_data(axis_tx_data),
                        .tx_axis_s_valid(axis_tx_valid),
                        .tx_axis_s_ready(axis_tx_ready),
                        .tx_axis_s_last(axis_tx_last),
                    
                        .rx_axis_m_data(axis_rx_data),
                        .rx_axis_m_valid(axis_rx_valid),
                        .rx_axis_m_ready(axis_rx_ready),
                        .rx_axis_m_last(axis_rx_last),
                        
                        .tx_mclk(tx_mclk),
                        .tx_lrck(tx_lrck),
                        .tx_sclk(tx_sclk),
                        .tx_sdout(tx_data),
                        .rx_mclk(rx_mclk),
                        .rx_lrck(rx_lrck),
                        .rx_sclk(rx_sclk),
                        .rx_sdin(rx_data)
                    );
                    
                    axis_volume_controller #(
                        .SWITCH_WIDTH(4),
                        .DATA_WIDTH(24)
                    ) m_vc (
                        .clk(axis_clk),
                        .sw(sw_db),
                        
                        .s_axis_data(axis_rx_data),
                        .s_axis_valid(axis_rx_valid),
                        .s_axis_ready(axis_rx_ready),
                        .s_axis_last(axis_rx_last),
                        
                        .m_axis_data(volume_data),
                        .m_axis_valid(axis_tx_valid),
                        .m_axis_ready(axis_tx_ready),
                        .m_axis_last(axis_tx_last)
                    );
                    
                        distortion #(
                        .DATA_WIDTH(24)
                    ) m_dist (
                        .clk(clk_out),
                        .distort_sw(sw_db[15]),
                        .rx_data(volume_data),
                        .tx_data(distort_data)
                    );
                        
                    swap #(
                        .DATA_WIDTH(24)
                    ) m_swap (
                        .clk(clk_out),
                        .swap_sw(sw_db[14]),
                        .rx_data(distort_data),
                        .tx_data(axis_tx_data)
                    );
                 
          
endmodule
