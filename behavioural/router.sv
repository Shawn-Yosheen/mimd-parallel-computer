// Router v0.4 ,4 connection router make no decision
// Author:Yuxuan Zhang
//  ECS, University of Soutampton

module router #(
  parameter DATA_WIDTH=32, MAX_PACKET_LEN=8, NET_ADDR=4, 
  parameter ADDRX = 0, ADDRY = 0
)(
  input Clock,
  input nReset,

  // input Channel buffer
  input  logic S_Req_XP, S_Req_XN, S_Req_YP, S_Req_YN, S_Req_PE,
  output logic S_Ack_XP, S_Ack_XN, S_Ack_YP, S_Ack_YN, S_Ack_PE, 
  input [DATA_WIDTH-1:0] S_Data_XP, S_Data_XN, S_Data_YP, S_Data_YN, S_Data_PE,

  // output interface
  output logic M_Req_XP, M_Req_XN, M_Req_YP, M_Req_YN, M_Req_PE, 
  input  logic M_Ack_XP, M_Ack_XN, M_Ack_YP, M_Ack_YN, M_Ack_PE, 
  output logic [DATA_WIDTH-1:0] M_Data_XP, M_Data_XN, M_Data_YP, M_Data_YN, M_Data_PE, 

  // credit flow control
  // not used by now
  output logic S_Credit_PE, S_Credit_Re,
  input  logic M_Credit_PE, M_Credit_Re
  );

timeunit 1ns;
timeprecision 100ps;

  // Parameter to calculate LEN_WIDTH
  localparam LEN_WIDTH = $clog2(MAX_PACKET_LEN) + 2;
  // Channel remaining packet
    // max number of length is 2^(MAX_PACKET_LEN), so bits of
    // remain_packet +1 here
  //logic [$clog2(LEN_WIDTH)-1:0] remain_packet_PE, remain_packet_Re;

  ////////////////////////
  //internal value define
  ////////////////////////

  // packet destination address
  logic [3:0] Des_Addr_XP, Des_Addr_XN, Des_Addr_YP, Des_Addr_YN, Des_Addr_PE;

  // packet destination address
  // output interface
  wire Ch_M_Req_XP, Ch_M_Req_XN, Ch_M_Req_YP, Ch_M_Req_YN, Ch_M_Req_PE;
  wire Ch_Ack_XP, Ch_Ack_XN, Ch_Ack_YP, Ch_Ack_YN, Ch_Ack_PE;
  wire [DATA_WIDTH-1:0] Ch_Data_XP, Ch_Data_XN, Ch_Data_YP, Ch_Data_YN, Ch_Data_PE;

  // packet length and out ptr for each multiplexer
  logic [7:0] Ctr_XP, Ctr_XN, Ctr_YP, Ctr_YN, Ctr_PE;
  // out ptr for each buffer
  logic [7:0] Ptr_XP, Ptr_XN, Ptr_YP, Ptr_YN, Ptr_PE;

  ////////////////////////
  //instance buffer here
  ////////////////////////

  packet_buffer #( 
    .DATA_WIDTH(DATA_WIDTH), 
    .MAX_PACKET_LEN(MAX_PACKET_LEN), 
    .NET_ADDR(NET_ADDR)
    ) buffer_XP (
      .Clock(Clock), .nReset(nReset), 
      .S_Req(S_Req_XP), .S_Ack(S_Ack_XP), .S_Data(S_Data_XP),
      .M_Req(Ch_M_Req_XP), .M_Ack(Ch_Ack_XP), .M_Data(Ch_Data_XP),
	    .Des_Addr(Des_Addr_XP), .Src_Addr( ),
      .Packet_Len(Ctr_XP), .Out_ptr(Ptr_XP)
      );
  
  packet_buffer #( 
    .DATA_WIDTH(DATA_WIDTH), 
    .MAX_PACKET_LEN(MAX_PACKET_LEN), 
    .NET_ADDR(NET_ADDR)
    ) buffer_XN (
      .Clock(Clock), .nReset(nReset), 
      .S_Req(S_Req_XN), .S_Ack(S_Ack_XN), .S_Data(S_Data_XN),
      .M_Req(Ch_M_Req_XN), .M_Ack(Ch_Ack_XN), .M_Data(Ch_Data_XN),
	    .Des_Addr(Des_Addr_XN), .Src_Addr( ),
      .Packet_Len(Ctr_XN), .Out_ptr(Ptr_XN)
      );

  packet_buffer #( 
    .DATA_WIDTH(DATA_WIDTH), 
    .MAX_PACKET_LEN(MAX_PACKET_LEN), 
    .NET_ADDR(NET_ADDR)
    ) buffer_YP (
      .Clock(Clock), .nReset(nReset), 
      .S_Req(S_Req_YP), .S_Ack(S_Ack_YP), .S_Data(S_Data_YP),
      .M_Req(Ch_M_Req_YP), .M_Ack(Ch_Ack_YP), .M_Data(Ch_Data_YP),
	    .Des_Addr(Des_Addr_YP), .Src_Addr( ),
      .Packet_Len(Ctr_YP), .Out_ptr(Ptr_YP)
      );

  packet_buffer #( 
    .DATA_WIDTH(DATA_WIDTH), 
    .MAX_PACKET_LEN(MAX_PACKET_LEN), 
    .NET_ADDR(NET_ADDR)
    ) buffer_YN (
      .Clock(Clock), .nReset(nReset), 
      .S_Req(S_Req_YN), .S_Ack(S_Ack_YN), .S_Data(S_Data_YN),
      .M_Req(Ch_M_Req_YN), .M_Ack(Ch_Ack_YN), .M_Data(Ch_Data_YN),
	    .Des_Addr(Des_Addr_YN), .Src_Addr( ),
      .Packet_Len(Ctr_YN), .Out_ptr(Ptr_YN)
      );

  packet_buffer #( 
    .DATA_WIDTH(DATA_WIDTH), 
    .MAX_PACKET_LEN(MAX_PACKET_LEN), 
    .NET_ADDR(NET_ADDR)
    ) buffer_PE (
      .Clock(Clock), .nReset(nReset), 
      .S_Req(S_Req_PE), .S_Ack(S_Ack_PE), .S_Data(S_Data_PE),
      .M_Req(Ch_M_Req_PE), .M_Ack(Ch_Ack_PE), .M_Data(Ch_Data_PE),
      .Des_Addr(Des_Addr_PE), .Src_Addr( ),
      .Packet_Len(Ctr_PE), .Out_ptr(Ptr_PE)
      );


  ///////////////////////////////
  // instance cross bar here
  ///////////////////////////////

  crossbar #(
  .DATA_WIDTH(), .MAX_PACKET_LEN(), .NET_ADDR(), 
  .ADDRX(ADDRX), .ADDRY(ADDRY)
  ) bar_ins(
  .Clock(Clock),
  .nReset(nReset), 
  // slave interface
  .Ch_M_Req_XP(Ch_M_Req_XP), .Ch_M_Req_XN(Ch_M_Req_XN), .Ch_M_Req_YP(Ch_M_Req_YP), .Ch_M_Req_YN(Ch_M_Req_YN), .Ch_M_Req_PE(Ch_M_Req_PE), 
  .Ch_S_Req_XP(S_Req_XP), .Ch_S_Req_XN(S_Req_XN), .Ch_S_Req_YP(S_Req_YP), .Ch_S_Req_YN(S_Req_YN), .Ch_S_Req_PE(S_Req_PE), 
  .Ch_Ack_XP(Ch_Ack_XP), .Ch_Ack_XN(Ch_Ack_XN), .Ch_Ack_YP(Ch_Ack_YP), .Ch_Ack_YN(Ch_Ack_YN), .Ch_Ack_PE(Ch_Ack_PE), 
  .Ch_Data_XP(Ch_Data_XP), .Ch_Data_XN(Ch_Data_XN), .Ch_Data_YP(Ch_Data_YP), .Ch_Data_YN(Ch_Data_YN), .Ch_Data_PE(Ch_Data_PE), 
  // buffer destination address
  .Des_Addr_XP(Des_Addr_XP), .Des_Addr_XN(Des_Addr_XN), .Des_Addr_YP(Des_Addr_YP), .Des_Addr_YN(Des_Addr_YN), .Des_Addr_PE(Des_Addr_PE), 
  // buffer packet length and out pointer
  .Ctr_XP(Ctr_XP), .Ctr_XN(Ctr_XN), .Ctr_YP(Ctr_YP), .Ctr_YN(Ctr_YN), .Ctr_PE(Ctr_PE), 
  .Ptr_XP(Ptr_XP), .Ptr_XN(Ptr_XN), .Ptr_YP(Ptr_YP), .Ptr_YN(Ptr_YN), .Ptr_PE(Ptr_PE), 
  // master interface
  .M_Req_XP(M_Req_XP), .M_Req_XN(M_Req_XN), .M_Req_YP(M_Req_YP), .M_Req_YN(M_Req_YN), .M_Req_PE(M_Req_PE), 
  .M_Ack_XP(M_Ack_XP), .M_Ack_XN(M_Ack_XN), .M_Ack_YP(M_Ack_YP), .M_Ack_YN(M_Ack_YN), .M_Ack_PE(M_Ack_PE), 
  .M_Data_XP(M_Data_XP), .M_Data_XN(M_Data_XN), .M_Data_YP(M_Data_YP), .M_Data_YN(M_Data_YN), .M_Data_PE(M_Data_PE)
);

  
  
  ///////////////////////////////
  //calculate remain_packet here
  ///////////////////////////////

endmodule
