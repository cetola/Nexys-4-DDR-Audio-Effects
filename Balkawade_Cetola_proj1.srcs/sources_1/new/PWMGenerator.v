
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2018 09:23:43 AM
// Design Name: 
// Module Name: rgbPWMGenerator
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

`timescale 1ns / 1ps
`include "mfp_ahb_const.vh"

module rgbPWMGenerator
#(
	//parameter declarations
	parameter 			PWM_WIDTH = 8,					// Number of duty cycle bits for each channel 
	parameter			PWM_N_CHANNEL = 3			    // Number of PWM channels = 3 for RGB
)
(
	// port declarations
	input 	CLK,				 						// system clock
	input	RESETn,										// system reset
	input	[PWM_WIDTH-1:0]	RED,						// duty cycle for Red LED PWM channel
	input	[PWM_WIDTH-1:0]	GREEN,						// duty cycle for Green LED PWM channel
	input	[PWM_WIDTH-1:0]	BLUE,						// duty cycle for Blue LED PWM channel	
	input 	[PWM_N_CHANNEL-1:0]	PWM_EN,	    			// PWM enables for each channel	
	output	[PWM_N_CHANNEL-1:0]	RGB_OUT				    // PWM outputs for each channel
);




//Instantiate the PWMCounter module for R,G,B signals 

PWMCounter B_PWMCounter(
	.CLK(CLK),				 						// system clock
	.RESETn(RESETn),							    // system reset
	.PWMvalue(BLUE),								//PWM value for Duty cycle
	.en(PWM_EN[0]),									// Enable signal for PWM
	.PWM_out(RGB_OUT[0])							//BLUE output PWM
);



PWMCounter G_PWMCounter(
	.CLK(CLK),				 						// system clock
	.RESETn(RESETn),							    // system reset
	.PWMvalue(GREEN),								//PWM value for Duty cycle
	.en(PWM_EN[1]),									// Enable signal for PWM
	.PWM_out(RGB_OUT[1])							//GREEN output PWM
);



PWMCounter R_PWMCounter(
	.CLK(CLK),				 						// system clock
	.RESETn(RESETn),							    // system reset
	.PWMvalue(RED),								//PWM value for Duty cycle
	.en(PWM_EN[2]),									// Enable signal for PWM
	.PWM_out(RGB_OUT[2])							//RED output PWM
);


	

endmodule


module PWMCounter
#(
	//parameter declarations
	parameter 			PWM_WIDTH = 8					// Number of duty cycle bits for each channel 
)
(
		input 	CLK,				 						// system clock
		input	RESETn,										// system reset
		input   [PWM_WIDTH-1:0] PWMvalue,					//PWM value for Duty cycle
		input   en,											// Enable signal for PWM
		output reg PWM_out										// PWM output
	);

	localparam Counter_Width = PWM_WIDTH + 1;

		reg [Counter_Width:0] pwm_counter;					// One bit more than the input PWM width to ensure 50% duty cycle

		

		//Channel counter
		// reset the counter on reset, else increment on every positive clock edge
		always @(posedge CLK) begin
			if(~RESETn) begin
				pwm_counter <= 0;
			end
			else begin
				pwm_counter <= pwm_counter + 1'b1;		//Increment the couter by 1
			end
		end	

		//Generate PWM output based on the counter value
		//Combination circuit: Compare if PWM enable is active and counter value is less than input PWMinput,
		// IF yes - set the PWM signal to HIGH, else LOW
		always @(*)
		begin
			if(en &&  (pwm_counter < PWMvalue))
				PWM_out = 1'b1;
			else
				PWM_out = 1'b0;

		end

endmodule



