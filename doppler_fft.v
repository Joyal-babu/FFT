`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2024 17:06:57
// Design Name: 
// Module Name: doppler_fft
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


module doppler_fft
#(
    parameter             TIM_GEN_PCOUNT                   = 11,                     // Pulse Count Width
    parameter   	      DATABUS_WIDTH                    = 16,                     // RAM Data Width
    parameter             CONFIG_DATA                      = 16'b00000_01_10_10_10_10_1,    // Config data for FFT IP
    parameter             DOPPLR_FFT                       = 512
)
(
    clk,
    rst,
    PulseCountMax,
    win_out_I,
    win_out_Q,
    win_valid,
    doppler_fft_out,
    doppler_fft_valid,
    doppler_fft_cpi
);

/********************************************************************************/	                       
// constants

//    parameter             TIM_GEN_PCOUNT                   = 11;                     // Pulse Count Width
//    parameter   	      DATABUS_WIDTH                    = 16;                     // RAM Data Width
//    parameter             CONFIG_DATA                      = 16'b00000_01_10_10_10_10_1;    // Config data for FFT IP
//    parameter             DOPPLR_FFT                       = 512;
    
/********************************************************************************/ 
// Input parameters

    input                                           clk;
    input                                           rst;
    input [TIM_GEN_PCOUNT - 1 : 0]           		PulseCountMax ;                 // 11 bit input for maximum pulse count
    input [DATABUS_WIDTH - 1 : 0]                   win_out_I;                      // Inphase Output
    input [DATABUS_WIDTH - 1 : 0]                   win_out_Q;                      // Quadrature phase Output
    input                                           win_valid;                      // Window Output Valid

/********************************************************************************/ 
// Output parameters

    output [2*DATABUS_WIDTH - 1 : 0]                doppler_fft_out;                // Inphase Output
    output                                          doppler_fft_valid;              // Window Output Valid
    output                                          doppler_fft_cpi;
    
/********************************************************************************/ 
// Input Variables

    reg [TIM_GEN_PCOUNT - 1 : 0]                    count;
    wire                                            last_in_sample;
    reg [2*DATABUS_WIDTH - 1 : 0]                   dfft_in;
    wire [2*DATABUS_WIDTH - 1 : 0]                  real_imag_in;
    reg                                             config_valid;
    reg                                             valid_in;
    wire [15:0]                                     sample_cnt;
    wire                                            padding_zero;
    
/********************************************************************************/ 
// Assignments

    assign last_in_sample = (count==DOPPLR_FFT-1);
    assign real_imag_in = {win_out_Q,win_out_I};
    assign sample_cnt = (PulseCountMax>DOPPLR_FFT)?PulseCountMax:DOPPLR_FFT;
    assign padding_zero = (PulseCountMax<DOPPLR_FFT && count>=PulseCountMax)?1'b1:1'b0;
 
/********************************************************************************/ 
// Counter

    always@(posedge clk)
    begin
        if(rst)
            count <= 'b0;
        else if(win_valid)
            count <= 'd1;
        else if(count>0 && count < sample_cnt-1)
            count <= count + 1;
        else
            count <= 'b0; 
    end
    
/********************************************************************************/ 
// Truncate Input samples or padding of zeros at input
    
    always@(posedge clk)
    begin
        if(rst)
            dfft_in <= 'b0;
        else if(padding_zero)
            dfft_in <= 'b0;
        else if(win_valid)
            dfft_in <= real_imag_in;
        else
            dfft_in <= 'b0;
    end

    always@(posedge clk)
    begin
        if(rst)
            valid_in <= 1'b0;
        else if(count>0 && count < sample_cnt-1)
            valid_in <= 1'b1;
        else
            valid_in <= 1'b0;
    end
    
//    always@(posedge clk)
//    begin
//        if(rst)
//            valid_in <= 1'b0;
//        else if(win_valid && count<DOPPLR_FFT-1 )
//            valid_in <= 1'b1;
//        else if(padding_zero)
//            valid_in <= 1'b1;
//        else
//            valid_in <= 1'b0;
//    end
    
/********************************************************************************/ 
// Doppler FFT config

    always@(posedge clk)
    begin
        if(rst)
            config_valid <= 1'b1;
        else
            config_valid <= 1'b0;
    end
    
/********************************************************************************/ 
// Doppler FFT

    dfft DOPP_FFT
        (
            .aclk(clk),
            .s_axis_config_tdata(CONFIG_DATA),
            .s_axis_config_tvalid(config_valid),
            .s_axis_config_tready(),
            .s_axis_data_tdata(dfft_in),
            .s_axis_data_tvalid(valid_in),
            .s_axis_data_tready(),
            .s_axis_data_tlast(last_in_sample),
            .m_axis_data_tdata(doppler_fft_out),
            .m_axis_data_tvalid(doppler_fft_valid),
            .m_axis_data_tlast(doppler_fft_cpi),
            .event_frame_started(),
            .event_tlast_unexpected(),
            .event_tlast_missing(),
            .event_data_in_channel_halt()
        );

endmodule
