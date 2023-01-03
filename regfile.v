//////////////////////////////////////////////////////////////////////////
//      Block Name      : regfile.v
//
//      Block Description :
//		This block models the table1 regfile. Table 1 consists of
// 		maxcode and base for both AC and DC terms.
//
// Lookup Table 1:
// Lookup Table 1 outputs maxcode_v1 and base_v1.
//
// For each code_length (address) there are two entries in the SRAM for both
// maxcode and base.  If dc_ac_s1=0 the ac entries are selected and if dc_ac_s1 = 1
// then the dc entries are output on maxcode_v1 and base_v1.
//
// Controls: wordnum_s1
// Inputs: maxcode_v1, base_v1, rw1_en_s1, dc_ac_s1 
// Outputs: maxcode_v1, base_v1
////////////////////////////////////////////////////////////////////////////   

////////////////////////////////////////////////////////////////////////////
module		regfile(reset_s1,rw1_en_s1,maxcode_v1,
		base_v1, dc_ac_s1,reset_sr_s2, phi1, phi2);
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
// Port Declarations
////////////////////////////////////////////////////////////////////////////

input		phi1,phi2;	// - 2 phase clocks
input		reset_s1;	// - When reset is high, the lookup tables are
				//   initialized and when reset is low the
				//   image on the bitstream is decoded.
input		rw1_en_s1;	// - Read/Write enable for table 1: 
				//   0 if read, 1 if write.
input		dc_ac_s1;	// - Selects whether the AC or DC Lookup Table
                                //   is read: 1 selects dc, 0 selects ac.
input 		reset_sr_s2;	// - Signal resets shift-reg's when a new
                                //   huffman code or coefficient is identified.

//INPUT (Initialization) OUTPUT (in normal operations)
// When reset=1 then the following signals are driven by stimulus.v, but when
// reset=0 they are the bitlines of lookup tables 1 and 2.  

inout	[8:0]	maxcode_v1; 	// - Table 1 Data: Maxcode
inout	[5:0]	base_v1;	// - Table 1 Data: Base

/////////////////////////////////////////////////////////////////////////////
// Internal Variable Declarations
/////////////////////////////////////////////////////////////////////////////

reg	[7:0]	wordnum_s1;	// - Selects wordlines (address) in Lookup Table 1
wire	[8:0]	maxcode_v1;	
wire	[5:0]	base_v1;	//   the Table 2 address.

//Lookup Table 1 Variable Declarations
// There are 8 entries in Lookup table 1 with a size of 6 and 9 bits.
// The following 4 declarations hold the data written to the SRAM during
// initialization.

reg	[5:0]	ac_base_v1[7:0];
reg	[8:0]	ac_maxcode_v1[7:0];
reg	[5:0]	dc_base_v1[7:0];
reg	[8:0]	dc_maxcode_v1[7:0];

reg	[3:0]	decodenum_s1;	
wire 	[5:0]	base_tmp_v1;
wire	[5:0]  	ac_basetmp_v1;
wire	[5:0]   dc_basetmp_v1;
wire	[8:0]	ac_maxcodetmp_v1;
wire	[8:0]	dc_maxcodetmp_v1;

// Convert the wordline selector back to a decimal value so that it may be 
// used in an array.  This logic is only needed in verilog and won't be 
// implemented in layout.  
always @(wordnum_s1)
   begin
      case (wordnum_s1)
         8'b00000001: decodenum_s1 = 0;
	 8'b00000010: decodenum_s1 = 1; 
	 8'b00000100: decodenum_s1 = 2; 
	 8'b00001000: decodenum_s1 = 3; 
	 8'b00010000: decodenum_s1 = 4; 
	 8'b00100000: decodenum_s1 = 5; 
	 8'b01000000: decodenum_s1 = 6; 
	 8'b10000000: decodenum_s1 = 7;
// The default case occurs when no wordline is selected.
         default: decodenum_s1 = 8;
      endcase
   end 

always @ (phi1 or decodenum_s1 or base_v1 or maxcode_v1 or dc_ac_s1 or rw1_en_s1)
  if (phi1)
    begin
// Write DC values to SRAM (written during initialization)
       // Note: this line violates strict two-phase clocking
       if (rw1_en_s1 == 1'b1 && dc_ac_s1 == 1'b1) begin
          dc_maxcode_v1[decodenum_s1] = maxcode_v1;
          dc_base_v1[decodenum_s1] = base_v1;
        end
// Write AC values to SRAM (written during initialization)
       // Note: this line violates strict two-phase clocking
       else if (rw1_en_s1 == 1'b1 && dc_ac_s1 == 1'b0) begin
          ac_maxcode_v1[decodenum_s1] = maxcode_v1;
          ac_base_v1[decodenum_s1] = base_v1; 
        end
    end

// Read from SRAM (Base)
assign ac_basetmp_v1 = ~rw1_en_s1 ? ac_base_v1[decodenum_s1] : 6'bz;
assign dc_basetmp_v1 = ~rw1_en_s1 ? dc_base_v1[decodenum_s1] : 6'bz;
// If dc_ac_s1=1 select the dc value otherwise select the ac value
assign base_tmp_v1 = dc_ac_s1 ? dc_basetmp_v1 : ac_basetmp_v1;

// Read from SRAM (Maxcode)
assign ac_maxcodetmp_v1 = ~rw1_en_s1 ? ac_maxcode_v1[decodenum_s1] : 9'bz;
assign dc_maxcodetmp_v1 = ~rw1_en_s1 ? dc_maxcode_v1[decodenum_s1] : 9'bz;
// If dc_ac_s1=1 select the dc value otherwise select the ac value.
assign maxcode_v1 = dc_ac_s1 ? dc_maxcodetmp_v1 : ac_maxcodetmp_v1;

// Models the case when no bitlines are selected.  During initialization
// base_v1 is latched and added with bits=0 in the bitstream shift register to 
// to generate the address for Lookup Table 2.
assign base_v1 = decodenum_s1[3] ? 6'bz : base_tmp_v1; 

// End of Lookup table 1

///////////////////////////////////////////////////////////////////////////////
// 8-bit Code_length SR:
// This functional block generates the wordline selects for lookup table 1.
// Only one wordline will be high at one time.
// 
// In SRAMs the wordline selects which of the 8 DC/AC values will be read
// on the bit-lines (maxcode_v1 and base_v1).  Because the wordlines are selected
// in order (code_length = 2-9) a shift register is used to select the wordlines
// instead of an incrementer.
// 
// When the shift register is reset by reset_sr_s2, the input to the shift register,
// count_in_s2, is high for one cycle.  The output, wordnum_s1 selects one of the 
// bitlines each cycle until the huffman code length is determined.
//
// Inputs: reset_sr_s2, phi1, phi2
// Output: wordnum_s1
/////////////////////////////////////////////////////////////////////////////////
// Insert your code here

reg [7:1] state_s2;
wire [7:0] state_tmp_s2;

always @(posedge phi1 or wordnum_s1)
if (phi1)
state_s2[7:1] = wordnum_s1[6:0];

always @(negedge phi1 or state_tmp_s2)
if (! phi1)
wordnum_s1 = state_tmp_s2;

assign state_tmp_s2[7:1] = reset_sr_s2 ? 7'b0 : state_s2[7:1];
assign state_tmp_s2[0] = reset_sr_s2;

// End of code_length shift register.
endmodule // regfile

