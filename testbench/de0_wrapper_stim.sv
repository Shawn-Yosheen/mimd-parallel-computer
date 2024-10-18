module de0_wrapper_stim();
     
timeunit 1ns;
timeprecision 100ps;

  logic nReset, CLOCK_50; 
  logic [9:0] SW;
  logic [1:0] Buttons;
  wire [9:0] LEDG;
  wire [7:0] HEX0;
  wire [7:0] HEX1;
  wire [7:0] HEX2;
  wire [7:0] HEX3;
  
  wire [2:0] KEY;
  
  assign KEY={nReset,~Buttons[1:0]}; // de0 keys are active low

  de0_wrapper dut(.CLOCK_50, .LEDG, .SW, .KEY, .HEX0, .HEX1, .HEX2, .HEX3);

  always
    begin
           CLOCK_50 = 0;
      #5ns CLOCK_50 = 1;
      #10ns CLOCK_50 = 0;
      #5ns CLOCK_50 = 0;
    end

  task press_button(input n);
      #1us Buttons[n] = 1;
      #1us Buttons[n] = 0;
  endtask
    

  initial
    begin
            nReset = 0;
            Buttons = 0;
            SW = 1;
      #10.0ns nReset = 1;
            
      #10us SW = 0;
      #5us press_button(0);
      #5us press_button(1);

      #10us SW = 1;
      #5us press_button(0);
      #5us press_button(1);


      #10us SW = 2;
      #5us press_button(0);
      #5us press_button(1);


      #10us SW = 3;
      #5us press_button(0);
      #5us press_button(1);


      #10us SW = 4;
      #5us press_button(0);
      #5us press_button(1);


      #20us SW = 5;
      #5us press_button(0);
      #5us press_button(1);


      #20us SW = 6;
      #5us press_button(0);
      #5us press_button(1);


      #20us SW = 7;
      #5us press_button(0);
      #5us press_button(1);


      #20us SW = 8;
      #5us press_button(0);
      #5us press_button(1);

      #30us SW = 15;
      #5us press_button(0);
      #5us press_button(1);

      #60us SW = 12;
      #5us press_button(0);
      #5us press_button(1);

      #50us $stop;
            $finish;
    end
       
endmodule
