// ////////////////////////////////////////////////////////////////////////
//      Block Name      : control.v
//
//      Block Description :
//      This block generates the control signals to datapath of
//      Huffman Decoder.
//
// ////////////////////////////////////////////////////////////////////////

`define idle            5'b01000
`define init            5'b11000
`define dc_decode       5'b11110
`define dc_coeff        5'b10010
`define ac_decode       5'b11011
`define ac_coeff        5'b10011

// ///////////////////////////////////////////////////////////////////////
// Module Declarations
// //////////////////////////////////////////////////////////////////////

module  control(reset_control_s1, coeff_size_s2, run_length_s2, match_s1, 
                reset_s1, valid_s2, position_s2, dc_ac_s1, reset_sr_s2, 
                coeff_en_b_s2,new_block_s2, init_sr_s2, init_dc_ac_s1,
                phi1, phi2);
   
   // ////////////////////////////////////////////////////////////////////////
   // Port Declarations
   // ///////////////////////////////////////////////////////////////////////
   
   input   [3:0]   coeff_size_s2;   // size of coefficient to shift in
   input [1:0]     run_length_s2;   // number of zeros before current coeff.
   input           match_s1,    // match_s1=1 when huffman code found
                   reset_s1,    // reset_s1=1 when initiatializing the
                   // huffman decoder look up tables 
                   reset_control_s1,// initialize controller to idle state
                   init_sr_s2,  // initialize shift register
                   init_dc_ac_s1,   // initialize DC or AC table
                   phi1,        // phase one clock
                   phi2;        // phase two clock

   output [3:0]    position_s2; // position within 4X4 block where coeff.
   // resides
   output          reset_sr_s2, // reset shift register control signal
                   coeff_en_b_s2,   // whether to reset SR to all 1's or 0's
                   new_block_s2,    // indicates next 4X4 block
                   dc_ac_s1,    // Selects maxcode from
                   // 1 : use DC Huffman table
                   // 0 : use AC Huffman table
                   valid_s2;    // indicates all bits of coeff. have been 
   // shifted in. So coefficient_s1 and
   // position_s2 are valid

   wire [3:0]      coeff_size_s2;
   wire [1:0]      run_length_s2;
   wire            match_s1,
                   reset_s1,
                   reset_control_s1,
                   new_block_s2,
                   phi1,
                   phi2;

   reg [3:0]       position_s2;
   wire            reset_sr_s2;

   wire            dc_ac_s1,
                   valid_s2;

   // //////////////////////////////////////////////////////////////////////
   // Internal Variable Declarations
   // //////////////////////////////////////////////////////////////////////
   
   wire [3:0]      curr_pos_s1, // coefficient's current position
                   cntr_s1; // output of counter for No. of bits left
   // to shift in   
   wire            reset_pos_s1;    // reset position counter in DC decode 
   reg             reset_pos_s2;    // state
   reg             reset_sr_del_s2;
   reg             reset_sr_del_s1; 
   reg [3:0]       prev_pos_s1,    // register to hold position_s2
                   position_s1, // delayed version of position_s2 for 
                   // controller
                   coeff_size_s1,   // size of the coeff. No. of bits to shift
                   // in
                   cntr_s2, // No. of bits left of Coeff. to shift in
                   cntr_in_s1;  // cntr_s1=cntr_in_s1-1

   reg [1:0]       run_length_s1;   // number of zeros before current coeff.

   reg             valid_s1,    // indicates all bits of coeff. have been 
                   // shifted in. So coefficient_s1 and
                   // position_s2 are valid

                   match_s2,    // asserted when maxcode matches code
                   // shifted in        
                   match_del_s2,    // delayed version of match_s1 & decode
                   match_del_s1;    // delayed version of match_s1 & decode
   reg             reset_s2;    // asserted during initialization
   reg             muxsel_s2;   // asserted when load coeff_size_s2 into 
   wire            muxsel_s1;   // counter cntr_in_s1
   wire            count_in_ctrl_FSM_s1,    // start shift in count_in_s2 into
                   // SR 
                   reset_sr_ctrl_FSM_s1,    // resets both SR's
                   dc_ac_en_s1,     // selects dc_ac_ctrl_s1 or 
                   // init_dc_ac_s1 to dc_ac_s1
                   dc_ac_ctrl_s1;       // 1 : decoding DC code
   // 0 : decoding AC code
   reg             reset_sr_s1,     // reset SR's
                   reset_sr_ctrl_s2,    // reset SR control signal
                   reset_sr_ctrl_s1,    // reset SR control signal
                   reset_sr_reset_s1;   // deassert reset_sr_s2 after one 
   // cycle

   reg             reset_sr_tmp_s2, // temp reg to store reset_sr_s2
                   coefftmp_en_b_s2;    // temp reg to store coeff_en_b_s2
   
   reg [4:0]       curr_state_s1,       // state reg
                   curr_state_s2,
                   next_state_s1,
                   next_state_s2;
   
   // /////////////////////////////////////////////////////////////////////
   //    Small Datapath
   // /////////////////////////////////////////////////////////////////////


   // ///////////////////////////////////////////////////////////////////
   // 4X4 block Position Register
   // use reset_pos_s1 to initialize prev_pos_s2 to be 4'b1111
   // so why initialize prev_pos_s2 to 15? because position_s2 always
   // add 1 even if run_length_s1 is zero.
   // position_s2 is calculated from prev_pos_s1+run_length_s1+1
   // //////////////////////////////////////////////////////////////////

   always @(phi1 or curr_pos_s1 or prev_pos_s1 or match_del_s1)
     if (phi1)
       begin
          if (match_del_s1)
            position_s2=curr_pos_s1;
          else
            position_s2=prev_pos_s1;
       end

   always @(phi2 or position_s2 or reset_pos_s2)
     if (phi2)
       if (reset_pos_s2==1'b1)
         prev_pos_s1=4'b1111;
       else
         prev_pos_s1=position_s2;

   always @(phi2 or run_length_s2)
     if (phi2)
       run_length_s1=run_length_s2;

   assign  curr_pos_s1={2'b0,run_length_s1}+4'b1+prev_pos_s1;

   // ///////////////////////////////////////////////////////////////////////
   // Coeff_size counter
   // coeff_size_s2 muxed into cntr_in_s1, then decremented until cntr_s2=0
   // when cntr_s2=0, then valid_s2=1
   // muxsel_s2 selects coeff_size_s2 or cntr_s2
   // reset_s1 initialize cntr registers from X's
   // //////////////////////////////////////////////////////////////////////
   
   assign  muxsel_s1=(curr_state_s1[4:3]==2'b11 & match_s1==1'b1 ) ? 1'b1 : 1'b0;

   always @(phi1 or muxsel_s1)
     if (phi1)
       muxsel_s2=muxsel_s1;

   always @(phi2 or coeff_size_s2 or cntr_s2 or muxsel_s2)
     if (phi2)
       begin
          if (muxsel_s2)
            cntr_in_s1=coeff_size_s2;
          else
            cntr_in_s1=cntr_s2;
       end

   assign  cntr_s1=cntr_in_s1-4'b1;

   always @(phi1 or cntr_s1 or reset_s1)
     if (phi1)
       if (reset_s1)
         cntr_s2=4'b0;
       else
         cntr_s2=cntr_s1;

   // /////////////////////////////////////////////////////////////////////
   // generate corresponding s1 and s2 signals because they are needed
   // in controller
   // /////////////////////////////////////////////////////////////////////

   always @(phi1 or match_s1 or curr_state_s1)
     if (phi1)
       match_del_s2 = match_s1 & curr_state_s1[3];

   always @(phi2 or match_del_s2)
     if (phi2)
       match_del_s1 = match_del_s2;

   always @(phi1 or match_s1)
     if (phi1)
       match_s2=match_s1;

   always @(phi2 or reset_sr_s2)
     if (phi2)
       reset_sr_s1=reset_sr_s2;

   always @(phi1 or curr_state_s1)
     if (phi1)
       curr_state_s2 = curr_state_s1;

   always @(phi1 or reset_s1)
     if (phi1)
       reset_s2=reset_s1;

   always @(phi2 or valid_s2)
     if (phi2)
       valid_s1=valid_s2;

   always @(phi2 or coeff_size_s2)
     if (phi2)
       coeff_size_s1=coeff_size_s2;

   always @(phi2 or position_s2)
     if (phi2)
       position_s1=position_s2;

   // ///////////////////////////////////////////////////////////////////////
   // Generate Control Signals high for 1 cycle only
   // ///////////////////////////////////////////////////////////////////////
   
   // reset_sr_s2=1 for 1 clock cycle only

   assign  reset_sr_s2 = curr_state_s2[3]==1'b1 ? reset_sr_tmp_s2 | init_sr_s2
           : valid_s2;  

   always @(phi1 or reset_sr_reset_s1 or reset_sr_ctrl_FSM_s1 or curr_state_s1 
            or next_state_s1)
     if (phi1)
       begin
          reset_sr_ctrl_s2=reset_sr_ctrl_FSM_s1;
          reset_sr_tmp_s2=reset_sr_ctrl_FSM_s1 & ~(reset_sr_reset_s1 & 
                                                   (curr_state_s1==next_state_s1));
       end

   always @(phi2 or reset_sr_ctrl_s2)
     if (phi2)
       begin
          if (reset_sr_ctrl_s2)
            reset_sr_reset_s1=1'b1;
          else
            reset_sr_reset_s1=1'b0;
       end

   // ///////////////////////////////////////////////////////////////////////
   // FSM
   // //////////////////////////////////////////////////////////////////////

   // FSM state registers
   // reset_control_s1 initialize state of FSM to idle
   // next_state_s1 is calculated from curr_state_s1 with combinational logic
   // next_state_s2 latches next_state_s1, 
   // and then curr_state_s1 latches next_state_s2

   always @(phi1 or next_state_s1 or reset_control_s1)
     if (phi1)
       if (reset_control_s1)
         next_state_s2=`idle;
       else
         next_state_s2=next_state_s1;

   always @(phi2 or next_state_s2 or reset_s2)
     if (phi2)
       if (reset_s2)
         curr_state_s1=`init;
       else
         curr_state_s1=next_state_s2;

   // ///////////////////////////////////////////////////////////////////
   // Combinational Logic for calculating next_state
   // ///////////////////////////////////////////////////////////////////

   // Fill in the combinational logic for the FSM HERE

   always @(next_state_s1 or curr_state_s1 or match_s1 or reset_s1 or valid_s1 or coeff_size_s1 or match_del_s1 or reset_sr_s1 or position_s1)
     begin
        case(curr_state_s1)
            `idle: if (reset_s1 == 1'b1)
                        next_state_s1 = `init;
                   else
                        next_state_s1 = `idle;
            `init:  if (reset_s1 == 1'b0)
                       next_state_s1 = `dc_decode;
                    else
                       next_state_s1 = `init;
            `dc_decode: if (match_s1 == 1'b1 && reset_sr_s1 == 1'b0)
                            next_state_s1 = `dc_coeff;
                        else
                            next_state_s1 = `dc_decode;
            `dc_coeff: if (valid_s1 == 1'b1 || coeff_size_s1 == 4'b0000 && match_del_s1 == 1'b1)
                            next_state_s1 = `ac_decode;
                       else
                            next_state_s1 = `dc_coeff;
            `ac_decode: if (match_s1 == 1'b1 && reset_sr_s1 == 1'b0)
                            next_state_s1 = `ac_coeff;
                        else
                            next_state_s1 = `ac_decode;
            `ac_coeff: if ((valid_s1 == 1'b1 && position_s1 == 4'b1111) || position_s1 == 4'b1111)
                            next_state_s1 = `dc_decode;
                       else if ((valid_s1 == 1'b1 || coeff_size_s1 == 4'b0000 && match_del_s1 == 1'b1) && position_s1 != 4'b1111)
                            next_state_s1 = `ac_decode;
                       else
                            next_state_s1 = `ac_coeff;
            default: next_state_s1 = `idle;
        endcase
     end     
   // End of logic for FSM


   // /////////////////////////////////////////////////////////////////////
   // Combinational Logic to generate some control signals based on 
   // state of the controller
   // ////////////////////////////////////////////////////////////////////

   assign  reset_sr_ctrl_FSM_s1    = next_state_s1[4];
   assign  count_in_ctrl_FSM_s1    = next_state_s1[3];
   assign  reset_pos_s1        = next_state_s1[2];
   assign  dc_ac_en_s1             = next_state_s1[1];
   assign  dc_ac_ctrl_s1           = next_state_s1[0];

   always @(phi1 or reset_pos_s1)
     if (phi1)
       reset_pos_s2 = reset_pos_s1;

   always @(phi1 or count_in_ctrl_FSM_s1)
     if (phi1)
       coefftmp_en_b_s2 = count_in_ctrl_FSM_s1;

   assign  coeff_en_b_s2 = valid_s2 | coefftmp_en_b_s2 | 
           (~|coeff_size_s2);

   assign  dc_ac_s1=dc_ac_en_s1 ? dc_ac_ctrl_s1 : init_dc_ac_s1;

   // Indicates next 4X4 block when reset position=1 and match=1

   always @(phi2 or reset_sr_s2)
     if (phi2)
       reset_sr_del_s1 = reset_sr_s2;

   always @(phi1 or reset_sr_del_s1)
     if (phi1)
       reset_sr_del_s2 = reset_sr_del_s1;

   assign  new_block_s2 = reset_sr_del_s2 & reset_pos_s2;

   // Combinational Logic to generate valid_s2 signal to indicate the
   // coefficient is valid

   assign  valid_s2= (~|cntr_s2) & ~(curr_state_s2[3]) &
           ~reset_s2;  // NOR gate 
   // (zero detector)

endmodule
