// Example code for an AHBLite System-on-Chip
//  Yuxuan Zhang
//  ECS, University of Soutampton
//
// This module is an AHB-Lite Slave containing one write only register
//
// Number of addressable locations : 3
// Size of each addressable location : 32 bits
// Supported transfer sizes : Word
// Alignment of base address : Word aligned
//
// Address map :
//   Base addess + 0 : 
//     Write digit register(counter for cores finishing job)
//   Base addess + 4 : 
//     Write start_counting register
//   Base addess + 8 : 
//     Write finish_counting register
//   Base addess + 12 : 
//     Write pixcel register


module ahb_digit #(
  parameter W = 8 // input bin width
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
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6

);

timeunit 1ns;
timeprecision 100ps;

  // AHB transfer codes needed in this module
  localparam No_Transfer = 2'b0;

  //control signals are stored in registers
  logic write_enable;
  logic [1:0] word_address;
 
  logic [31:0] digit, start, finish, pixcel;
  logic start_bit, finish_bit;

  assign start_bit = start[0];
  assign finish_bit = finish[0];
  
  // state machine vairables
  typedef enum logic [1:0] {WAIT, COUNTING} state_type;
  state_type present_state, next_state;

  // counter macro numbers
  localparam MAX_PRE_COUNT = 5_000_000 - 1;

  // counter register
  logic [22:0] pre_counter;
  logic [3:0] deciseconds_counter;
  logic [5:0] seconds_counter;
  logic [3:0] minutes_counter;
  

  logic [W+(W-4)/3:0] Result_Data;
  logic [6+(6-4)/3:0] Second_Data;  
  logic [4+(4-4)/3:0] Pixcel_Data;

  // instance Binary2BCD and BCD2Seg for digit_counter
  Binary2BCD #( .W(W) ) digit_conv (
    .BIN_in(digit[W-1:0]),
    .BCD_out(Result_Data)
  );

  BCD2Seg H4( .BCD_in(Result_Data[3:0]), .Seg_out(HEX4) );
  BCD2Seg H5( .BCD_in(Result_Data[7:4]), .Seg_out(HEX5) );

  // instance for timer_counter
  Binary2BCD #( .W(6) ) second_conv (
    .BIN_in(seconds_counter),
    .BCD_out(Second_Data)
  );

  BCD2Seg deciseconds ( .BCD_in(deciseconds_counter[3:0] ), .Seg_out(HEX0) );
  BCD2Seg seconds_l ( .BCD_in(Second_Data[3:0]), .Seg_out(HEX1) );
  BCD2Seg seconds_h ( .BCD_in( {1'b0, Second_Data[6:4]} ), .Seg_out(HEX2) );
  BCD2Seg minutes ( .BCD_in( minutes_counter[3:0] ), .Seg_out(HEX3) );

  // instance for pixcel
  Binary2BCD #( .W(4) ) pixcel_conv (
    .BIN_in( pixcel[3:0] ),
    .BCD_out(Pixcel_Data)
  );

  BCD2Seg pix_ins ( .BCD_in(Pixcel_Data[3:0] ), .Seg_out(HEX6) );


  //Generate the control signals in the address phase
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn )
      begin
        write_enable <= '0;
        word_address <= '0;
      end
    else if ( HREADY && HSEL && (HTRANS != No_Transfer) )
      begin
        write_enable <= HWRITE;
        word_address <= HADDR[3:2];
     end
    else
      begin
        write_enable <= '0;
        word_address <= '0;
     end

  //Act on control signals in the data phase

  // write
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn ) begin
      digit <= '0;
      start <= '0;
      finish <= '0;
      pixcel <= '0;
    end
    else if ( write_enable &&  word_address == 0 )
      digit <= HWDATA;
    else if ( write_enable &&  word_address == 1 )
      start <= HWDATA;
    else if ( write_enable &&  word_address == 2 )
      finish <= HWDATA;
    else if ( write_enable &&  word_address == 3 )
      pixcel <= HWDATA;
    else begin
      start <= '0;
      finish <= '0;
    end


  //Transfer Response
  assign HREADYOUT = '1; //Single cycle Write & Read. Zero Wait state operations

  /////////////////////////
  // state machine defines
  /////////////////////////
  always_ff @(posedge HCLK, negedge HRESETn)
    if ( ! HRESETn )
      present_state <= WAIT;
    else
      present_state <= next_state;

  always_comb begin
    case(present_state)
    WAIT:     next_state = start_bit ? COUNTING:WAIT;
    COUNTING: next_state = finish_bit ? WAIT:COUNTING;
    default:  next_state = WAIT;
    endcase
  end

  always_ff @(posedge HCLK, negedge HRESETn) begin
    if ( ! HRESETn ) begin
      pre_counter <= '0;
      deciseconds_counter <= '0;
      seconds_counter <= '0;
      minutes_counter <= '0;
    end
    else if(present_state == WAIT) begin
      if(start_bit) begin
        pre_counter <= '0;
        deciseconds_counter <= '0;
        seconds_counter <= '0;
        minutes_counter <= '0;
      end    
    end
    else if (present_state == COUNTING) begin
      if(pre_counter == MAX_PRE_COUNT) begin
        pre_counter <= '0;
        if(deciseconds_counter == 9) begin
          deciseconds_counter <= '0;
          if(seconds_counter == 59) begin
            seconds_counter <= '0;
              if(minutes_counter ==9) begin
                minutes_counter <= '0;
              end else
                minutes_counter <= minutes_counter+1;
          end else
            seconds_counter <= seconds_counter + 1;
        end else 
          deciseconds_counter <= deciseconds_counter + 1;
      end else
        pre_counter <= pre_counter + 1;
    end

  end


endmodule

module BCD2Seg(
  input logic  [3:0] BCD_in,
  output logic [6:0] Seg_out
);

timeunit 1ns;
timeprecision 100ps;

  always_comb begin
    case(BCD_in)
    4'd0: Seg_out = 7'h40; //0
    4'd1: Seg_out = 7'h79; //1
    4'd2: Seg_out = 7'h24; //2
    4'd3: Seg_out = 7'h30; //3
    4'd4: Seg_out = 7'h19; //4
    4'd5: Seg_out = 7'h12; //5
    4'd6: Seg_out = 7'h02; //6
    4'd7: Seg_out = 7'h78; //7
    4'd8: Seg_out = 7'h00; //8
    4'd9: Seg_out = 7'h10; //9
    default: Seg_out = 7'h1; //null
    endcase
  end
endmodule

module Binary2BCD #(
  parameter W = 8 // input bin width
)(
  input logic  [W-1 : 0] BIN_in,
  output logic [W+(W-4)/3 : 0] BCD_out
);

timeunit 1ns;
timeprecision 100ps;

integer i, j;

  always_comb begin
    for(i = 0; i <= W+(W-4)/3 ; i = i+1)
      BCD_out[i] = 0;

    BCD_out[W-1:0] = BIN_in;

    for(i = 0; i <= W-4; i = i+1)
      for(j = 0; j <= i/3; j = j+1)
        if(BCD_out[ W-i+4*j -: 4 ] > 4)
          BCD_out[ W-i+4*j -: 4 ] =  BCD_out[W-i+4*j -: 4] + 4'd3;
  end

endmodule
