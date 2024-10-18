module de1_soc_wrapper_stim();
     
timeunit 1ns;
timeprecision 100ps;

  logic nReset, CLOCK_50; 
  logic [9:0] SW;
  logic [1:0] Buttons;
  wire [9:0] LEDR;
  wire [6:0] HEX0;
  wire [6:0] HEX1;
  wire [6:0] HEX2;
  wire [6:0] HEX3;
  wire [6:0] HEX4;
  wire [6:0] HEX5;
  
  wire [2:0] KEY;
  
  assign KEY={nReset,~Buttons[1:0]}; // DE1-SoC keys are active low

  de1_soc_wrapper dut(.CLOCK_50, .LEDR, .SW, .KEY, .HEX0, .HEX1, .HEX2, .HEX3, .HEX4, .HEX5);

  always
    begin
           CLOCK_50 = 0;
      #5ns CLOCK_50 = 1;
      #10ns CLOCK_50 = 0;
      #5ns CLOCK_50 = 0;
    end

  task press_button(input n);
      #30us Buttons[n] = 1;
      #30us Buttons[n] = 0;
  endtask
    

  initial
    begin
            nReset = 0;
            Buttons = 0;
            SW = 0;
      #10.0ns nReset = 1;
            
      #10us SW = 1;
      #10us press_button(0);

      #10us SW = 2;
      #10us press_button(0);


      #10us SW = 3;
      #10us press_button(0);


      #10us SW = 4;
      #10us press_button(0);


      #20us press_button(1);
	//output 1


      #20us press_button(1);
	//output 2


      #20us press_button(1);
	//output 3


      #20us press_button(1);
	//output 4


      #20us press_button(1);
	//output 0


      #10us SW = 5;
      #10us press_button(0);


      #10us SW = 6;
      #10us press_button(0);


      #10us SW = 7;
      #10us press_button(0);


      #20us press_button(1);
	//output 5


      #20us press_button(1);
	//output 6


      #20us press_button(1);
	//output 7


      #20us press_button(1);
	//output 0
      #50us $stop;
            $finish;
    end
       
endmodule
