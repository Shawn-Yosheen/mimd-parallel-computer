module noc_stim();
     
timeunit 1ns;
timeprecision 100ps;

  logic nReset, Clock; 
  logic [31:0] Switches;
  logic [1:0] Buttons;
  wire [31:0] DataOut;
  wire DataValid;
  logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

  noc #(
  .DEBOUNCE_COUNT(0), .DATA_WIDTH(32), .MAX_PACKET_LEN(8), .NET_ADDR(4)
) noc_ins(
  .Clock(Clock), .nReset(nReset),
  .Switches(Switches), 
  .Buttons(Buttons), 
  .DataOut(DataOut), .DataValid(DataValid),
  .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5)
);

  always
    begin
           Clock = 0;
      #5ns Clock = 1;
      #10ns Clock = 0;
      #5ns Clock = 0;
    end

  task press_button_SW;
      #10us Buttons[0] = 1;
      #10us Buttons[0] = 0;
  endtask

  task press_button_OUT;
      #10us Buttons[1] = 1;
      #10us Buttons[1] = 0;
  endtask
    

  initial
    begin
		nReset = 0;
		Buttons = '0;
		Switches = 0;
		#10.0ns nReset = 1;

      //#20us press_button(1);
		#10us Switches = 16;
		#10us press_button_SW;
/*
		#10us Switches = 8;
		#10us press_button_SW;
		#10us Switches = 9;
		#10us press_button_SW;
		#10us Switches = 10;
		#10us press_button_SW;

		#50us press_button_OUT;
		#10us press_button_OUT;
		#10us press_button_OUT;
		#10us press_button_OUT;
*/

      #100s $stop;
            $finish;
    end

endmodule
