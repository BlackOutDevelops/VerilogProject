//////////////////////////////////////////////////////////////////////////
//      Block Name      : stimulus.v
//
//      Block Description :
//      This block implements the stimulus necessary to initialize the 
//   	lookup tables and supplies the JPEG bitstream to the datapath.
//	
//	You should not look at this block as an example of great verilog coding
//	style. (in fact it's pretty bad)  It's primary purpose is to provide 
//      stimulus to the datapath and control and emulate the world outside of
//      our project.
//
//////////////////////////////////////////////////////////////////////////

// You need to change this line whenever a new image is copied to image.dat.
// NUM_BITS should be set equal to the following:
// test1.dat: 32
// test2.dat: 147
// mystery.dat: 83391

 
`define NUM_BITS 32

// FILE1, FILE2, and FILE3 contain information necessary to initialize
// and stimulate the datapath and control.
// FILE1 - Initialization information for table 1.
// Data format: <maxcode[8:0]><base[5:0]> 
// FILE2 - Initialization information for table 2.
// Data format: <address[5:0]><coeff_size[3:0]><run_length[1:0]>
// FILE3 - Each line contains a bit of the JPEG Bitstream.

`define	FILE1	"table1.dat"
`define FILE2   "table2.dat"
`define FILE3 	"test1.dat"

/////////////////////////////////////////////////////////////////////////////
module		stimulus(reset_control_s1,bitstream_s1,reset_s1,rw1_en_s1,
		rw2_en_s1,maxcode_v1,base_v1,
		coeff_size_v1,run_length_v1,init_dc_ac_s1,
                init_sr_s2,phi1,phi2);
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// Port Declarations
/////////////////////////////////////////////////////////////////////////////
input 		phi1,phi2;	// - 2 phase clocks

output		bitstream_s1;	// - JPEG bitstream;
output		reset_s1;	// - Reset signal: 1 during initialization,
				//   0 during decoding
output		rw1_en_s1;	// - Read/Write enable for table 1: 
				//   0 selects read, 1 selects write.
output		rw2_en_s1;	// - Read/Write enable for table 2
output	[8:0]	maxcode_v1; 	// - Table 1 Data: Maxcode
output	[5:0]	base_v1;	// - Table 1 Data: Base
output	[3:0]	coeff_size_v1;	// - Table 2 Data: Coefficient Size 
output	[1:0]	run_length_v1;	// - Table 2 Data: Run-length 
output  	init_dc_ac_s1;	// - 1 if writing to DC memory elements,
				//   0 if writing to AC memory elements.
output		init_sr_s2;	// - Driven during initialization and 
				//   set to 0 during decoding.  
output		reset_control_s1; // resets control

reg		reset_s1;
reg		bitstream_s1;
reg		rw1_en_s1;
reg		rw2_en_s1;
reg		init_sr_s2;

wire	[8:0]	maxcode_v1;
wire	[5:0]	base_v1;
wire	[3:0]	coeff_size_v1;
wire	[1:0]	run_length_v1;
wire		init_dc_ac_s1;

/////////////////////////////////////////////////////////////////////////////
// Internal Variable Declarations
/////////////////////////////////////////////////////////////////////////////
reg		init_sr_s1;
reg	[1:0]	state;
reg	[8:0]	maxcode_s1;
reg	[5:0]	base_s1;
reg	[3:0]	coeff_size_s1;
reg	[1:0]	run_length_s1;
reg	[20:0]	ProgCntr;        // Used as the array pointer for Table1, Table2
				 // and ProgCntr
reg		reset_control_s1;

reg	[14:0]	Table1[15:0];    // table1.dat is read into this array
reg	[11:0]	Table2[53:0];	 // table2.dat is read into this array
reg		Image[`NUM_BITS:0]; //image.dat is read into this array
reg		dc_ac_tmp_s1;

// Define States needed in stimulus.v
`define	RESET		2'b00
`define INIT_TABLE1 	2'b01
`define INIT_TABLE2 	2'b10
`define READ_IMAGE 	2'b11

// Load the test vectors from files
initial
   begin
      // Initialize Table1 and Table2 to zero.
      for (ProgCntr = 0; ProgCntr < 54; ProgCntr = ProgCntr+1)
         Table2[ProgCntr] = 12'b0;
      for (ProgCntr = 0; ProgCntr < 16; ProgCntr = ProgCntr+1)
	 Table1[ProgCntr] = 15'b0;
      // $write is a command which allows you to write text to the 
      // verilog session.
      $write("Reading in Table 1: Maxcode, Base:");
      $display(`FILE1);
      // $readmemb loads the contents of FILE into an array
      $readmemb(`FILE1, Table1);
      $write("Reading in Table 2: Address(n-1), Run-length(n), Size(n):");
      $display(`FILE2);
      $readmemb(`FILE2, Table2);
      $write("Reading in image: ");
      $display(`FILE3);
      $readmemb(`FILE3, Image);
      ProgCntr = 0;
   end

// Create tri-state signals for maxcode_v1, base_v1, coeff_size_v1, and 
// run_length_v1.  These signals are only driven by stimulus.v during 
// initialization. While decoding (reset_s1 == 0) these values are driven 
// by the datapath or control and tri-stated in stimulus.v.
assign maxcode_v1 = reset_s1 ? maxcode_s1 : 9'bz;
assign base_v1 = reset_s1 ? base_s1 : 6'bz;
assign coeff_size_v1 = reset_s1 ? coeff_size_s1 : 4'bz;
assign run_length_v1 = reset_s1 ? run_length_s1: 2'bz;
assign init_dc_ac_s1 = reset_s1 ? dc_ac_tmp_s1: 1'b0;	

always @ (phi1 or init_sr_s1 or reset_s1)
   if (phi1) begin
      if (reset_s1)
         init_sr_s2 = init_sr_s1;
      else 
 	 init_sr_s2 = 1'b0;
    end

// State Machine for stimulus.v
// The four possible states are RESET, INIT_TABLE1, INIT_TABLE2,
// and READ_IMAGE.  
// RESET:  Make sure that the datapath and control are initialized
// INIT_TABLE1: Write the contents of table1.dat to lookup table 1 
// INIT_TABLE2: Write the contents of table2.dat to lookup table 2
// READ_IMAGE: Provide bitstream_s1 with data every clock cycle.

// You shouldn't be using flops in the datapath.
always @ (posedge phi2)
   begin
      case (state)
	 `RESET: begin
             $write("State: RESET\n");
	 // Select Next State: Stay in RESET for five clock cycles
             if (ProgCntr == 4) 
                begin
   		  state = `INIT_TABLE1;
                  ProgCntr = 0;
                  init_sr_s1 = 1;
 		  reset_s1 = 1;
                end
	     else 
                begin
	          state = `RESET;
		  reset_s1 = 0;
	          ProgCntr = ProgCntr + 1;
                  init_sr_s1 = 0;
                end
	// Set Variables for RESET
	     reset_control_s1 = 1;	
             bitstream_s1 = 0;
             rw1_en_s1 = 0;
             rw2_en_s1 = 0;
             dc_ac_tmp_s1 = 0;
            end
         `INIT_TABLE1: begin
             if (ProgCntr == 7)
                init_sr_s1 = 1;
             else init_sr_s1 = 0;

             // Selects whether the ac or dc memory is written.
             if (ProgCntr < 8)
                dc_ac_tmp_s1 = 0;
             else dc_ac_tmp_s1 = 1;

             // Initialize other variables.
	     reset_control_s1 = 0;
             bitstream_s1 = 0;
             reset_s1 = 1;
             rw1_en_s1 = 1;
             rw2_en_s1 = 0;

             // Read from the file
             {maxcode_s1, base_s1} = Table1[ProgCntr];
             ProgCntr = ProgCntr + 1;

             $write("State: INIT_TABLE1 maxcode=%b base=%b\n", maxcode_s1, base_s1);

             // Set State
             if (ProgCntr < 16)
                state = `INIT_TABLE1;
             else begin
                state = `INIT_TABLE2;
                ProgCntr = 0;
              end              
            end
         `INIT_TABLE2: begin
             // Initialize variables
             reset_control_s1 = 0;
             bitstream_s1 = 0;
             reset_s1 = 1;
             rw1_en_s1 = 1;
             dc_ac_tmp_s1 = 0;
             init_sr_s1 = 0;
             if (ProgCntr > 0)
                rw2_en_s1 = 1;
             else
                rw2_en_s1 = 0;
       
             // Read data from table2.dat:
             // address(n+1), run_length(n), coeff_size(n)
             {base_s1, run_length_s1, coeff_size_s1} = Table2[ProgCntr];
             ProgCntr = ProgCntr+1;
       
             $write("State: INIT_TABLE2 run_length=%h coeff_size=%h\n", run_length_s1,
 	             coeff_size_s1);

             // Set State
             if (ProgCntr < 54)
                state = `INIT_TABLE2;
             else begin
		$write("Decoding image...\n");
                state = `READ_IMAGE;
                ProgCntr = 0;
              end  
            end
         `READ_IMAGE: begin
             // Set initial variables
             reset_s1 = 0;
             reset_control_s1 = 0;
             rw1_en_s1 = 0;
             rw2_en_s1 = 0;
	     // Set state and stop stimulation
             if (ProgCntr <= `NUM_BITS + 1) begin
                {bitstream_s1} = Image[ProgCntr];
                state = `READ_IMAGE;
              end
	     else
		$stop;
             ProgCntr = ProgCntr + 1;
            end
         default: begin
               state = `RESET;
            end
      endcase
     end
endmodule







