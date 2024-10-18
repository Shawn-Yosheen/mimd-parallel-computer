// Network Node v0.1
// Author:Yuxuan Zhang
//  ECS, University of Soutampton
module node #(
  parameter DEBOUNCE_COUNT = 0, DATA_WIDTH=32, MAX_PACKET_LEN=8, NET_ADDR=4,
  parameter ADDRX = 0, ADDRY = 0,
  parameter USE_VGA_MEM = 0
)(

  input Clock, nReset,
  
  input [31:0] Switches, 
  input [1:0] Buttons, 

  output [31:0] DataOut,
  output logic DataValid,

  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6,  //Non-AHB Signals

  output LOCKUP,

  //communication signals
  input  logic S_Req_XP, S_Req_XN, S_Req_YP, S_Req_YN,
  output logic S_Ack_XP, S_Ack_XN, S_Ack_YP, S_Ack_YN, 
  input [31:0] S_Data_XP, S_Data_XN, S_Data_YP, S_Data_YN,

  output logic M_Req_XP, M_Req_XN, M_Req_YP, M_Req_YN, 
  input  logic M_Ack_XP, M_Ack_XN, M_Ack_YP, M_Ack_YN, 
  output logic [31:0] M_Data_XP, M_Data_XN, M_Data_YP, M_Data_YN

);
 
timeunit 1ns;
timeprecision 100ps;

  wire M_Req_PE, M_Ack_PE;
  wire [DATA_WIDTH-1:0] M_Data_PE;

  wire S_Req_PE, S_Ack_PE;
  wire [DATA_WIDTH-1:0] S_Data_PE;

  soc #( 
  .ADDRX(ADDRX), .ADDRY(ADDRY), .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .USE_VGA_MEM(USE_VGA_MEM)
) soc_ins (

  .HCLK(Clock), .HRESETn(nReset), 

  .Switches(Switches), .Buttons(Buttons), .DataOut(DataOut), .DataValid(DataValid),
  .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6),

  .LOCKUP(LOCKUP),

  .S_Req(M_Req_PE), .S_Ack(M_Ack_PE), .S_Data(M_Data_PE),
  .M_Req(S_Req_PE), .M_Ack(S_Ack_PE), .M_Data(S_Data_PE),

  .Addr_X( ), .Addr_Y( )

);

  router #( 
  .ADDRX(ADDRX), .ADDRY(ADDRY),
  .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR)
) ro_ins (

  .Clock(Clock), .nReset(nReset),

  .S_Req_XP(S_Req_XP), .S_Req_XN(S_Req_XN), .S_Req_YP(S_Req_YP), .S_Req_YN(S_Req_YN), .S_Req_PE(S_Req_PE), 
  .S_Ack_XP(S_Ack_XP), .S_Ack_XN(S_Ack_XN), .S_Ack_YP(S_Ack_YP), .S_Ack_YN(S_Ack_YN), .S_Ack_PE(S_Ack_PE), 
  .S_Data_XP(S_Data_XP), .S_Data_XN(S_Data_XN), .S_Data_YP(S_Data_YP), .S_Data_YN(S_Data_YN), .S_Data_PE(S_Data_PE), 

  .M_Req_XP(M_Req_XP), .M_Req_XN(M_Req_XN), .M_Req_YP(M_Req_YP), .M_Req_YN(M_Req_YN), .M_Req_PE(M_Req_PE), 
  .M_Ack_XP(M_Ack_XP), .M_Ack_XN(M_Ack_XN), .M_Ack_YP(M_Ack_YP), .M_Ack_YN(M_Ack_YN), .M_Ack_PE(M_Ack_PE), 
  .M_Data_XP(M_Data_XP), .M_Data_XN(M_Data_XN), .M_Data_YP(M_Data_YP), .M_Data_YN(M_Data_YN), .M_Data_PE(M_Data_PE),

  // not used by now
  .S_Credit_PE(), .S_Credit_Re(),
  .M_Credit_PE(), .M_Credit_Re()
  );

endmodule
