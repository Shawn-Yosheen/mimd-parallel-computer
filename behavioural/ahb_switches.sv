// Example code for an AHBLite System-on-Chip
//  Iain McNally, modified by Yuxuan Zhang
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
//     Read Switches Entered via Button
//   Base addess + 4 : 
//     Read Status of Switches Entered via Buttons
//
// Bits within status register :
//   Bit 0   DataValid
//     (data has been entered via Button
//      this status bit is cleared when this data is read by the bus master)

// this interface supports 32 bit transfers


module ahb_switches #(
  parameter DEBOUNCE_COUNT = 0
  //1,250,000=25ms/(1/50MHz)
)(

  // AHB Global Signals
  input HCLK,
  input HRESETn,

  // AHB Signals from Master to Slave
  input [31:0] HADDR, // With this interface HADDR is ignored
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
  input [31:0] Switches,
  input Buttons

);

timeunit 1ns;
timeprecision 100ps;

  // AHB transfer codes needed in this module
  localparam No_Transfer = 2'b0;

  // Storage for one switch values  
  logic [31:0] SwitchData;

  // Storage for status bits 
  logic DataValid;

  // last_buttons is used for simple edge detection  
  logic last_buttons;

  //control signals are stored in registers
  logic read_enable;

  logic word_address;
 
  logic [31:0] Status;

  logic debounced_buttons;

	//instance debounce module
 Debounce_Button #(.DEBOUNCE_COUNT(DEBOUNCE_COUNT)) debounce_ins(
	.HCLK(HCLK),
	.HRESETn(HRESETn),
	.Button_In(Buttons),
	.Button_Out(debounced_buttons)
  );
  

  //Update the SwitchData values only when the appropriate button is pressed
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn )
      begin
        SwitchData <= '0;
        last_buttons <= '0;
        DataValid <= 0;
      end
    else
      begin
        if ( debounced_buttons && !last_buttons )
          begin
            SwitchData <= Switches;
            DataValid <= 1;
          end
        else if ( read_enable && ( word_address == 1 ) )
          begin
            DataValid <= 0;
          end

        last_buttons <= debounced_buttons;

      end


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
        word_address <= HADDR[2];
     end
    else
      begin
        read_enable <= '0;
        word_address <= '0;
     end

  //Act on control signals in the data phase

  // define the bits in the status register
  assign Status = { 31'd0, DataValid};

  //read
  always_comb
    if ( ! read_enable )
      // (output of zero when not enabled for read is not necessary
      //  but may help with debugging)
      HRDATA = '0;
    else
      case (word_address)
        // ensure that word data is correctly aligned
        0 : HRDATA = SwitchData;
        1 : HRDATA = Status;
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
