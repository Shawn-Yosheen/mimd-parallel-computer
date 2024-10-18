// Example code for an AHBLite System-on-Chip
//  Iain McNally
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing a RAM
// Since this loads a program it is for FPGA use only
//
// Number of addressable locations : 2**MEMWIDTH
///////////////////
// VGA pixel logic
///////////////////
// total memory bits: 640 * 480 * 4 = 1,228,800
// half byte memory number: 640 * 480 = 307,200
// MEMWIDTH-2 == log2(307,200) == 18.2
// MEMWIDTH = 21

// for smaller size
// half byte memory number: 160 * 120 = 19,200
// MEMWIDTH-2 == log2(19,200) == 14.2
// MEMWIDTH = 17

// Size of each addressable location : 4 bits
// Supported transfer sizes : Half-Byte
// Alignment of base address : Word aligned
//

// Memory is synchronous which should suit block memory types
// Read and Write addresses are separate
//   (this supported by many FPGA block memories)
//

// This model is for Altera (Intel) FPGAs only
//   The RAM model has two dimensions
//   * This is the advised technique for byte access in Altera FPGAs
//   * This is not currently supported for block RAM in Xilinx FPGAs
//


module vga_ram #(
  parameter MEMWIDTH = 21
)(
  //AHBLITE INTERFACE

    //Slave Select Signal
    input HSEL,
    //Global Signals
    input HCLK,
    input HRESETn,
    //Address, Control & Write Data
    input HREADY,
    input [31:0] HADDR,
    input [1:0] HTRANS,
    input HWRITE,
    input [2:0] HSIZE,
    input [31:0] HWDATA,
    // Transfer Response & Read Data
    output HREADYOUT,
    output [31:0] HRDATA

);

timeunit 1ns;
timeprecision 100ps;

  localparam No_Transfer = 2'b0;

// Memory Array  
  logic [3:0]memory[0:(307200-1)];
  logic [31:0] data_from_memory;

//control signals are stored in registers
  logic write_enable, read_enable;
  logic [MEMWIDTH-3:0] write_address, read_address, saved_read_address;
 
//Generate the control signals and write_address in the address phase
  always_ff @(posedge HCLK, negedge HRESETn)
    if (! HRESETn )
      begin
        write_enable <= '0;
        read_enable <= '0;
        write_address <= '0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        write_enable <= HWRITE;
        read_enable <= ! HWRITE;
        if ( HWRITE ) write_address <= HADDR[MEMWIDTH-1:2];
      end
    else
      begin
        write_enable <= '0;
        read_enable <= '0;
      end

// read address is calculated a cycle earlier than write address
  always_comb
    if ( HREADY && HSEL && (HTRANS != No_Transfer) && ! HWRITE )
      read_address = HADDR[MEMWIDTH-1:2];
    else
      read_address = saved_read_address;

  always_ff @(posedge HCLK, negedge HRESETn)
    if (! HRESETn )
      saved_read_address <= '0;
    else
      saved_read_address <= read_address;
      
//Act on control signals in the data phase

  // This block models the RAM timing
  // Read and write are both synchronous
  // The code uses a standard format to ensure easy synthesis
  //
  // "New Data" Read-During-Write Behaviour:
  //  In this case we use blocking assignments in order to return new data
  //    if read and write addresses match
  //  This avoids a potential read-after-write data hazard
  //
  always_ff @(posedge HCLK) begin
    if ( write_enable ) memory[write_address] = HWDATA[ 3: 0];
    data_from_memory[3:0] = memory[read_address];
  end

  assign data_from_memory [31:4] = '0;
    
  //read
  // (output of zero when not enabled for read is not necessary but may help with debugging)
  assign HRDATA = ( read_enable ) ? data_from_memory : '0;

//Transfer Response
  assign HREADYOUT = '1; //Single cycle Write & Read. Zero Wait state operations

endmodule
