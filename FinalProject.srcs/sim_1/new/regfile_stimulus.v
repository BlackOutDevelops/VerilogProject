//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2021 08:47:11 PM
// Design Name: 
// Module Name: regfile_stimulus
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


module regfile_stimulus();
reg		phi1,phi2;	// - 2 phase clocks
reg		reset_s1;	// - When reset is high, the lookup tables are
				//   initialized and when reset is low the
				//   image on the bitstream is decoded.
reg		rw1_en_s1;	// - Read/Write enable for table 1: 
				//   0 if read, 1 if write.
reg		dc_ac_s1;	// - Selects whether the AC or DC Lookup Table
                                //   is read: 1 selects dc, 0 selects ac.
reg 		reset_sr_s2;	// - Signal resets shift-reg's when a new
                                //   huffman code or coefficient is identified.

//INPUT (Initialization) OUTPUT (in normal operations)
// When reset=1 then the following signals are driven by stimulus.v, but when
// reset=0 they are the bitlines of lookup tables 1 and 2.  

wire	[8:0]	maxcode_v1; 	// - Table 1 Data: Maxcode
wire	[5:0]	base_v1;	// - Table 1 Data: Base
regfile rg_tb(.reset_s1(reset_s1),.rw1_en_s1(rw1_en_s1),.maxcode_v1(maxcode_v1),
		.base_v1(base_v1), .dc_ac_s1(dc_ac_s1),.reset_sr_s2(reset_sr_s2), .phi1(phi1), .phi2(phi2));
		
initial
    begin
        phi1 = 0;
        reset_sr_s2 = 0;
    end
   
always
    begin
        phi1 = ~phi1;
        #20;
    end
    
always
    begin
        reset_sr_s2 = ~reset_sr_s2;
        #45;
    end   
endmodule
