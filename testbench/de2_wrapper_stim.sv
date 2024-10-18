module de2_wrapper_stim();
     
timeunit 1ns;
timeprecision 100ps;

  logic nReset, CLOCK_50; 
  logic [15:0] SW;
  logic [1:0] Buttons;
  wire [15:0] LEDR;
  wire [6:0] HEX0;
  wire [6:0] HEX1;
  wire [6:0] HEX2;
  wire [6:0] HEX3;
  wire [6:0] HEX4;
  wire [6:0] HEX5;
  wire [6:0] HEX6;
  wire [6:0] HEX7;
  
  wire [2:0] KEY;
  
  assign KEY={nReset,~Buttons[1:0]}; // DE2 keys are active low

  de2_wrapper dut(.CLOCK_50, .LEDR, .SW, .KEY, .HEX0, .HEX1, .HEX2, .HEX3, .HEX4, .HEX5, .HEX6, .HEX7);

  always
    begin
           CLOCK_50 = 0;
      #5ns CLOCK_50 = 1;
      #10ns CLOCK_50 = 0;
      #5ns CLOCK_50 = 0;
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
            Buttons = 0;
            SW = 0;
      #10.0ns nReset = 1;
            
		#10us SW = 16;
		#10us press_button_SW;


      #100s $stop;
            $finish;
    end
       
endmodule
