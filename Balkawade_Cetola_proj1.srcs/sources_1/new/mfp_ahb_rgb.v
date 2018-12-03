
//////////////////////////////////////////////////////////////////////////////////
// Company: Portland State University
// Engineer: Sanika Balkawade
// 
// Create Date: 11/26/2018 09:23:43 AM
// Design Name: AHB-lite peripheral for RGB LEDs
// Module Name: mfp_ahb_rgb
// Project Name: Audio Effects generator
// Target Devices: 
// Tool Versions: 
// Description: 
// AHB-lite peripheral for MIPSfpga system.
// 
// Dependencies: rgbPWMGenerator.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`include "mfp_ahb_const.vh"

module mfp_ahb_rgb(
    input                        HCLK,          //Clock
    input                        HRESETn,       //REset
    input      [ 31          :0] HADDR,         
    input      [  1          :0] HTRANS,
    input      [ 31          :0] HWDATA,
    input                        HWRITE,
    input                        HSEL,
    output reg [ 31          :0] HRDATA,
    
    output     [`MFP_N_RGB_DATA - 1:0] IO_RGB_DATA   //rgb PWM data - 6 bits
    );
    
    reg  [31:0]  HADDR_d;
    reg         HWRITE_d;
    reg         HSEL_d;
    reg  [1:0]  HTRANS_d;
    wire        we;
    
    reg    [`PWM_WIDTH-1:0]    RED1_DC, RED2_DC;           // duty cycle for Red LED PWM channel
    reg    [`PWM_WIDTH-1:0]    GREEN1_DC,GREEN2_DC;        // duty cycle for Green LED PWM channel
    reg    [`PWM_WIDTH-1:0]    BLUE1_DC, BLUE2_DC;         // duty cycle for Blue LED PWM channel    
     
    
    reg    [`MFP_N_RGB_CTRL - 1:0]   RGB1_CTRL;             // PWM enable signals for RGB LED1
    reg    [`MFP_N_RGB_CTRL - 1:0]   RGB2_CTRL;             // PWM enable signals for RGB LED2        
     
    
     //Set registers besed on the bus data
     always @(posedge HCLK)
     begin
         HADDR_d  <= HADDR;
         HWRITE_d <= HWRITE;
         HSEL_d   <= HSEL;
         HTRANS_d <= HTRANS;     
         
     end
    
    // set the write enable line just like the other modules
    // HTRANS_d must not be set to "idle" (b00), select and write must be high
    assign we = (HTRANS_d != `HTRANS_IDLE) & HSEL_d & HWRITE_d;
    
    always @(posedge HCLK or negedge HRESETn) begin
        if(HRESETn == 1'b0) begin
             RGB1_CTRL   <= 3'b111;         //Enable PWM signals by default // LED1
             RGB2_CTRL   <= 3'b111;         //LED2
             BLUE1_DC    <= 'd255;          //Blue color enabled by default
             GREEN1_DC   <= 'h0;            //Green duty cycle
             RED1_DC     <= 'h0;            //Red duty cycle
             BLUE2_DC    <= 'd255;          //BLue duty cycle LED2
             GREEN2_DC   <= 'h0;            //Green duty cycle LED2
             RED2_DC     <= 'h0;            //Red duty cycle LED2
        end
        else if(we)
        begin
            case(HADDR_d)
                
                //Set rgb 1 control signals
                `H_RGB_CTRL1_ADDR:   RGB1_CTRL <= HWDATA[2:0];
                //RGB LED 2 ctrl
                `H_RGB_CTRL2_ADDR:   RGB2_CTRL <= HWDATA[2:0];
                    
                 //RGB LED1 Data   
                `H_RGB_DATA1_ADDR: begin                            
                    BLUE1_DC  <= HWDATA[7:0];
                    GREEN1_DC <= HWDATA[15:8];
                    RED1_DC   <= HWDATA[23:16];
                end
                
                //RGB LED2 Data
                `H_RGB_DATA2_ADDR:   begin                                   
                    BLUE2_DC  <= HWDATA[7:0];
                    GREEN2_DC <= HWDATA[15:8];
                    RED2_DC   <= HWDATA[23:16]; 
                end
            
            //latch
            default: begin
                         RGB1_CTRL <= RGB1_CTRL;
                         RGB2_CTRL <= RGB2_CTRL;
                         BLUE1_DC <= BLUE1_DC;
                         GREEN1_DC <= GREEN1_DC;
                         RED1_DC <= RED1_DC;
                         BLUE2_DC <= BLUE2_DC;
                         GREEN2_DC <= GREEN2_DC;
                         RED2_DC <= RED2_DC;
                         
            end
            endcase
            
        end        
    
    
    end
    
    // PWM generator for rgb LED1
    rgbPWMGenerator rgb1PWMGenerator (
        // port declarations
        .CLK(HCLK),                 //system clock
        .RESETn(HRESETn),           //system reset
        .RED(RED1_DC),                        // duty cycle for Red LED PWM channel
        .GREEN(GREEN1_DC),                    // duty cycle for Green LED PWM channel
        .BLUE(BLUE1_DC),                    // duty cycle for Blue LED PWM channel    
        .PWM_EN(RGB1_CTRL),                // PWM enables for each channel    
        .RGB_OUT(IO_RGB_DATA[2:0])                        // PWM outputs for each channel
    );
    
    //PWM generator for RGB LED2
    rgbPWMGenerator rgb2PWMGenerator (
            // port declarations
            .CLK(HCLK),                 //system clock
            .RESETn(HRESETn),           //system reset
            .RED(RED2_DC),                        // duty cycle for Red LED PWM channel
            .GREEN(GREEN2_DC),                    // duty cycle for Green LED PWM channel
            .BLUE(BLUE2_DC),                    // duty cycle for Blue LED PWM channel    
            .PWM_EN(RGB2_CTRL),                // PWM enables for each channel    
            .RGB_OUT(IO_RGB_DATA[5:3])                        // PWM outputs for each channel
        );
          
                         
     
endmodule //rgbPWMGenerator
