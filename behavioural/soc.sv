// Example code for a PicoRV32 AHBLite System-on-Chip
//  Iain McNally
//  ECS, University of Soutampton
//
//
// This version supports 3 AHBLite slaves:
//
//  ahb_ram           RAM
//  ahb_switches      A handshaking interface to support input from switches and buttons
//  ahb_out           An output interface supporting simultaneous update of data and valid signals
//

module soc #(
  parameter ADDRX = 0, ADDRY = 0, DEBOUNCE_COUNT = 1250000,
  parameter USE_VGA_MEM = 0
)(

  input HCLK, HRESETn,
  
  input [31:0] Switches, 
  input [1:0] Buttons, 

  output [31:0] DataOut,
  output logic DataValid,

  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, //Non-AHB Signals

  output LOCKUP,

  //communication signals
  output logic S_Ack,
  input [31:0] S_Data,
  input S_Req,

  output logic [31:0] M_Data,
  output logic M_Req,
  input M_Ack,

  output logic [1:0] Addr_X, Addr_Y

);
 
timeunit 1ns;
timeprecision 100ps;

  // Global & Master AHB Signals
  wire [31:0] HADDR, HWDATA, HRDATA;
  wire [1:0] HTRANS;
  wire [2:0] HSIZE, HBURST;
  wire [3:0] HPROT;
  wire HWRITE, HMASTLOCK, HRESP, HREADY;

  // Per-Slave AHB Signals
  wire HSEL_RAM, HSEL_SW, HSEL_DOUT, HSEL_RX, HSEL_TX, HSEL_ID, HSEL_DIG, HSEL_MEM, HSEL_VGA;
  wire [31:0] HRDATA_RAM, HRDATA_SW, HRDATA_DOUT, HRDATA_RX, HRDATA_TX, HRDATA_ID, HRDATA_DIG, HRDATA_MEM, HRDATA_VGA;
  wire HREADYOUT_RAM, HREADYOUT_SW, HREADYOUT_DOUT, HREADYOUT_RX, HREADYOUT_TX, HREADYOUT_ID, HREADYOUT_DIG, HREADYOUT_MEM, HREADYOUT_VGA;

  // interconnect between mem and tx
  logic [31:0] Mem_Addr, Mem_Data;
  logic [7:0] Des_Addr, Byte_Len, Mes_Type;
  logic mem_valid;

  //divide buttons
  wire KEY3, KEY2;

  assign KEY2 = Buttons[1];
  assign KEY3 = Buttons[0];

  // Set this to zero because PicoRV32 does not support LOCKUP
  assign LOCKUP = '0;

  // Set this to zero because simple slaves do not generate errors
  assign HRESP = '0;

  // PicoRV32 is AHB Master
  picorv32_ahb riscv_1 (

    // AHB Signals
    .HCLK, .HRESETn,
    .HADDR, .HBURST, .HMASTLOCK, .HPROT, .HSIZE, .HTRANS, .HWDATA, .HWRITE,
    .HRDATA, .HREADY, .HRESP                                   

  );


  // AHB interconnect including address decoder, register and multiplexer
  ahb_interconnect interconnect_1 (

    .HCLK, .HRESETn, .HADDR, .HRDATA, .HREADY,

    .HSEL_SIGNALS({HSEL_VGA, HSEL_MEM, HSEL_DIG, HSEL_ID, HSEL_TX, HSEL_RX, HSEL_DOUT, HSEL_SW, HSEL_RAM}),
    .HRDATA_SIGNALS({HRDATA_VGA, HRDATA_MEM, HRDATA_DIG, HRDATA_ID, HRDATA_TX, HRDATA_RX, HRDATA_DOUT, HRDATA_SW, HRDATA_RAM}),
    .HREADYOUT_SIGNALS({HREADYOUT_VGA, HREADYOUT_MEM, HREADYOUT_DIG, HREADYOUT_ID, HREADYOUT_TX, HREADYOUT_RX, HREADYOUT_DOUT,HREADYOUT_SW,HREADYOUT_RAM})

  );


  // AHBLite Slaves
        
  ahb_ram ram_1 (

    .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
    .HSEL(HSEL_RAM),
    .HRDATA(HRDATA_RAM), .HREADYOUT(HREADYOUT_RAM)

  );


  ahb_switches #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT) ) switches_1 (

    .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
    .HSEL(HSEL_SW),
    .HRDATA(HRDATA_SW), .HREADYOUT(HREADYOUT_SW),

    .Switches(Switches), .Buttons(KEY3)

  );

  ahb_out #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT) ) out_1 (

    .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
    .HSEL(HSEL_DOUT),
    .HRDATA(HRDATA_DOUT), .HREADYOUT(HREADYOUT_DOUT),

    .DataOut(DataOut), .DataValid(DataValid), .Buttons(KEY2)

  );

  ahb_rx rx_1(

  .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .HSEL(HSEL_RX),
  .HRDATA(HRDATA_RX), .HREADYOUT(HREADYOUT_RX),

  .S_Ack(S_Ack), .S_Data(S_Data), .S_Req(S_Req)

  );

  ahb_tx #(.X(ADDRX), .Y(ADDRY) ) tx_1(

  .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .HSEL(HSEL_TX),
  .HRDATA(HRDATA_TX), .HREADYOUT(HREADYOUT_TX),

  .Mem_Addr(Mem_Addr), .Mem_Data(Mem_Data), 
  .Mem_Des_Addr(Des_Addr), .Mem_Byte_Len(Byte_Len), .Mem_Mes_Type(Mes_Type), 
  .mem_valid(mem_valid), 
  .M_Data(M_Data), .M_Req(M_Req), .M_Ack(M_Ack)

  );

  ahb_id #(.X(ADDRX), .Y(ADDRY) ) id_1(

  .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .HSEL(HSEL_ID),
  .HRDATA(HRDATA_ID), .HREADYOUT(HREADYOUT_ID),

  .Addr_X(Addr_X), .Addr_Y(Addr_Y)

);

  ahb_digit #( .W(8) ) dig_1(

  .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .HSEL(HSEL_DIG),
  .HRDATA(HRDATA_DIG), .HREADYOUT(HREADYOUT_DIG),

  .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6)
);

  ahb_mem #( .ADDRX(ADDRX), .ADDRY(ADDRY) ) mem_ins( 

  .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
  .HSEL(HSEL_MEM),
  .HRDATA(HRDATA_MEM), .HREADYOUT(HREADYOUT_MEM),

  .Mem_Addr(Mem_Addr), .Mem_Data(Mem_Data),
  .Des_Addr(Des_Addr), .Byte_Len(Byte_Len), .Mes_Type(Mes_Type), 
	.valid(mem_valid)
);

generate
  if(USE_VGA_MEM) begin: gen_vga_mem
    vga_ram vga_ram_1 (

      .HCLK, .HRESETn, .HADDR, .HWDATA, .HSIZE, .HTRANS, .HWRITE, .HREADY,
      .HSEL(HSEL_VGA),
      .HRDATA(HRDATA_VGA), .HREADYOUT(HREADYOUT_VGA)

    );
  end
  else begin : gen_non
    ahb_non non_1(
      .HRDATA(HRDATA_VGA), .HREADYOUT(HREADYOUT_VGA)
    );
  end
endgenerate

endmodule
