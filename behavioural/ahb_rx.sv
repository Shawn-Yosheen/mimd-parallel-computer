//  rx interface v1.0
//  written by Yuxuan Zhang
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing 10 read-only register 
//
// Number of addressable locations : 10
// Size of each addressable location : 32 bits
// Supported transfer sizes : Word
// Alignment of base address : Word aligned
//
// Address map :
//   Base addess + 0 : 
//     Read Data[0] register
//   Base addess + 4 : 
//     Read Data[1] register
//   Base addess + 8 : 
//     Read Data[2] register
//   Base addess + 12 : 
//     Read Data[3] register
//   Base addess + 16 : 
//     Read Data[4] register
//   Base addess + 20 : 
//     Read Data[5] register
//   Base addess + 24 : 
//     Read Data[6] register
//   Base addess + 28 : 
//     Read Data[7] register
//
//   Base addess + 32 : 
//     Read Message Length register
//   Base addess + 36 : 
//     Read Source Address register
//
//   Base addess + 64 : 
//     Read status register
//
// Register Content:
//   Bits within Message Length register :
//     Bit [5:0]   Length of Byte
//       (from 0 Byte to 32 Byte)

//   Bits within Source Address register :
//     Bit [3:2]   X location
//     Bit [1:0]   Y location
//
//   Bits within status register :
//     Bit 0	   Done
//
//   unaddresable register
//     [7:0]   Data_Valid
//       (when Data_Valid[i] asserted, Data[i] has new data )
//       (Data_Valid[i] is set to 0 by hardware after read Data[i])
//       (when all valid data is read by master, rx can accept new data )


module ahb_rx (

  // AHB Global Signals
  input HCLK,
  input HRESETn,

  // AHB Signals from Master to Slave
  input [31:0] HADDR, // With this interface only HADDR[6:2] is used (other bits are ignored)
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
  output logic S_Ack,
  input [31:0] S_Data,
  input S_Req

);

timeunit 1ns;
timeprecision 100ps;

  // AHB transfer codes needed in this module
  localparam No_Transfer = 2'b0;

  //control signals are stored in registers
  logic read_enable;
  logic [4:0] word_address;

  // 8 bit length 32 bit width buffer
  logic [31:0] Rx_Data [7:0];
 
  // Message Length register
  logic [31:0] Mes_Len;
  // bits in the Mes_Len register
  logic [7:0] Byte_Len_reg;
  // bits in header
  logic [7:0] Head_Byte_Len;
  // total flit length
  logic [7:0] Packet_Len;
  // flit left to receive
  logic [7:0] read_ptr;

  // destination address register
  // bits in the header
  logic [7:0] Head_Des_Addr;

  // source address register
  logic [31:0] Src_Addr;
  logic [7:0] Head_Src_Addr;
  logic [7:0] Src_Addr_reg;

  logic [31:0] Header;

  //status register and bits in it
  logic [31:0] Status;
  logic Done;

  // after receive all data, when Data_Valid==0, all data are read by msater
  logic [7:0] Data_Valid;

  //state machine viarables
  typedef enum logic [2:0] {IDLE, EMPTY, RECEIVE, DONE} RX_state_type;
  RX_state_type RX_present_state, RX_next_state;

  //Generate the control signals in the address phase
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn )
      begin
        read_enable <= '0;
        word_address <= '0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        read_enable <= ! HWRITE;
        word_address <= HADDR[6:2];
     end
    else
      begin
        read_enable <= '0;
        word_address <= '0;
     end

  //Act on control signals in the data phase

  // define the bits in the status register
  assign Mes_Len = {24'd0, Byte_Len_reg};
  assign Src_Addr = {24'd0, Src_Addr_reg};
  assign Status = { 31'd0, Done};

  //read

  always_comb
    if ( ! read_enable )
      // (output of zero when not enabled for read is not necessary
      //  but may help with debugging)
      HRDATA = '0;
    else
      case (word_address)
        5'd0 : HRDATA = Rx_Data[0];
        5'd1 : HRDATA = Rx_Data[1];
        5'd2 : HRDATA = Rx_Data[2];
        5'd3 : HRDATA = Rx_Data[3];
        5'd4 : HRDATA = Rx_Data[4];
        5'd5 : HRDATA = Rx_Data[5];
        5'd6 : HRDATA = Rx_Data[6];
        5'd7 : HRDATA = Rx_Data[7];
        5'd8 : HRDATA = Mes_Len;
        5'd9 : HRDATA = Src_Addr;
        5'd16: HRDATA = Status;
        // unused address - returns zero
        default : HRDATA = '0;
      endcase


  //Transfer Response
  assign HREADYOUT = 1; //Single cycle Write. Zero Wait state operations

///////////////////////
//  input from network
///////////////////////

  always_comb begin
	Head_Des_Addr = Header [31:24];
	Head_Src_Addr = Header [23:16];
	Head_Byte_Len = Header [15: 8];
  end

//////////////////////
// state machine
//////////////////////

  // next state
  always_ff @(posedge HCLK, negedge HRESETn)
	if ( ! HRESETn )
		RX_present_state <= IDLE;
	else
		RX_present_state <= RX_next_state;

  // next state
  always_comb begin
	Done = 0;
	S_Ack = 0;
	Header = 32'd0;
	RX_next_state = IDLE;
	case(RX_present_state)
	IDLE: begin
		Header = 32'd0;
		RX_next_state = EMPTY;
	end
	EMPTY: begin
		S_Ack = 1;
		Header = S_Data;
		if(S_Req)
			RX_next_state = RECEIVE;
		else
			RX_next_state = EMPTY;
	end
	RECEIVE: begin
		if( read_ptr < Packet_Len-1 )
			RX_next_state = RECEIVE;
		else
			RX_next_state = DONE;
	end
	DONE: begin
		Done = 1;
		if( Data_Valid == '0)
			RX_next_state = EMPTY;
		else
			RX_next_state = DONE;
	end
	endcase
  end

  // register
  always_ff @(posedge HCLK, negedge HRESETn) begin
	if ( ! HRESETn ) begin
		Byte_Len_reg <= '0;
		read_ptr <= '0;
		Packet_Len <= '0;
		Src_Addr_reg <= '0;
		Data_Valid <= '0;
	end
	else if(RX_present_state == IDLE) begin
		Byte_Len_reg <= '0;
		read_ptr <= '0;
		Packet_Len <= '0;
		Src_Addr_reg <= '0;
		Data_Valid <= '0;
	end
	else if(RX_present_state == EMPTY) begin
		read_ptr <= '0;
		if(S_Req) begin
			Byte_Len_reg <= Head_Byte_Len;
			Packet_Len <= (Head_Byte_Len >> 2);
			Src_Addr_reg <= Head_Src_Addr;
		end
	end
	else if(RX_present_state == RECEIVE) begin
		// buffer input defines here
		Rx_Data[read_ptr] <= S_Data;

		//assume there is no block, data comes in continuously
		read_ptr <= read_ptr + 1;
		if(! (read_ptr < Packet_Len-1) ) begin
			Data_Valid <= (1 << Packet_Len) - 1;
		end
	end
	else if(RX_present_state == DONE) begin
		if( Data_Valid != '0 && read_enable && word_address >= 5'd0 && word_address <= 5'd7) begin
			Data_Valid[ word_address[2:0] ] <= 0;
			Rx_Data[word_address[2:0]] <= 0;
		end
	end
  end



endmodule
