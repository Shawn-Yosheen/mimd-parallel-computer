// identifier to identify different C code and output X,Y location to router
//  Yuxuan Zhang
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing 2 read-only locations
//
// Number of addressable locations : 2
// Size of each addressable location : 32 bits
// Supported transfer sizes : Word
// Alignment of base address : Word aligned
//
// Address map :
//   Base addess + 0 : 
//     Read PE Addr_XY register
//
// Bits within Addr_XY register :
//   Bit [1:0]   Addr of Y
//   Bit [3:2]   Addr of X


module ahb_id #( parameter X=0, Y=0  )(

  // AHB Global Signals
  input HCLK,
  input HRESETn,

  // AHB Signals from Master to Slave
  input [31:0] HADDR, //in this design, HADDR is ignored
  input [31:0] HWDATA,
  input [2:0] HSIZE,
  input [1:0] HTRANS,
  input HWRITE,
  input HREADY,
  input HSEL,

  // AHB Signals from Slave to Master
  output logic [31:0] HRDATA,
  output HREADYOUT,

  //Non-AHB Signals
  output logic [1:0] Addr_X, Addr_Y

);

timeunit 1ns;
timeprecision 100ps;

  // AHB transfer codes needed in this module
  localparam No_Transfer = 2'b0;

  //control signals are stored in registers
  logic read_enable;
  logic write_enable;
 
  logic [31:0] Addr_XY;

  // output addr assignments 
  assign Addr_X = X;
  assign Addr_Y = Y;
  // register assignments
  assign Addr_XY = {28'b0, Addr_X, Addr_Y};

  //Generate the control signals in the address phase
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn )
        read_enable <= '0;
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
        read_enable <= ! HWRITE;
    else
        read_enable <= '0;


  //read
  always_comb
    if ( ! read_enable )
      // (output of zero when not enabled for read is not necessary
      //  but may help with debugging)
      HRDATA = '0;
    else
      HRDATA = Addr_XY;

  //Transfer Response
  assign HREADYOUT = '1; //Single cycle Write & Read. Zero Wait state operations



endmodule
