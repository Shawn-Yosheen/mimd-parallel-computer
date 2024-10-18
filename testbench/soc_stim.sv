module soc_stim();
     
timeunit 1ns;
timeprecision 100ps;

  logic HRESETn, HCLK; 
  logic [31:0] Switches;
  logic [1:0] Buttons_SW, Buttons_OUT;
  wire [31:0] DataOut;
  wire DataValid;
  wire LOCKUP1, LOCKUP2;

  //communication signals
  //ahb_rx
  logic S_Ack;
  logic [31:0] S_Data;
  logic S_Req;
  //ahb_tx
  logic [31:0] M_Data;
  logic M_Req;
  logic M_Ack;
  logic [31:0] M_Data1;
  logic M_Req1;
  logic M_Ack1;
  //ahb_id
  logic [1:0] Addr1_X, Addr1_Y;
  logic [1:0] Addr2_X, Addr2_Y;


  soc #(
  .ADDRX(0), .ADDRY(0), .DEBOUNCE_COUNT(0)
) dut1(.HCLK, .HRESETn, .Switches(Switches), .Buttons(Buttons_SW), 
	.DataOut(), .DataValid(), .LOCKUP(LOCKUP1), 
	.S_Ack(S_Ack), .S_Data(S_Data), .S_Req(S_Req), 
	.M_Data(M_Data), .M_Req(M_Req), .M_Ack(M_Ack),
	.Addr_X(Addr1_X), .Addr_Y(Addr1_Y) );

  soc #(
  .ADDRX(0), .ADDRY(1), .DEBOUNCE_COUNT(0)
) dut2(.HCLK, .HRESETn, .Switches(), .Buttons(Buttons_OUT), 
	.DataOut(DataOut), .DataValid(DataValid), .LOCKUP(LOCKUP2), 
	.S_Ack(M_Ack1), .S_Data(M_Data1), .S_Req(M_Req1), 
	.M_Data(S_Data), .M_Req(S_Req), .M_Ack(S_Ack),
	.Addr_X(Addr2_X), .Addr_Y(Addr2_Y) );

  packet_buffer buffer1 (
    .Clock(HCLK), .nReset(HRESETn),
    .S_Req(M_Req), .S_Ack(M_Ack), .S_Data(M_Data),
    .M_Ack(M_Ack1), .M_Req(M_Req1), .M_Data(M_Data1) );

  always
    begin
           HCLK = 0;
      #5ns HCLK = 1;
      #10ns HCLK = 0;
      #5ns HCLK = 0;
    end

  task press_button_SW;
      #10us Buttons_SW[0] = 1;
      #10us Buttons_SW[0] = 0;
  endtask

  task press_button_OUT;
      #10us Buttons_OUT[1] = 1;
      #10us Buttons_OUT[1] = 0;
  endtask
    

  initial
    begin
		HRESETn = 0;
		Buttons_SW = '0;
		Buttons_OUT = '0;
		Switches = 0;
		#10.0ns HRESETn = 1;

      //#20us press_button(1);
		#10us Switches = 7;
		#10us press_button_SW;
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
/*
	for(int j=1; j<16; j++) begin
		#10us Switches = j;
		#10us press_button(0);
	end
*/

      #50us $stop;
            $finish;
    end

endmodule
