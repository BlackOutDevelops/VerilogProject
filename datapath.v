//////////////////////////////////////////////////////////////////////////
//      Block Name      : datapath.v
//
//      Block Description :
//      This block implements the datapath portion of the Huffman decoder 
// 	and shift registers, adder, comparator and latches that are 
//	necessary to implement the Huffman Code
//
//////////////////////////////////////////////////////////////////////////     
//
//  The following blocks have been implemented for you:
//  o 10-bit shift register
//
//  You have to implement the following blocks:
//  o 9-bit comparator (bits > maxcode)
//  o 6-bit table2_addr calculation
//  o Add 5 additional latches to ensure correct timing of signals
//    (look at the timing diagram in the homework to determine where
//     they should go)
//

/////////////////////////////////////////////////////////////////////////////
module		datapath(bitstream_s1,maxcode_v1, base_v1,
		reset_sr_s2,coeff_en_b_s2,match_s1, address_s1,
		coefficient_s2,phi1, phi2);
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// Port Declarations
/////////////////////////////////////////////////////////////////////////////

input		phi1,phi2;	// - 2 phase clocks

//INPUT 
input 		bitstream_s1;	// - JPEG bitstream
input 		reset_sr_s2;	// - Signal resets shift-reg's when a new
                                //   huffman code or coefficient is identified.
input		coeff_en_b_s2;	// - This signal controls whether the bitstream
				//   shift register is reset to a 1 or 0.
input	[8:0]	maxcode_v1; 	// - Table 1 Data: Maxcode
input	[5:0]	base_v1;	// - Table 1 Data: Base


output		match_s1;	// - Indicates that the Huffman code length has 
				//   been determined.
output	[9:0]	coefficient_s2;			    
output	[5:0]	address_s1;	// - Table 2 Address that selects the corresponding

/////////////////////////////////////////////////////////////////////////////
// Datapath Variable Declarations
/////////////////////////////////////////////////////////////////////////////

reg	[5:0]	address_s1;	// - Table 2 Address that selects the corresponding
wire	[5:0]	address_s2;     //   coeff_size and run_length
reg	[8:0]	maxcode_s1;	// - Largest Huffman code for a given code_length.
reg	[8:0]	maxcode_s2;	
wire	[8:0]	maxcode_v1;	
reg	[5:0]	base_s2;	// - Value from Table 1 that is used to calculate the 
wire	[5:0]	base_v1;	//   the Table 2 address.
wire	[5:0]	bits_s2;	// - 6 LSB's of the 10-bit shift register
reg	[9:0]	bits_s1;        // - Contents of 10-bit shift register
reg	[9:0]	coefficient_s2;


///////////////////////////////////////////////////////////////////////////////
//                                 DATAPATH                                  //
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 10-bit Shift Register for Jpeg Bitstream:
// This block receives the jpeg bitstream and sends latched output to 
// a) Table 2 address calculation  
// b) Huffman Code-Length determination. (match_s1 generation)
// The shift register is reset after a huffman code or coefficient has been 
// shifted in.  The shift register should NOT be reset if the coefficient 
// size is zero. Note that the first bit of the shift register is never reset!
//
// A shift register consists of a number of latches connected in series with
// alternating phi1 and phi2 clock signals.  The data is serially shifted from
// latch to latch.
// Inputs: 	bitstream_s1 -- encoded bitstream
//		reset_sr_s2 -- When this signal is 1 the shift register is reset.
//		coeff_en_b_s2 -- When a coefficient is shifted in this signal=0
//                               and when a huffman code is shifted in it's 1.
// Outputs: 	bits_s1, bits_s2 signals used by the datapath. 		
///////////////////////////////////////////////////////////////////////////////

// Interval Variable Declarations
reg	[9:0]	par_out_s2;
wire	[9:0]	par_out_tmp_s2;
wire		reset_tmp_s2;

always @(phi1 or bitstream_s1 or bits_s1[9:0])
     if (phi1)
        begin
          par_out_s2[0] = bitstream_s1;
	  par_out_s2[9:1] = bits_s1[8:0];
        end 
always @(phi2 or par_out_tmp_s2)
      if (phi2)
         begin
	    bits_s1 = par_out_tmp_s2; 
         end

// The coefficients that are placed on the bitstream may be positive or negative.
// It may be determined if the coefficient is positive or negative by looking at the
// first bit on the bitstream.  The bitstream is reset to all 1's if the coefficient
// is negative (the MSB of the coefficient is 0) and is reset to all 0's
// if coefficient is positive (the MSB of the coefficient is 1).

assign reset_tmp_s2 = ~(coeff_en_b_s2 | par_out_s2[0]);
assign par_out_tmp_s2[9:1] = reset_sr_s2 ? {9{reset_tmp_s2}} : par_out_s2[9:1];

// The first bit of the shift register is never reset because a new bit is 
// shifted in each cycle.
assign par_out_tmp_s2[0] = par_out_s2[0];

// bits_s2 only needs to be 6 bits long.
assign bits_s2 = par_out_tmp_s2[5:0];
// End of 10-bit shift Register


///////////////////////////////////////////////////////////////////////////////
// Latches for Table1 outputs
///////////////////////////////////////////////////////////////////////////////
always @(posedge phi1 or base_v1)
     if (phi1)
        base_s2 = base_v1;
         
always @(posedge phi1 or maxcode_v1)
    if (phi1)
        maxcode_s2 = maxcode_v1;
// End of Latches of Table1 outputs

//////////////////////////////////////////////////////////////////////////////
// Table 2 address calculation:
// The Huffman code in the bitstream shift register is added with base
// to create the lookup table 2 address.
//////////////////////////////////////////////////////////////////////////////
always @(posedge phi1 or base_s2 or bits_s2)
    begin
        assign address_s1 = bits_s2 + base_s2;
    end
// End of address calculation

////////////////////////////////////////////////////////////////////////////////
// Compare Maxcode to Bits:
// If bits <=  nm maxcode then match=1 and the Huffman code length has been 
// determined.  This comparison between maxcode and bits is always made
// but match_s1 is only sampled by the control when a Huffman code is being
// read from the bitstream and code_length is greater than 1.
///////////////////////////////////////////////////////////////////////////////
assign match_s1 = bits_s1 <= maxcode_s2;
// End of comparator

////////////////////////////////////////////////////////////////////////////////
// Latch for Coefficient_s2 Output
////////////////////////////////////////////////////////////////////////////////
always @(coeff_en_b_s2 or bits_s1)
     if (coeff_en_b_s2 == 1'b1)
        coefficient_s2 = bits_s1;
endmodule // datapath





