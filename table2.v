//////////////////////////////////////////////////////////////////////////
//      Block Name      : datapath.v
//
//      Block Description :
//      This block implements the datapath portion of the Huffman decoder 
// 	and contains the lookup tables, shift registers, adder, comparator 
//  	and latches that are necessary to implement the Huffman Code
//      Identification Algorithm described in the project write-up.
//////////////////////////////////////////////////////////////////////////     

/////////////////////////////////////////////////////////////////////////////
module		table2(rw2_en_s1,coeff_size_v1,run_length_v1,
		address_s1,coeff_size_s2, run_length_s2,phi1, phi2);
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// Port Declarations
/////////////////////////////////////////////////////////////////////////////

input		phi1,phi2;	// - 2 phase clocks
input		rw2_en_s1;	// - Read/Write enable for table 2
input	[5:0]	address_s1;
input	[3:0]	coeff_size_v1;	// - Table 2 Data: Coefficient Size 
input	[1:0]	run_length_v1;	// - Table 2 Data: Run-length 

output	[3:0]	coeff_size_s2;	// - This signal tells the control the size
				//   of the coefficient following the Huffman
				//   code on the bitstream.  
output	[1:0]	run_length_s2;  // - This signal tells the control the number
			        //   of zeroes which precede the coefficient
				//   in the 4x4 block.

wire	[5:0]	address_s1;	
reg	[3:0]	coeff_size_s2;	
wire	[3:0]	coeff_size_v1;
reg	[1:0]	run_length_s2;	
wire	[1:0]	run_length_v1;


/////////////////////////////////////////////////////////////////////////////
// Internal Variable Declarations
/////////////////////////////////////////////////////////////////////////////


// There are 53 entries in the second lookup table of 4 and 2 bits each.
// The variables mem_size_v1 and mem_runlength_v1 hold the data written
// to the SRAM during initialization.
reg	[3:0]	mem_size_v1[52:0];
reg	[1:0]	mem_runlength_v1[52:0];

///////////////////////////////////////////////////////////////////////////////
//                                 DATAPATH                                  //
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// Lookup Table 2
// Inputs: rw2_en_s1, address_s1, coeff_size_v1, run_length_v1
// Outputs: coeff_size_s2, run_length_s2
///////////////////////////////////////////////////////////////////////////


// Initialize Table 2
always @ (phi1 or address_s1 or coeff_size_v1 or run_length_v1 or rw2_en_s1)
  if (phi1)
    begin
//  Write SRAM 
//  This line violates strict two-phase clocking.
       if (rw2_en_s1) begin
          mem_size_v1[address_s1] = coeff_size_v1;
          mem_runlength_v1[address_s1] = run_length_v1;
        end
    end

// Read from SRAM
assign coeff_size_v1 = ~rw2_en_s1 ? mem_size_v1[address_s1] : 4'bz;
assign run_length_v1 = ~rw2_en_s1 ? mem_runlength_v1[address_s1] :2'bz;
// End of lookup table 2

///////////////////////////////////////////////////////////////////////////////
// Latches for Table1/Table2 outputs
///////////////////////////////////////////////////////////////////////////////

// Latch Coeff_size and Run_length
always @(phi1 or coeff_size_v1)
	if (phi1)
	   coeff_size_s2 = coeff_size_v1;
always @(phi1 or run_length_v1)
	if (phi1)
	   run_length_s2 = run_length_v1;
// End of Latches of Table1/Table2 outputs



endmodule // table2
