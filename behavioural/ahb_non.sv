module ahb_non (
  // Transfer Response & Read Data
  output HREADYOUT,
  output [31:0] HRDATA

);

timeunit 1ns;
timeprecision 100ps;
    
  //read
  assign HRDATA = '0;

  //Transfer Response
  assign HREADYOUT = '1; //Single cycle Write & Read. Zero Wait state operations



endmodule
