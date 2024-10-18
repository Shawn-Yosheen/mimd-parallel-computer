// Example code for an AHBLite System-on-Chip
//  Iain McNally, modified by Yuxuan Zhang
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing two read/write register and one read only register
//
// Number of addressable locations : 3
// Size of each addressable location : 32 bits
// Supported transfer sizes : Word
// Alignment of base address : Word aligned
//
// Address map :
//   Base addess + 0 : 
//     Read LED_OUT register
//     Write LED_OUT register
//   Base addess + 4 : 
//     Read NextDataValid and DataValid registers
//     Write NextDataValid register
//   Base addess + 8 : 
//     Read OutFlag registers, cleared to 0 after read
//
// Bits within status register :
//   Bit 1   NextDataValid
//   Bit 0   DataValid

// In order to update the output, the software should update the NextDataValid
// register followed by the DataOut register.

// Bits within OutFlag register :
//   Bit 0   OutAck

// when updating the output value, OutFlag register is set by hardware, 
// when software read OutFlag register, hardware clear the register, and software write the new value from switches


module ahb_out #(
  parameter DEBOUNCE_COUNT = 0
  //1,250,000=25ms/(1/50MHz)
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
  output logic [31:0] DataOut,
  output logic DataValid,
  input Buttons

);

timeunit 1ns;
timeprecision 100ps;

  // AHB transfer codes needed in this module
  localparam No_Transfer = 2'b0;

  //control signals are stored in registers
  logic write_enable, read_enable;
  logic [1:0] word_address;
 
  logic OutAck;
  logic [31:0] OutFlag;

  logic NextDataValid;
  logic [31:0] Status;

  // last_buttons is used for simple edge detection  
  logic last_buttons;
  // debounced_buttons is for data after debounce
  logic debounced_buttons;


	//instance debounce module
 Debounce_Button #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) debounce_ins(
	.HCLK(HCLK),
	.HRESETn(HRESETn),
	.Button_In(Buttons),
	.Button_Out(debounced_buttons)
  );

  //update the OutFlag register when button is pressed, and clear the value after the read is accessed
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn )
      begin
        OutAck <= 0;
        last_buttons <= '0;
      end
    else
      begin
        if ( debounced_buttons && !last_buttons )
            OutAck <= 1;
        else if ( read_enable && ( word_address[1] == 1 ) )
          begin
            OutAck <= 0;
          end

        last_buttons <= debounced_buttons;

      end
  //define the bit in the OutFlag register
  assign OutFlag = {31'd0, OutAck};

  //Generate the control signals in the address phase
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn )
      begin
        write_enable <= '0;
        read_enable <= '0;
        word_address <= '0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        write_enable <= HWRITE;
        read_enable <= ! HWRITE;
        word_address <= HADDR[3:2];
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
        DataOut <= '0;
		DataValid <= '0;
		NextDataValid <= '0;
	end
    else if ( write_enable &&  word_address == 0 ) begin
        DataOut <= HWDATA;
		DataValid <= NextDataValid;
	end
	else if ( write_enable &&  word_address == 1 ) begin
        NextDataValid <= HWDATA[0];
	end

  // define the bits in the status register
  assign Status = {30'd0, NextDataValid, DataValid};

  //read
  always_comb
    if ( ! read_enable )
      // (output of zero when not enabled for read is not necessary
      //  but may help with debugging)
      HRDATA = '0;
    else
      case (word_address)
        // ensure that half-word data is correctly aligned
        2'b00 : HRDATA = DataOut;
        2'b01 : HRDATA = Status;
        2'b10 : HRDATA = OutFlag;
        // unused address - returns zero
        default : HRDATA = '0;
      endcase

  //Transfer Response
  assign HREADYOUT = '1; //Single cycle Write & Read. Zero Wait state operations


endmodule

`ifndef DEBOUNCE_BUTTON
`define DEBOUNCE_BUTTON
module Debounce_Button #(parameter DEBOUNCE_COUNT=1250000)(
  // AHB Global Signals
  input HCLK,
  input HRESETn,

  // Non-AHB Signals
  input Button_In,
  output logic Button_Out

  );

	timeunit 1ns;
	timeprecision 100ps;

  //1,250,000=25ms/(1/50MHz)
	//localparam DEBOUNCE_COUNT = 1250000;
  //2^21>1,250,000
	logic [20:0] Counter_Button;
	logic Button_Sync0, Button_Sync1;
	logic Button_Stable;

	//synchronize the input button register
    always_ff @(posedge HCLK , negedge HRESETn) begin
        if (!HRESETn) begin
            Button_Sync0 <= 1'b0;
            Button_Sync1 <= 1'b0;
        end else begin
            Button_Sync0 <= Button_In;
            Button_Sync1 <= Button_Sync0;
        end
    end

    //Debounce module
    always_ff @(posedge HCLK , negedge HRESETn) begin
      if (!HRESETn) begin
        Counter_Button <= 0;
        Button_Stable <= 0;
      end
      else begin
        if (Button_Sync1 != Button_Stable) begin
          if(Counter_Button == DEBOUNCE_COUNT) begin
            Button_Stable <= Button_Sync1;
				    Counter_Button <= '0;
          end else begin
            Button_Stable <= Button_Stable;
            Counter_Button <= Counter_Button + 1;
          end
        end else begin
          Button_Stable <= Button_Stable;
          Counter_Button <= '0;
        end
      end
    end

    // button output after debounce
    assign Button_Out = Button_Stable;

endmodule
`endif // DEBOUNCE_BUTTON

