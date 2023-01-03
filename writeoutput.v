//////////////////////////////////////////////////////////////////////////
//      Block Name      : writeoutput.v
//
//      Block Description :
//      This block writes the outputs to a file-huff_dec.out.
//
//////////////////////////////////////////////////////////////////////////

module writeoutput(coefficient_s2, position_s2, valid_s2, new_block_s2, phi1, 
                phi2);

input 	[9:0]	coefficient_s2;
input	[3:0]	position_s2;
input		valid_s2;
input		new_block_s2;	// This signal is high for one cycle when a 
				// new block is decoded.
input		phi1, phi2;

wire	[9:0]	coefficient_s2;
wire	[3:0]	position_s2;
wire		valid_s2;

wire	[31:0]	next_block_s2;
reg	[31:0]	block_s1;
reg	[31:0]  block_s2;

integer		myfile;

initial
 begin
	myfile = $fopen("huff_dec.out");
	block_s2 = -1;
 end

// Calculate the next 4x4 block number.
assign next_block_s2 = block_s2+'d1;
always @ (phi2 or next_block_s2 or block_s2)
   if (phi2)
      begin
	if (new_block_s2) 
           block_s1 = next_block_s2;
	else
	   block_s1 = block_s2;
      end

always @ (phi1 or block_s1)
   if (phi1)
	block_s2 = block_s1;

// If the outputs are valid, write them to huff_dec.out
always @(valid_s2)
   if (valid_s2) begin
      $fwrite(myfile,"%d %d %d\n", block_s2, coefficient_s2, position_s2);
   end
endmodule












