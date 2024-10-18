//Packet Buffer v2.0
//Yuxuan Zhang
//MAX_PACKET_LEN could only be 2^n

module packet_buffer #(parameter DATA_WIDTH=32, MAX_PACKET_LEN=8, NET_ADDR=4)(
  //Global Signals
  input Clock,
  input nReset,

  // slave interface(data in)
  input  logic S_Req,
  output logic S_Ack,
  input logic [DATA_WIDTH-1:0] S_Data,

  // master interface(data out)
  output logic M_Req,
// M_Req is asserted when M_Data is head
  input  logic M_Ack,
  output logic [DATA_WIDTH-1:0] M_Data,

	// routing signals -- used in a router
	output logic [3:0] Des_Addr, Src_Addr, 

	output logic [7:0] Packet_Len, Out_ptr
  
    );

timeunit 1ns;
timeprecision 100ps;

  // internal viarables defiend here

  //data array
  logic [DATA_WIDTH-1:0] Packet_Data [MAX_PACKET_LEN:0];

  logic [31:0] Header;

  logic [7:0] Byte_Len;

  logic [7:0] In_ptr;

  // slave interface state machine viarables
  typedef enum logic [2:0] {S_IDLE, S_EMPTY, S_REC} s_state_type;
  s_state_type s_present_state, s_next_state;

  // master interface state machine viarables
  typedef enum logic [2:0] {M_IDLE, M_EMPTY, M_REQ, M_SEND} m_state_type;
  m_state_type m_present_state, m_next_state;

//////////////////////
// slave state machine
//////////////////////

  // next state
  always_ff @(posedge Clock, negedge nReset)
	  if ( ! nReset )
		  s_present_state <= S_IDLE;
	  else
		  s_present_state <= s_next_state;

  always_comb begin

	  Header = 32'd0;
	  s_next_state = S_IDLE;

	  case(s_present_state)
	  S_IDLE: begin
		  s_next_state = S_EMPTY;
	  end
	  S_EMPTY: begin
      if(S_Req && S_Ack) begin
        s_next_state = S_REC;
        Header = S_Data;
      end
      else begin
        s_next_state = S_EMPTY;
        Header = 32'd0;
      end
	  end
	  S_REC: begin
		  s_next_state = (In_ptr < Packet_Len)? S_REC : S_EMPTY;
	  end
	  endcase

  end

  always_comb begin
    S_Ack = 0;
    if(m_present_state == M_EMPTY)
      S_Ack = 1;
  end

  // header defines here
  always_comb begin
    if(s_present_state == S_EMPTY && S_Req && S_Ack)
      Des_Addr = Header [27:24];
    else if(m_present_state == M_REQ)
	    Des_Addr = Packet_Data [0] [27:24];
    else
      Des_Addr = '0;
	  Src_Addr = Header [23:16];
	  Byte_Len = Header [15: 8];
  end

  always_ff @(posedge Clock, negedge nReset) begin
	  if ( ! nReset ) begin
		  In_ptr <= '0;
		  Packet_Len <= '0;
	  end
	  else if(s_present_state == S_IDLE) begin
		  In_ptr <= '0;
		  Packet_Len <= '0;
	  end
	  else if(s_present_state == S_EMPTY) begin
		  if(S_Req && S_Ack) begin
			  Packet_Len <= (Byte_Len >> 2);
			  Packet_Data[In_ptr]  <= S_Data;
			  In_ptr <= In_ptr+1;
		  end
		  else
			  In_ptr <= '0;
	  end
	  else if(s_present_state == S_REC) begin
		  if(s_next_state == S_EMPTY)
			  In_ptr <= '0;
		  else
			  In_ptr <= In_ptr + 1;
		  Packet_Data[In_ptr] <= S_Data;
	  end
  end

//////////////////////
// master state machine
//////////////////////

  // next state
  always_ff @(posedge Clock, negedge nReset)
	if ( ! nReset )
		m_present_state <= M_IDLE;
	else
		m_present_state <= m_next_state;

  // comb assignments
  always_comb begin
	  M_Req = 0;
	  M_Data = 32'd0;
	  m_next_state = M_IDLE;

	  case(m_present_state)
	  M_IDLE: begin
		  m_next_state = M_EMPTY;
	  end
	  M_EMPTY: begin
		  //this stage change depends on other slave state machine
		  if( s_next_state == S_REC )
			  m_next_state = M_REQ;
		  else
			  m_next_state = M_EMPTY;
	  end
	  M_REQ: begin
		  M_Req = 1;
		  M_Data = Packet_Data[Out_ptr];
		  if(M_Ack)
			  m_next_state = M_SEND;
		  else
			  m_next_state = M_REQ;
	  end
	  M_SEND: begin
		  M_Data = Packet_Data[Out_ptr];
		  m_next_state = ( Out_ptr < Packet_Len)? M_SEND : M_EMPTY;
	  end
	  endcase

  end

  // register
  always_ff @(posedge Clock, negedge nReset) begin
	if ( ! nReset )
		Out_ptr <= '0;
	else if(m_present_state == M_IDLE)
		Out_ptr <= '0;
	else if(m_present_state == M_EMPTY)
		Out_ptr <= '0;
	else if(m_present_state == M_REQ) begin
    if(M_Ack)
		  Out_ptr <= Out_ptr+1;
    else
      Out_ptr <= '0;
  end
	else if(m_present_state == M_SEND) begin
		if(m_next_state == M_EMPTY)
			Out_ptr <= '0;
		else
			Out_ptr <= Out_ptr + 1;
	end
  end

//////////////////////
// data register
//////////////////////

   		

endmodule

