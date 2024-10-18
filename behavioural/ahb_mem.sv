// An memory interface for AHBLite System-on-Chip
// ahb2remote memoru interface v0.1
//  Yuxuan Zhang
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing 16 write only register
//
// Number of addressable locations : 16
// Size of each addressable location : 32 bits
// Supported transfer sizes : Word
// Alignment of base address : Word aligned
//
// Address map :
//   Base addess + 0 : 
//     Write (0,0) Data[0] register
//
//   Base addess + 0x0100_0000 : 
//     Write (0,1) Data[0] register
//
//   Base addess + 0x0200_0000 : 
//     Write (0,2) Data[0] register
//
//   Base addess + 0x0300_0000 : 
//     Write (0,3) Data[0] register
//
//   Base addess + 0x0400_0000 : 
//     Write (1,0) Data[0] register
//
//   Base addess + 0x0500_0000 : 
//     Write (1,1) Data[0] register
//
//   Base addess + 0x0600_0000 : 
//     Write (1,2) Data[0] register
//
//   Base addess + 0x0700_0000 : 
//     Write (1,3) Data[0] register
//
//   Base addess + 0x0800_0000 : 
//     Write (2,0) Data[0] register
//
//   Base addess + 0x0900_0000 : 
//     Write (2,1) Data[0] register
//
//   Base addess + 0x0A00_0000 : 
//     Write (2,2) Data[0] register
//
//   Base addess + 0x0B00_0000 : 
//     Write (2,3) Data[0] register
//
//   Base addess + 0x0C00_0000 : 
//     Write (3,0) Data[0] register
//
//   Base addess + 0x0D00_0000 : 
//     Write (3,1) Data[0] register
//
//   Base addess + 0x0E00_0000 : 
//     Write (3,2) Data[0] register
//
//   Base addess + 0x0F00_0000 : 
//     Write (3,3) Data[0] register
//

// if the master access remote memory addr, ahb_mem generate header to ahb_tx


module ahb_mem #(
  parameter ADDRX = 0, ADDRY = 0
)( 

  // AHB Global Signals
  input HCLK,
  input HRESETn,

  // AHB Signals from Master to Slave
  input [31:0] HADDR, // With this interface only HADDR[1] is used (other bits are ignored)
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
  output logic [31:0] Mem_Addr,
  output logic [31:0] Mem_Data,
  output logic [7:0] Des_Addr, Byte_Len, Mes_Type, 
	
	output logic valid
);

timeunit 1ns;
timeprecision 100ps;

  // AHB transfer codes needed in this module
  localparam No_Transfer = 2'b0;

  // control signals are stored in registers
  logic write_enable, read_enable;
  logic [3:0] word_address;

	// define temp_memory here
  logic [31:0]memory;

  // local Address register from paramter X and Y
  logic [1:0] local_X, local_Y;

  assign local_X = ADDRX;
  assign local_Y = ADDRY;
  assign local_address = {local_X, local_Y};

  //Generate the control signals in the address phase
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn )
      begin
        write_enable <= '0;
        read_enable <= '0;
        word_address <= '0;
				Byte_Len <= '0;
				Mes_Type <= '0;
				Des_Addr <= '0;
				Mem_Addr <= '0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        write_enable <= HWRITE;
        read_enable <= ! HWRITE;
        word_address <= HADDR[27:24];
				Byte_Len <= generate_byte_len( HSIZE );
				Mes_Type <= HWRITE ? 8'h1 : 8'h3;
				Des_Addr <= {4'd0, HADDR[27:24]};
				Mem_Addr <= HADDR;
     end
    else
      begin
        write_enable <= '0;
        read_enable <= '0;
        word_address <= '0;
     end

  //Act on control signals in the data phase

  // write
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn ) begin
			Mem_Data <= '0;
			valid <= 0;
		end
    else if ( write_enable &&  word_address == local_address )
        memory<= HWDATA;
    else if ( write_enable &&  word_address != local_address ) begin
			Mem_Data <= HWDATA;
			valid <= 1;
		end
		else begin
			valid <= 0;
		end

/*
  //read
  always_comb
    if ( ! read_enable )
      // (output of zero when not enabled for read is not necessary
      //  but may help with debugging)
      HRDATA = '0;
    else
      case (word_address)
        // ensure that half-word data is correctly aligned

        // unused address - returns zero
        default : HRDATA = '0;
      endcase
*/
  //Transfer Response
  assign HREADYOUT = '1; //Single cycle Write & Read. Zero Wait state operations

// decode byte select signals from the size and the lowest two address bits
  function logic [7:0] generate_byte_len( logic [2:0] size );
    logic [7:0] byte_len;
		byte_len = (HSIZE[1:0] == 2'b10) ? 8'd4 :
		           (HSIZE[1:0] == 2'b01) ? 8'd2 :
		           8'd1;
    return byte_len;
  endfunction


endmodule
