module nexys4_wrapper_stim();
     
timeunit 1ns;
timeprecision 100ps;

  logic nReset, Clock; 
  logic [15:0] Switches;
  logic [1:0] Buttons; // nexys4 buttons are active high
  wire [15:0] DataOut;
  wire DataValid, DataInvalid;
  wire Status_Red, Status_Green;

  nexys4_wrapper dut(.Clock, .nReset, .DataOut, .DataValid, .DataInvalid, .Switches, .Buttons, .Status_Red, .Status_Green);

  always
    begin
           Clock = 0;
      #2.5ns Clock = 1;
      #5.0ns Clock = 0;
      #2.5ns Clock = 0;
    end

  task press_button(input n);
      #1us Buttons[n] = 1;
      #1us Buttons[n] = 0;
  endtask
    

  initial
    begin
            nReset = 0;
            Buttons = 0;
            Switches = 1;
      #10.0ns nReset = 1;
            
      #10us Switches = 0;
      #5us press_button(0);
      #5us press_button(1);

      #10us Switches = 1;
      #5us press_button(0);
      #5us press_button(1);


      #10us Switches = 2;
      #5us press_button(0);
      #5us press_button(1);


      #10us Switches = 3;
      #5us press_button(0);
      #5us press_button(1);


      #10us Switches = 4;
      #5us press_button(0);
      #5us press_button(1);


      #20us Switches = 5;
      #5us press_button(0);
      #5us press_button(1);


      #20us Switches = 6;
      #5us press_button(0);
      #5us press_button(1);


      #20us Switches = 7;
      #5us press_button(0);
      #5us press_button(1);


      #20us Switches = 8;
      #5us press_button(0);
      #5us press_button(1);

      #30us Switches = 15;
      #5us press_button(0);
      #5us press_button(1);

      #60us Switches = 12;
      #5us press_button(0);
      #5us press_button(1);

      #50us $stop;
            $finish;
    end
       
endmodule
