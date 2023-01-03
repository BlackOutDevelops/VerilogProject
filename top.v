module top();

// INPUT Signals (Datapath)
wire		phi1;		// - 2-phase clocks	
wire		phi2;
wire 		bitstream_s1;	// - JPEG bitstream
wire		reset_s1;	// - Indicates when lookup tables are being  
				//   initialized and when the bitstream is valid.
wire		rw1_en_s1;	// - Read/write control signal to Table 1
wire		rw2_en_s1;	// - Read/write control signal to Table 2

// INPUT Signals (Initialization)
wire	[8:0]	maxcode_v1; 	// - Table 1 Data: Maxcode
wire	[5:0]	base_v1;	// - Table 1 Data: Base
wire	[3:0]	coeff_size_v1;	// - Table 2 Data: Coefficient Size 
wire	[1:0]	run_length_v1;	// - Table 2 Data: Run-length 
wire		dc_ac_s1;	// - Selects whether the AC/DC Lookup Table 1
                                //   is read in: 1 selects dc, 0 selects ac. (Tri-state)
wire		new_block_s2;

// OUTPUT Signals
wire	[9:0]	coefficient_s2; 	   
wire		valid_s2; 	// - Indicates that the coefficient and 
				//   position are valid.
wire	[3:0]	position_s2;	// - Zig-zag position within the 4x4 block


// Internal Control Signals
wire		reset_sr_s2;	// - Signal resets shift-reg's when a new
                                //   huffman code or coefficient is identified.
wire		coeff_en_b_s2;	// - 
wire	[3:0]	coeff_size_s2;	// - Coeff_Size of Coefficient
wire	[1:0]	run_length_s2;	// - Number of zero's preceding coefficient
wire		match_s1;	// - Indicates that Huffman code length has 
				//   been determined.
wire	[5:0]	address_s1;
wire		reset_control_s1;
wire		init_sr_s2;
wire		init_dc_ac_s1;

//////////////////////////////////////////////////////////////////////////////////////
// Module Instantiations
//////////////////////////////////////////////////////////////////////////////////////

table2		table2(rw2_en_s1,coeff_size_v1,run_length_v1,
			address_s1,coeff_size_s2, run_length_s2,phi1, phi2);
regfile		regfile(reset_s1,rw1_en_s1,maxcode_v1,
			base_v1, dc_ac_s1,reset_sr_s2, phi1, phi2);
datapath	datapath(bitstream_s1,maxcode_v1, base_v1,
			reset_sr_s2,coeff_en_b_s2,match_s1, address_s1,
			coefficient_s2,phi1, phi2);

control		control(reset_control_s1,coeff_size_s2, run_length_s2, 
			match_s1, reset_s1, valid_s2, position_s2, dc_ac_s1, 
			reset_sr_s2, coeff_en_b_s2, new_block_s2,
		 	init_sr_s2, init_dc_ac_s1,phi1, phi2);
clkgen		clkgen(phi1, phi2);

// Instantiate testing infrastructure

stimulus      	stimulus(reset_control_s1,bitstream_s1,reset_s1,rw1_en_s1,rw2_en_s1,
			maxcode_v1,base_v1,coeff_size_v1,run_length_v1,
			init_dc_ac_s1,init_sr_s2,phi1,phi2);

writeoutput	writeoutput(coefficient_s2, position_s2, valid_s2,
			new_block_s2, phi1, phi2);



  initial 
    begin
   /*   $gr_waves( "phi1", phi1,
                "phi2", phi2,
		"reset_s1", reset_s1,
		"reset_sr_s2", reset_sr_s2,
		"coeff_en_b_s2", coeff_en_b_s2,
		"address_s1", address_s1, 
		"match_s1", match_s1,
                "coefficient_s2", coefficient_s2,
		"bits_s1", datapath.bits_s1,
		"bits_s2", datapath.bits_s2,
		"wordnum_s1",regfile.wordnum_s1, 
		"next_state_s1", control.next_state_s1,
		"curr_state_s1", control.curr_state_s1,
                "valid_s2", valid_s2
		);	
    */
       $dumpvars;
       
    end


endmodule





