`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Traana Technologies
// Engineer: G Lalitha Yadav
// 
// Create Date: 26.06.2024 11:57:07
// Design Name: 
// Module Name: magnituder
// Project Name: Drone Kill System
// Target Devices: 
// Tool Versions: Vivado 2017.4
// Description: calculates sqrt(sqr(real)+sqr(imaginary)).
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Considered fixed point 2's complement input with integer 2 bits and fraction 14 bits.
// 
//////////////////////////////////////////////////////////////////////////////////


module magnituder
#(
    parameter   	DATABUS_WIDTH       = 16,                      // RAM Data Width
    parameter       TIM_GEN_PCOUNT      = 11,                      // Pulse Count Width
    parameter       TIM_GEN_RCOUNT      = 9                        // Maximum Range Count Width
)
(
    clk,
    rst,
    dfft_out,
    dfft_valid,
    PulseCountMax,
    RangeCountMax,
    mag_out,
    mag_valid,
    mag_cpi
);

/*******************************************************************************************/
// Input parameters

//    parameter   	  DATABUS_WIDTH       = 16;                      // RAM Data Width
//    parameter       TIM_GEN_PCOUNT      = 11;                     // Pulse Count Width
//    parameter       TIM_GEN_RCOUNT      = 9;                      // Maximum Range Count Width

/*******************************************************************************************/
// Input parameters

    input clk;
    input rst;
    input [2*DATABUS_WIDTH - 1 : 0]     dfft_out;           // Doppler FFT Output    
    input                               dfft_valid;         // Doppler FFT Valid
    input [TIM_GEN_PCOUNT - 1 : 0]      PulseCountMax ;     // 11 bit input for maximum pulse count
    input [TIM_GEN_RCOUNT - 1 : 0]      RangeCountMax ;     // 9 bit input for maximum range count
    
/*******************************************************************************************/
// Output parameters

    output [DATABUS_WIDTH - 1 : 0]      mag_out;            // Magnituder Output
    output                              mag_valid;          // Magnituder Valid Output
    output                              mag_cpi;
    
/*******************************************************************************************/
// Internal Variables

    wire [DATABUS_WIDTH - 1 : 0]        dfft_out_I;         // Doppler FFT Inphase Output
    wire [DATABUS_WIDTH - 1 : 0]        dfft_out_Q;         // Doppler FFT Quadrature Phase Output
    wire [DATABUS_WIDTH - 1 : 0]        dfft_out_I_fix;
    wire [DATABUS_WIDTH - 1 : 0]        dfft_out_Q_fix;
    wire [2*DATABUS_WIDTH - 1 : 0]      mag_in;
    wire [2*DATABUS_WIDTH - 1 : 0]      mag_out_fix;
    reg [TIM_GEN_PCOUNT + TIM_GEN_RCOUNT - 1 : 0]        cnt;
    
/*******************************************************************************************/
// Assignments

    assign dfft_out_I = dfft_out[DATABUS_WIDTH - 1 : 0];
    assign dfft_out_Q = dfft_out[2*DATABUS_WIDTH - 1 : DATABUS_WIDTH];
    assign dfft_out_I_fix = {dfft_out_I[DATABUS_WIDTH - 1],dfft_out_I[DATABUS_WIDTH - 1 : 1]};
    assign dfft_out_Q_fix = {dfft_out_Q[DATABUS_WIDTH - 1],dfft_out_Q[DATABUS_WIDTH - 1 : 1]};
    assign mag_in = {dfft_out_Q_fix,dfft_out_I_fix};
    //assign mag_out = {mag_out_fix[DATABUS_WIDTH - 1],mag_out_fix[DATABUS_WIDTH - 3 : 0],1'b0};
    assign mag_out = mag_out_fix[DATABUS_WIDTH - 1 : 0];
    assign mag_cpi = (cnt == PulseCountMax*RangeCountMax-1);
    
/*******************************************************************************************/
// Rectangular to Polar coordinates Translator

    cordic_magnituder
        MAG 
        (
            .aclk(clk),
            .aresetn(~rst),
            .s_axis_cartesian_tvalid(dfft_valid),
            .s_axis_cartesian_tdata(mag_in),
            .m_axis_dout_tvalid(mag_valid),
            .m_axis_dout_tdata(mag_out_fix)                 // contains both magnitude and phase, where phase is ignored
        );
        
/*******************************************************************************************/
// Counter to generate magnituder CPI

    always@(posedge clk)
    begin
        if(rst)
            cnt <= 'b0;
        else if(mag_valid && cnt<(PulseCountMax*RangeCountMax-1))
            cnt <= cnt + 1;
        else
            cnt <= 'b0;
    end

endmodule
