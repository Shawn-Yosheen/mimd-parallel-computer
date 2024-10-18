module noc #(
  parameter DEBOUNCE_COUNT = 0, DATA_WIDTH=32, MAX_PACKET_LEN=8, NET_ADDR=4
)(

  input Clock, nReset,
  
  input [31:0] Switches, 
  input [1:0] Buttons, 

  output [31:0] DataOut,
  output logic DataValid,

  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6

);
     
timeunit 1ns;
timeprecision 100ps;



  wire LOCKUP00, LOCKUP01, LOCKUP10, LOCKUP11;

  //communication signals
  //ahb_rx
  logic S_Req_00_10, S_Req_10_20, S_Req_20_30, S_Req_00_01, S_Req_01_02, S_Req_02_03;
  logic S_Req_01_11, S_Req_11_21, S_Req_21_31, S_Req_10_11, S_Req_11_12, S_Req_12_13;
  logic S_Req_02_12, S_Req_12_22, S_Req_22_32, S_Req_20_21, S_Req_21_22, S_Req_22_23;
  logic S_Req_03_13, S_Req_13_23, S_Req_23_33, S_Req_30_31, S_Req_31_32, S_Req_32_33;

  logic S_Ack_00_10, S_Ack_10_20, S_Ack_20_30, S_Ack_00_01, S_Ack_01_02, S_Ack_02_03;
  logic S_Ack_01_11, S_Ack_11_21, S_Ack_21_31, S_Ack_10_11, S_Ack_11_12, S_Ack_12_13;
  logic S_Ack_02_12, S_Ack_12_22, S_Ack_22_32, S_Ack_20_21, S_Ack_21_22, S_Ack_22_23;
  logic S_Ack_03_13, S_Ack_13_23, S_Ack_23_33, S_Ack_30_31, S_Ack_31_32, S_Ack_32_33;

  logic [31:0] S_Data_00_10, S_Data_10_20, S_Data_20_30, S_Data_00_01, S_Data_01_02, S_Data_02_03;
  logic [31:0] S_Data_01_11, S_Data_11_21, S_Data_21_31, S_Data_10_11, S_Data_11_12, S_Data_12_13;
  logic [31:0] S_Data_02_12, S_Data_12_22, S_Data_22_32, S_Data_20_21, S_Data_21_22, S_Data_22_23;
  logic [31:0] S_Data_03_13, S_Data_13_23, S_Data_23_33, S_Data_30_31, S_Data_31_32, S_Data_32_33;

  //ahb_tx
  logic M_Req_00_10, M_Req_10_20, M_Req_20_30, M_Req_00_01, M_Req_01_02, M_Req_02_03;
  logic M_Req_01_11, M_Req_11_21, M_Req_21_31, M_Req_10_11, M_Req_11_12, M_Req_12_13;
  logic M_Req_02_12, M_Req_12_22, M_Req_22_32, M_Req_20_21, M_Req_21_22, M_Req_22_23;
  logic M_Req_03_13, M_Req_13_23, M_Req_23_33, M_Req_30_31, M_Req_31_32, M_Req_32_33;

  logic M_Ack_00_10, M_Ack_10_20, M_Ack_20_30, M_Ack_00_01, M_Ack_01_02, M_Ack_02_03;
  logic M_Ack_01_11, M_Ack_11_21, M_Ack_21_31, M_Ack_10_11, M_Ack_11_12, M_Ack_12_13;
  logic M_Ack_02_12, M_Ack_12_22, M_Ack_22_32, M_Ack_20_21, M_Ack_21_22, M_Ack_22_23;
  logic M_Ack_03_13, M_Ack_13_23, M_Ack_23_33, M_Ack_30_31, M_Ack_31_32, M_Ack_32_33;

  logic [31:0] M_Data_00_10, M_Data_10_20, M_Data_20_30, M_Data_00_01, M_Data_01_02, M_Data_02_03;
  logic [31:0] M_Data_01_11, M_Data_11_21, M_Data_21_31, M_Data_10_11, M_Data_11_12, M_Data_12_13;
  logic [31:0] M_Data_02_12, M_Data_12_22, M_Data_22_32, M_Data_20_21, M_Data_21_22, M_Data_22_23;
  logic [31:0] M_Data_03_13, M_Data_13_23, M_Data_23_33, M_Data_30_31, M_Data_31_32, M_Data_32_33;

  // buttons and ledout
  logic [1:0] Buttons_SW, Buttons_OUT;
  assign Buttons_SW = {1'b0, Buttons[0]};
  assign Buttons_OUT = {Buttons[1], 1'b0};

node #(
  .ADDRX (0), .ADDRY(0),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_00(
  .Clock(Clock), .nReset(nReset),
  .Switches(Switches), .Buttons(Buttons_SW), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_00_10), .S_Ack_XP(S_Ack_00_10), .S_Data_XP(S_Data_00_10),
  .M_Req_XP(M_Req_00_10), .M_Ack_XP(M_Ack_00_10), .M_Data_XP(M_Data_00_10),
  .S_Req_XN( ), .S_Ack_XN( ), .S_Data_XN( ),
  .M_Req_XN( ), .M_Ack_XN( ), .M_Data_XN( ),
  .S_Req_YP(S_Req_00_01), .S_Ack_YP(S_Ack_00_01), .S_Data_YP(S_Data_00_01),
  .M_Req_YP(M_Req_00_01), .M_Ack_YP(M_Ack_00_01), .M_Data_YP(M_Data_00_01),
  .S_Req_YN( ), .S_Ack_YN( ), .S_Data_YN( ),
  .M_Req_YN( ), .M_Ack_YN( ), .M_Data_YN( )

);

node #(
  .ADDRX (1), .ADDRY(0),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_10(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_10_20), .S_Ack_XP(S_Ack_10_20), .S_Data_XP(S_Data_10_20),
  .M_Req_XP(M_Req_10_20), .M_Ack_XP(M_Ack_10_20), .M_Data_XP(M_Data_10_20),
  .S_Req_XN(M_Req_00_10), .S_Ack_XN(M_Ack_00_10), .S_Data_XN(M_Data_00_10),
  .M_Req_XN(S_Req_00_10), .M_Ack_XN(S_Ack_00_10), .M_Data_XN(S_Data_00_10),
  .S_Req_YP(S_Req_10_11), .S_Ack_YP(S_Ack_10_11), .S_Data_YP(S_Data_10_11),
  .M_Req_YP(M_Req_10_11), .M_Ack_YP(M_Ack_10_11), .M_Data_YP(M_Data_10_11),
  .S_Req_YN( ), .S_Ack_YN( ), .S_Data_YN( ),
  .M_Req_YN( ), .M_Ack_YN( ), .M_Data_YN( )

);

node #(
  .ADDRX (2), .ADDRY(0),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_20(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_20_30), .S_Ack_XP(S_Ack_20_30), .S_Data_XP(S_Data_20_30),
  .M_Req_XP(M_Req_20_30), .M_Ack_XP(M_Ack_20_30), .M_Data_XP(M_Data_20_30),
  .S_Req_XN(M_Req_10_20), .S_Ack_XN(M_Ack_10_20), .S_Data_XN(M_Data_10_20),
  .M_Req_XN(S_Req_10_20), .M_Ack_XN(S_Ack_10_20), .M_Data_XN(S_Data_10_20),
  .S_Req_YP(S_Req_20_21), .S_Ack_YP(S_Ack_20_21), .S_Data_YP(S_Data_20_21),
  .M_Req_YP(M_Req_20_21), .M_Ack_YP(M_Ack_20_21), .M_Data_YP(M_Data_20_21),
  .S_Req_YN( ), .S_Ack_YN( ), .S_Data_YN( ),
  .M_Req_YN( ), .M_Ack_YN( ), .M_Data_YN( )

);

node #(
  .ADDRX (3), .ADDRY(0),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_30(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP( ), .S_Ack_XP( ), .S_Data_XP( ),
  .M_Req_XP( ), .M_Ack_XP( ), .M_Data_XP( ),
  .S_Req_XN(M_Req_20_30), .S_Ack_XN(M_Ack_20_30), .S_Data_XN(M_Data_20_30),
  .M_Req_XN(S_Req_20_30), .M_Ack_XN(S_Ack_20_30), .M_Data_XN(S_Data_20_30),
  .S_Req_YP(S_Req_30_31), .S_Ack_YP(S_Ack_30_31), .S_Data_YP(S_Data_30_31),
  .M_Req_YP(M_Req_30_31), .M_Ack_YP(M_Ack_30_31), .M_Data_YP(M_Data_30_31),
  .S_Req_YN( ), .S_Ack_YN( ), .S_Data_YN( ),
  .M_Req_YN( ), .M_Ack_YN( ), .M_Data_YN( )

);

node #(
  .ADDRX (0), .ADDRY(1),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_01(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_01_11), .S_Ack_XP(S_Ack_01_11), .S_Data_XP(S_Data_01_11),
  .M_Req_XP(M_Req_01_11), .M_Ack_XP(M_Ack_01_11), .M_Data_XP(M_Data_01_11),
  .S_Req_XN( ), .S_Ack_XN( ), .S_Data_XN( ),
  .M_Req_XN( ), .M_Ack_XN( ), .M_Data_XN( ),
  .S_Req_YP(S_Req_01_02), .S_Ack_YP(S_Ack_01_02), .S_Data_YP(S_Data_01_02),
  .M_Req_YP(M_Req_01_02), .M_Ack_YP(M_Ack_01_02), .M_Data_YP(M_Data_01_02),
  .S_Req_YN(M_Req_00_01), .S_Ack_YN(M_Ack_00_01), .S_Data_YN(M_Data_00_01),
  .M_Req_YN(S_Req_00_01), .M_Ack_YN(S_Ack_00_01), .M_Data_YN(S_Data_00_01)

);

node #(
  .ADDRX (1), .ADDRY(1),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_11(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_11_21), .S_Ack_XP(S_Ack_11_21), .S_Data_XP(S_Data_11_21),
  .M_Req_XP(M_Req_11_21), .M_Ack_XP(M_Ack_11_21), .M_Data_XP(M_Data_11_21),
  .S_Req_XN(M_Req_01_11), .S_Ack_XN(M_Ack_01_11), .S_Data_XN(M_Data_01_11),
  .M_Req_XN(S_Req_01_11), .M_Ack_XN(S_Ack_01_11), .M_Data_XN(S_Data_01_11),
  .S_Req_YP(S_Req_11_12), .S_Ack_YP(S_Ack_11_12), .S_Data_YP(S_Data_11_12),
  .M_Req_YP(M_Req_11_12), .M_Ack_YP(M_Ack_11_12), .M_Data_YP(M_Data_11_12),
  .S_Req_YN(M_Req_10_11), .S_Ack_YN(M_Ack_10_11), .S_Data_YN(M_Data_10_11),
  .M_Req_YN(S_Req_10_11), .M_Ack_YN(S_Ack_10_11), .M_Data_YN(S_Data_10_11)

);

node #(
  .ADDRX (2), .ADDRY(1),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_21(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_21_31), .S_Ack_XP(S_Ack_21_31), .S_Data_XP(S_Data_21_31),
  .M_Req_XP(M_Req_21_31), .M_Ack_XP(M_Ack_21_31), .M_Data_XP(M_Data_21_31),
  .S_Req_XN(M_Req_11_21), .S_Ack_XN(M_Ack_11_21), .S_Data_XN(M_Data_11_21),
  .M_Req_XN(S_Req_11_21), .M_Ack_XN(S_Ack_11_21), .M_Data_XN(S_Data_11_21),
  .S_Req_YP(S_Req_21_22), .S_Ack_YP(S_Ack_21_22), .S_Data_YP(S_Data_21_22),
  .M_Req_YP(M_Req_21_22), .M_Ack_YP(M_Ack_21_22), .M_Data_YP(M_Data_21_22),
  .S_Req_YN(M_Req_20_21), .S_Ack_YN(M_Ack_20_21), .S_Data_YN(M_Data_20_21),
  .M_Req_YN(S_Req_20_21), .M_Ack_YN(S_Ack_20_21), .M_Data_YN(S_Data_20_21)

);

node #(
  .ADDRX (3), .ADDRY(1),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_31(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP( ), .S_Ack_XP( ), .S_Data_XP( ),
  .M_Req_XP( ), .M_Ack_XP( ), .M_Data_XP( ),
  .S_Req_XN(M_Req_21_31), .S_Ack_XN(M_Ack_21_31), .S_Data_XN(M_Data_21_31),
  .M_Req_XN(S_Req_21_31), .M_Ack_XN(S_Ack_21_31), .M_Data_XN(S_Data_21_31),
  .S_Req_YP(S_Req_31_32), .S_Ack_YP(S_Ack_31_32), .S_Data_YP(S_Data_31_32),
  .M_Req_YP(M_Req_31_32), .M_Ack_YP(M_Ack_31_32), .M_Data_YP(M_Data_31_32),
  .S_Req_YN(M_Req_30_31), .S_Ack_YN(M_Ack_30_31), .S_Data_YN(M_Data_30_31),
  .M_Req_YN(S_Req_30_31), .M_Ack_YN(S_Ack_30_31), .M_Data_YN(S_Data_30_31)

);

node #(
  .ADDRX (0), .ADDRY(2),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_02(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_02_12), .S_Ack_XP(S_Ack_02_12), .S_Data_XP(S_Data_02_12),
  .M_Req_XP(M_Req_02_12), .M_Ack_XP(M_Ack_02_12), .M_Data_XP(M_Data_02_12),
  .S_Req_XN( ), .S_Ack_XN( ), .S_Data_XN( ),
  .M_Req_XN( ), .M_Ack_XN( ), .M_Data_XN( ),
  .S_Req_YP(S_Req_02_03), .S_Ack_YP(S_Ack_02_03), .S_Data_YP(S_Data_02_03),
  .M_Req_YP(M_Req_02_03), .M_Ack_YP(M_Ack_02_03), .M_Data_YP(M_Data_02_03),
  .S_Req_YN(M_Req_01_02), .S_Ack_YN(M_Ack_01_02), .S_Data_YN(M_Data_01_02),
  .M_Req_YN(S_Req_01_02), .M_Ack_YN(S_Ack_01_02), .M_Data_YN(S_Data_01_02)

);

node #(
  .ADDRX (1), .ADDRY(2),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_12(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_12_22), .S_Ack_XP(S_Ack_12_22), .S_Data_XP(S_Data_12_22),
  .M_Req_XP(M_Req_12_22), .M_Ack_XP(M_Ack_12_22), .M_Data_XP(M_Data_12_22),
  .S_Req_XN(M_Req_02_12), .S_Ack_XN(M_Ack_02_12), .S_Data_XN(M_Data_02_12),
  .M_Req_XN(S_Req_02_12), .M_Ack_XN(S_Ack_02_12), .M_Data_XN(S_Data_02_12),
  .S_Req_YP(S_Req_12_13), .S_Ack_YP(S_Ack_12_13), .S_Data_YP(S_Data_12_13),
  .M_Req_YP(M_Req_12_13), .M_Ack_YP(M_Ack_12_13), .M_Data_YP(M_Data_12_13),
  .S_Req_YN(M_Req_11_12), .S_Ack_YN(M_Ack_11_12), .S_Data_YN(M_Data_11_12),
  .M_Req_YN(S_Req_11_12), .M_Ack_YN(S_Ack_11_12), .M_Data_YN(S_Data_11_12)

);

node #(
  .ADDRX (2), .ADDRY(2),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(1)
) node_22(
  .Clock(Clock), .nReset(nReset),
  .Switches(Switches), .Buttons(Buttons), 
  .DataOut(DataOut), .DataValid(DataValid),
  .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6),
  .LOCKUP( ),
  .S_Req_XP(S_Req_22_32), .S_Ack_XP(S_Ack_22_32), .S_Data_XP(S_Data_22_32),
  .M_Req_XP(M_Req_22_32), .M_Ack_XP(M_Ack_22_32), .M_Data_XP(M_Data_22_32),
  .S_Req_XN(M_Req_12_22), .S_Ack_XN(M_Ack_12_22), .S_Data_XN(M_Data_12_22),
  .M_Req_XN(S_Req_12_22), .M_Ack_XN(S_Ack_12_22), .M_Data_XN(S_Data_12_22),
  .S_Req_YP(S_Req_22_23), .S_Ack_YP(S_Ack_22_23), .S_Data_YP(S_Data_22_23),
  .M_Req_YP(M_Req_22_23), .M_Ack_YP(M_Ack_22_23), .M_Data_YP(M_Data_22_23),
  .S_Req_YN(M_Req_21_22), .S_Ack_YN(M_Ack_21_22), .S_Data_YN(M_Data_21_22),
  .M_Req_YN(S_Req_21_22), .M_Ack_YN(S_Ack_21_22), .M_Data_YN(S_Data_21_22)

);

node #(
  .ADDRX (3), .ADDRY(2),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_32(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP( ), .S_Ack_XP( ), .S_Data_XP( ),
  .M_Req_XP( ), .M_Ack_XP( ), .M_Data_XP( ),
  .S_Req_XN(M_Req_22_32), .S_Ack_XN(M_Ack_22_32), .S_Data_XN(M_Data_22_32),
  .M_Req_XN(S_Req_22_32), .M_Ack_XN(S_Ack_22_32), .M_Data_XN(S_Data_22_32),
  .S_Req_YP(S_Req_32_33), .S_Ack_YP(S_Ack_32_33), .S_Data_YP(S_Data_32_33),
  .M_Req_YP(M_Req_32_33), .M_Ack_YP(M_Ack_32_33), .M_Data_YP(M_Data_32_33),
  .S_Req_YN(M_Req_31_32), .S_Ack_YN(M_Ack_31_32), .S_Data_YN(M_Data_31_32),
  .M_Req_YN(S_Req_31_32), .M_Ack_YN(S_Ack_31_32), .M_Data_YN(S_Data_31_32)

);

node #(
  .ADDRX (0), .ADDRY(3),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_03(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_03_13), .S_Ack_XP(S_Ack_03_13), .S_Data_XP(S_Data_03_13),
  .M_Req_XP(M_Req_03_13), .M_Ack_XP(M_Ack_03_13), .M_Data_XP(M_Data_03_13),
  .S_Req_XN( ), .S_Ack_XN( ), .S_Data_XN( ),
  .M_Req_XN( ), .M_Ack_XN( ), .M_Data_XN( ),
  .S_Req_YP( ), .S_Ack_YP( ), .S_Data_YP( ),
  .M_Req_YP( ), .M_Ack_YP( ), .M_Data_YP( ),
  .S_Req_YN(M_Req_02_03), .S_Ack_YN(M_Ack_02_03), .S_Data_YN(M_Data_02_03),
  .M_Req_YN(S_Req_02_03), .M_Ack_YN(S_Ack_02_03), .M_Data_YN(S_Data_02_03)

);

node #(
  .ADDRX (1), .ADDRY(3),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_13(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_13_23), .S_Ack_XP(S_Ack_13_23), .S_Data_XP(S_Data_13_23),
  .M_Req_XP(M_Req_13_23), .M_Ack_XP(M_Ack_13_23), .M_Data_XP(M_Data_13_23),
  .S_Req_XN(M_Req_03_13), .S_Ack_XN(M_Ack_03_13), .S_Data_XN(M_Data_03_13),
  .M_Req_XN(S_Req_03_13), .M_Ack_XN(S_Ack_03_13), .M_Data_XN(S_Data_03_13),
  .S_Req_YP( ), .S_Ack_YP( ), .S_Data_YP( ),
  .M_Req_YP( ), .M_Ack_YP( ), .M_Data_YP( ),
  .S_Req_YN(M_Req_12_13), .S_Ack_YN(M_Ack_12_13), .S_Data_YN(M_Data_12_13),
  .M_Req_YN(S_Req_12_13), .M_Ack_YN(S_Ack_12_13), .M_Data_YN(S_Data_12_13)

);

node #(
  .ADDRX (2), .ADDRY(3),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_23(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP(S_Req_23_33), .S_Ack_XP(S_Ack_23_33), .S_Data_XP(S_Data_23_33),
  .M_Req_XP(M_Req_23_33), .M_Ack_XP(M_Ack_23_33), .M_Data_XP(M_Data_23_33),
  .S_Req_XN(M_Req_13_23), .S_Ack_XN(M_Ack_13_23), .S_Data_XN(M_Data_13_23),
  .M_Req_XN(S_Req_13_23), .M_Ack_XN(S_Ack_13_23), .M_Data_XN(S_Data_13_23),
  .S_Req_YP( ), .S_Ack_YP( ), .S_Data_YP( ),
  .M_Req_YP( ), .M_Ack_YP( ), .M_Data_YP( ),
  .S_Req_YN(M_Req_22_23), .S_Ack_YN(M_Ack_22_23), .S_Data_YN(M_Data_22_23),
  .M_Req_YN(S_Req_22_23), .M_Ack_YN(S_Ack_22_23), .M_Data_YN(S_Data_22_23)

);

node #(
  .ADDRX (3), .ADDRY(3),
  .DEBOUNCE_COUNT(DEBOUNCE_COUNT), .DATA_WIDTH(DATA_WIDTH), .MAX_PACKET_LEN(MAX_PACKET_LEN), .NET_ADDR(NET_ADDR),
  .USE_VGA_MEM(0)
) node_33(
  .Clock(Clock), .nReset(nReset),
  .Switches(), .Buttons(Buttons_OUT), 
  .DataOut(), .DataValid(),
  .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(),
  .LOCKUP( ),
  .S_Req_XP( ), .S_Ack_XP( ), .S_Data_XP( ),
  .M_Req_XP( ), .M_Ack_XP( ), .M_Data_XP( ),
  .S_Req_XN(M_Req_23_33), .S_Ack_XN(M_Ack_23_33), .S_Data_XN(M_Data_23_33),
  .M_Req_XN(S_Req_23_33), .M_Ack_XN(S_Ack_23_33), .M_Data_XN(S_Data_23_33),
  .S_Req_YP( ), .S_Ack_YP( ), .S_Data_YP( ),
  .M_Req_YP( ), .M_Ack_YP( ), .M_Data_YP( ),
  .S_Req_YN(M_Req_32_33), .S_Ack_YN(M_Ack_32_33), .S_Data_YN(M_Data_32_33),
  .M_Req_YN(S_Req_32_33), .M_Ack_YN(S_Ack_32_33), .M_Data_YN(S_Data_32_33)

);



endmodule
