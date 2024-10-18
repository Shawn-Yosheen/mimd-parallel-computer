// Example code for an AHBLite System-on-Chip
//  Iain McNally
//  ECS, University of Soutampton
//
// This module is a wrapper allowing the system to be used on the DE2 FPGA board
//   (this should also work on the newer DE2-115 board 10/22/2020)
//

module de2_wrapper(

  input CLOCK_50,
  
  input [15:0] SW, 
  input [2:0] KEY, // DE2 keys are active low

  output [15:0] LEDR,
  output [6:0] HEX0,
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5,
  output [6:0] HEX6,
  output [6:0] HEX7

);

timeunit 1ns;
timeprecision 100ps;

  localparam heartbeat_count_msb = 25; 

  localparam seven_seg_L = ~7'b0111000; 
  localparam seven_seg_E = ~7'b1111001; 
  localparam seven_seg_o = ~7'b1011100; 
  localparam seven_seg_off = ~7'b0000000; 
  
  
  wire HCLK, HRESETn, LOCKUP, DataValid;
  wire [1:0] Buttons;
  wire [31:0] Switches;
  wire [31:0] LED;

  assign LOCKUP = 0;

  assign LEDR = LED[15:0];

  assign Switches = { 14'd0, SW }; // DE2 has more than 16 switches
  
  assign Buttons = ~KEY[1:0];
//.DEBOUNCE_COUNT(1250000)
noc #(
  .DEBOUNCE_COUNT(1250000)
) noc_ins (
  .Clock(HCLK), .nReset(HRESETn),
  .Buttons(Buttons), 
  .Switches(Switches), 
  .DataOut( LED ), .DataValid(DataValid),
  .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6)
);
     
  // Drive HRESETn directly from active low CPU KEY[2] button
  assign HRESETn = KEY[2];

  // Drive HCLK from 50MHz de0 board clock
  assign HCLK = CLOCK_50;



  // This code gives us a heartbeat signal
  //
  logic running, heartbeat;
  logic [heartbeat_count_msb:0] tick_count;
  always_ff @(posedge CLOCK_50, negedge HRESETn )
    if ( ! HRESETn )
      begin
        running <= 0;
        heartbeat <= 0;
        tick_count <= 0;
      end
    else
      begin
        running <= 1;
        heartbeat = tick_count[heartbeat_count_msb] && tick_count[heartbeat_count_msb-2];
        tick_count <= tick_count + 1;
      end

  // HEX0 is status/heartbeat
  assign HEX7 = (LOCKUP) ? seven_seg_L : (!DataValid) ? seven_seg_E : (heartbeat) ? seven_seg_o : seven_seg_off;


endmodule