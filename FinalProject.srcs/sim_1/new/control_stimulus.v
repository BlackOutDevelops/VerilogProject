`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2021 03:18:35 PM
// Design Name: 
// Module Name: control_stimulus
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

`define idle            5'b01000
`define init            5'b11000
`define dc_decode       5'b11110
`define dc_coeff        5'b10010
`define ac_decode       5'b11011
`define ac_coeff        5'b10011

module control_stimulus();
   reg [3:0]       coeff_size_s2;
   reg [1:0]       run_length_s2;
   reg             match_s1,
                   reset_s1,
                   reset_control_s1,
                   phi1,
                   phi2,
                   reset_sr_s1,
                   valid_s1,
                   position_s1,
                   coeff_size_s1;
   
   reg [4:0]       next_state_s1;

   wire            position_s2,
                   new_block_s2;
   wire            reset_sr_s2;

   wire            dc_ac_s1,
                   valid_s2;
                   
   control C_tb(.reset_control_s1(reset_control_s1), .coeff_size_s2(coeff_size_s2), .run_length_s2(run_length_s2), .match_s1(match_s1), 
                .reset_s1(reset_s1), .valid_s2(valid_s2), .position_s2(position_s2), .dc_ac_s1(dc_ac_s1), .reset_sr_s2(reset_sr_s2), 
                .coeff_en_b_s2(coeff_en_b_s2),.new_block_s2(new_block_s2), .init_sr_s2(init_sr_s2), .init_dc_ac_s1(init_dc_ac_s1),
                .phi1(phi1), .phi2(phi2));
   
   initial
    begin
        phi1 = 0;
    end
   
   always
    begin
        phi1 = ~phi1;
        #20;
    end
    
    initial
        begin
            // idle to init
            reset_s1 = #10 1;
            //init to dc_decode
            reset_s1 = #40 0;
            //dc_decode to dc_coeff
            reset_sr_s1 = #40 0;
            match_s1 = 1;
            //dc_coeff to ac_decode
            reset_sr_s1 = #40 1;
            match_s1 = 0;
            
            // valid_s1 = 1;
            // OR
            coeff_size_s2 = 1;
            run_length_s2 = 1;
            //ac_decode to ac_coeff
            reset_sr_s1 = #40 0;
            match_s1 = 1;
        end
    
    always @(reset_s1 or next_state_s1 or phi1)
     begin
        case(next_state_s1)
            `idle: if (reset_s1)
                        next_state_s1 = `init;
                   else
                        next_state_s1 = `idle;
            `init: if (reset_s1)
                       next_state_s1 = `init;
                   else
                       next_state_s1 = `dc_decode;
            `dc_decode: if (match_s1 == 1 && reset_sr_s1 != 1)
                            next_state_s1 = `dc_coeff;
                        else
                            next_state_s1 = `dc_decode;
            `dc_coeff: if (valid_s1 || (coeff_size_s2 = 0))
                            next_state_s1 = `ac_decode;
                       else
                            next_state_s1 = `dc_coeff;
            `ac_decode: if (match_s1 == 1 && reset_sr_s1 != 1)
                            next_state_s1 = `ac_coeff;
                        else
                            next_state_s1 = `ac_decode;
            `ac_coeff: if ((valid_s1 && position_s1 == 15) || coeff_size_s1 == 0)
                            next_state_s1 = `dc_decode;
                       else if ((valid_s1 || (coeff_size_s2 = 0)) && !coeff_size_s1 && position_s1 != 15)
                            next_state_s1 = `ac_decode;
                       else
                            next_state_s1 = `ac_coeff;
            default: next_state_s1 = `idle;
        endcase
     end
endmodule
