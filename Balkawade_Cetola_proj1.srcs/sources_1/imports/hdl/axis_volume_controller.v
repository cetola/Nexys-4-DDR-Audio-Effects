`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent
// Engineer: Arthur Brown edited by Stephano Cetola
// 
// Create Date: 03/23/2018 01:23:15 PM
// Module Name: axis_volume_controller
// Description: AXI-Stream volume controller intended for use with AXI Stream Pmod I2S2 controller.
//              Whenever a 2-word packet is received on the slave interface, it is multiplied by 
//              the value of the switches, taken to represent the range 0.0:1.0, then sent over the
//              master interface. Reception of data on the slave interface is halted while processing and
//              transfer is taking place.
//              SC:
//              Added debounce. Adding amplitude LED effect. Yes, it is a mess, but it works.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_volume_controller #(
    parameter SWITCH_WIDTH = 4, // WARNING: this module has not been tested with other values of SWITCH_WIDTH, it will likely need some changes
    parameter DATA_WIDTH = 24
) (
    input wire clk,
    input wire [SWITCH_WIDTH-1:0] sw,
    output wire [15:0] LED,
    output wire [15:0] amp,
    
    //AXIS SLAVE INTERFACE
    input  wire [DATA_WIDTH-1:0] s_axis_data,
    input  wire s_axis_valid,
    output reg  s_axis_ready = 1'b1,
    input  wire s_axis_last,
    
    // AXIS MASTER INTERFACE
    output reg [DATA_WIDTH-1:0] m_axis_data = 1'b0,
    output reg m_axis_valid = 1'b0,
    input  wire m_axis_ready,
    output reg m_axis_last = 1'b0
);
    localparam MULTIPLIER_WIDTH = 24;
    reg [MULTIPLIER_WIDTH+DATA_WIDTH-1:0] data [1:0];
    
    reg [MULTIPLIER_WIDTH:0] multiplier = 'b0; // range of 0x00:0x10 for width=4
    
    wire m_select = m_axis_last;
    wire m_new_word = (m_axis_valid == 1'b1 && m_axis_ready == 1'b1) ? 1'b1 : 1'b0;
    wire m_new_packet = (m_new_word == 1'b1 && m_axis_last == 1'b1) ? 1'b1 : 1'b0;
    
    wire s_select = s_axis_last;
    wire s_new_word = (s_axis_valid == 1'b1 && s_axis_ready == 1'b1) ? 1'b1 : 1'b0;
    wire s_new_packet = (s_new_word == 1'b1 && s_axis_last == 1'b1) ? 1'b1 : 1'b0;
    reg s_new_packet_r = 1'b0;
    
    reg[15:0] led_io = 1'b1;
    wire signed [23:0] less_data;
    
    assign LED = led_io;
    assign amp = led_io;
    assign less_data = $signed(m_axis_data);    
    
    always@(posedge clk) begin        //TODO: OMG, seriously, it's gross.
        multiplier <= {sw,{MULTIPLIER_WIDTH{1'b0}}} / {SWITCH_WIDTH{1'b1}};
        s_new_packet_r <= s_new_packet;
    end
    
    always@(posedge clk)
        if (s_new_word == 1'b1) // sign extend and register AXIS slave data
            data[s_select] <= {{MULTIPLIER_WIDTH{s_axis_data[DATA_WIDTH-1]}}, s_axis_data};
        else if (s_new_packet_r == 1'b1) begin
            data[0] <= $signed(data[0]) * multiplier; // core volume control algorithm, infers a DSP48 slice
            data[1] <= $signed(data[1]) * multiplier;
        end
        
    always@(posedge clk)
        if (s_new_packet_r == 1'b1)
            m_axis_valid <= 1'b1;
        else if (m_new_packet == 1'b1)
            m_axis_valid <= 1'b0;
            
    always@(posedge clk)
        if (m_new_packet == 1'b1)
            m_axis_last <= 1'b0;
        else if (m_new_word == 1'b1)
            m_axis_last <= 1'b1;
            
    always@(m_axis_valid, data[0], data[1], m_select)
        if (m_axis_valid == 1'b1)
            m_axis_data = data[m_select][MULTIPLIER_WIDTH+DATA_WIDTH-1:MULTIPLIER_WIDTH];
        else
            m_axis_data = m_axis_data;
            
    always@(posedge clk)
        if (less_data > 1430000)
            led_io = 16'hffff;
        else if (less_data > 1330000)
            led_io = 16'h7fff;
        else if (less_data > 1230000)
            led_io = 16'h3fff;
        else if (less_data > 1130000)
            led_io = 16'h1fff;
        else if (less_data > 1030000)
            led_io = 16'hfff;
        else if (less_data > 930000)
            led_io = 16'h7ff;
        else if (less_data > 830000)
            led_io = 16'h3ff;
        else if (less_data > 730000)
            led_io = 16'h1ff;
        else if (less_data > 630000)
            led_io = 16'hff;
        else if (less_data > 530000)
            led_io = 16'h7f;
        else if (less_data > 430000)
            led_io = 16'h3f;
        else if (less_data > 330000)
            led_io = 16'h1f;
        else if (less_data > 230000)
            led_io = 16'hf;
        else if (less_data > 130000)
            led_io = 16'h7;
        else if (less_data > 10000)
            led_io = 16'h3;
        else
            led_io = 16'b1;
            
    always@(posedge clk)
        if (s_new_packet == 1'b1)
            s_axis_ready <= 1'b0;
        else if (m_new_packet == 1'b1)
            s_axis_ready <= 1'b1;
endmodule
