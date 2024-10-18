// tx interface v1.0
// Yuxuan Zhang
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing 10 write only register and 1 read only register
//
// Number of addressable locations : 11
// Size of each addressable location : 32 bits
// Supported transfer sizes : Word
// Alignment of base address : Word aligned
//
// Address map :
//   Base addess + 0 : 
//     Write Data[0] register
//   Base addess + 4 : 
//     Write Data[1] register
//   Base addess + 8 : 
//     Write Data[2] register
//   Base addess + 12 : 
//     Write Data[3] register
//   Base addess + 16 : 
//     Write Data[4] register
//   Base addess + 20 : 
//     Write Data[5] register
//   Base addess + 24 : 
//     Write Data[6] register
//   Base addess + 28 : 
//     Write Data[7] register
//
//   Base addess + 32 : 
//     Write Message Length register
//   Base addess + 36 : 
//     Write Destination Address register
//   Base addess + 40 : 
//     Write message type register
//
//   Base addess + 64 : 
//     Read status register
//
// Register Content:
//   Bits within Message Length register :
//     Bit [5:0]   Length of Byte
//       (from 1 Byte to 32 Byte)

//   Bits within Destination Address register :
//     Bit [3:2]   X location
//     Bit [1:0]   Y location
//
//   Bits within status register :
//     Bit 0   Busy
//       (when Busy asserted, tx is still transmitting data)
//       (when Busy == 0, new data can be written in)

// in software, when write the des_addr register, the tx_interface is triggered


module ahb_tx #( parameter X=0, Y=0  )(

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

  // input from ahb_mem
  input mem_valid,
  input logic [31:0] Mem_Addr, Mem_Data, 
  input [7:0] Mem_Des_Addr, Mem_Byte_Len, Mem_Mes_Type, 

  // output to network
  output logic M_Req,
  input M_Ack,
  output logic [31:0] M_Data

);

timeunit 1ns;
timeprecision 100ps;

  // AHB transfer codes needed in this module
  localparam No_Transfer = 2'b0;

  // control signals are stored in registers
  logic write_enable, read_enable;
  logic [4:0] word_address;

  // 8 bit length 32 bit width buffer
  logic [31:0] Tx_Data [7:0];

  // Message Length register and bits in it
  logic [31:0] Mes_Len;
  logic [7:0] Head_Byte_Len;
  logic [7:0] Packet_Len;
  logic [7:0] Cnt_Packet;

  // Destination Address register and bits in it
  logic [31:0] Des_Addr;
  logic [7:0] Head_Des_Addr;

  // source Address register from paramter X and Y
  logic [7:0] Head_Src_Addr;
  logic [1:0] Src_X, Src_Y;

  logic [7:0] Head_Mes_Type;

  // status register 
  logic [31:0] Status;
  logic Busy;

  // header contain Head_Des_Addr, Head_Src_Addr, Byte_Len for now
  logic [31:0] Header;

  // state machine viarables
  typedef enum logic [2:0] {T_IDLE, T_REQ, T_SEND, M_REQ, M_SEND} TX_state_type;
  TX_state_type TX_present_state, TX_next_state;

  // Generate the control signals in the address phase
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn )
      begin
        write_enable <= '0;
        read_enable  <= '0;
        word_address <= '0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        write_enable <= HWRITE;
        read_enable  <= ! HWRITE;
        word_address <= HADDR[6:2];
     end
    else
      begin
        write_enable <= '0;
        read_enable  <= '0;
        word_address <= '0;
     end

  //Act on control signals in the data phase

  // write
  // write Tx_Data[7:0]

  always_ff @(posedge HCLK)begin
		if( TX_present_state == M_REQ) begin
			Tx_Data[0] <= Mem_Addr;
			Tx_Data[1] <= Mem_Data;
		end
	else begin
    for ( int i=0; i<8; i++ ) begin
      if ( write_enable && ( word_address == i ) )
        Tx_Data[i] <= HWDATA;
    end
  end
  end


  // write Message Length, Destination Address register

  //define the bits in the Des_Addr and Mes_Len register
  assign Head_Des_Addr = (mem_valid && TX_present_state == T_IDLE) ? Mem_Des_Addr : Des_Addr[7:0];
  assign Head_Byte_Len = (mem_valid && TX_present_state == T_IDLE) ? Mem_Byte_Len : Mes_Len[7:0];
  assign Head_Mes_Type = Mem_Mes_Type;

  always_ff @(posedge HCLK, negedge HRESETn) begin
	if ( ! HRESETn ) begin
    Mes_Len <= '0;
		Des_Addr <= '0;
	end
	else if ( write_enable && ( word_address == 5'd8 ) )
   	Mes_Len <= HWDATA;
	else if ( write_enable && ( word_address == 5'd9 ) )
		Des_Addr <= HWDATA;
  end

  // define the bits in the status register
  assign Status = { 31'd0, Busy};

  //read
  always_comb
    if ( ! read_enable )
      // (output of zero when not enabled for read is not necessary
      //  but may help with debugging)
      HRDATA = '0;
    else
      case (word_address[4])
        1 : HRDATA = Status;
        // unused address - returns zero
        default : HRDATA = '0;
      endcase

  //Transfer Response
  assign HREADYOUT = 1; //Single cycle Write & Read. Zero Wait state operations

//////////////////////
//  output to network
//////////////////////

  // define Head_Src_Addr and Header
  always_comb begin
	Src_X = X;
	Src_Y = Y;
	Head_Src_Addr = {4'd0, Src_X, Src_Y};

	Header = { Head_Des_Addr, Head_Src_Addr, Head_Byte_Len, Head_Mes_Type};
  end

//////////////////////
// state machine
//////////////////////

  // next state
  always_ff @(posedge HCLK, negedge HRESETn)
	if ( ! HRESETn )
		TX_present_state <= T_IDLE;
	else
		TX_present_state <= TX_next_state;

  // next state
  always_comb begin
	Busy = 0;
	M_Req = 0;
	M_Data = '0;
	TX_next_state = T_IDLE;
	case(TX_present_state)
	T_IDLE: begin
		if(mem_valid)
			TX_next_state = M_REQ;
		else if(write_enable && word_address == 5'd9)
			TX_next_state = T_REQ;
		else
			TX_next_state = T_IDLE;
	end
	T_REQ: begin
		Busy = 1;
		M_Req = 1;
		//head build in T_REQ state
		M_Data = Header;
		if(M_Ack)
			TX_next_state = T_SEND;
		else
			TX_next_state = T_REQ;
	end
	T_SEND: begin
		Busy = 1;
		M_Data = Tx_Data [Cnt_Packet];
		if( Cnt_Packet < Packet_Len-1 )
			TX_next_state = T_SEND;
		else
			TX_next_state = T_IDLE;
	end
	M_REQ: begin
		Busy = 1;
		M_Req = 1;
		M_Data = Header;
		if(M_Ack)
			TX_next_state = M_SEND;
		else
			TX_next_state = M_REQ;
	end
	M_SEND: begin
		Busy = 1;
		M_Data = Tx_Data [Cnt_Packet];
		if( Cnt_Packet < Packet_Len-1 )
			TX_next_state = M_SEND;
		else
			TX_next_state = T_IDLE;
	end
	endcase
  end

  // register
  always_ff @(posedge HCLK, negedge HRESETn)
	if ( ! HRESETn ) begin
		Cnt_Packet <= '0;
		Packet_Len <= '0;
	end
	else if(TX_present_state == T_IDLE) begin
		Cnt_Packet <= '0;
		Packet_Len <= '0;
	end
	else if(TX_present_state == T_REQ || TX_present_state == M_REQ) begin
		Packet_Len <= (Head_Byte_Len >> 2);
	end
	else if(TX_present_state == T_SEND || TX_present_state == M_REQ) begin
		Cnt_Packet <= Cnt_Packet + 1;
	end

endmodule

