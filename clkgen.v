/////////////////////////////////////////////////////////////////////////////
module clkgen(phi1, phi2);
/////////////////////////////////////////////////////////////////////////////
  output        phi1,           // Two-phase non-overlapping clocks
                phi2;

  reg           phi1,
                phi2;
          // Start with both clocks low
  initial
    begin
      phi1 = 0;
      phi2 = 0;
    end

  // Generate two-phase non-overlapping clock waveforms
  always
    begin
      #100 phi1 = 0;
      #25  phi2 = 1;
      #100 phi2 = 0;
      #25  phi1 = 1;
    end            
endmodule


