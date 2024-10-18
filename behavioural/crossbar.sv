module crossbar #(
  parameter DATA_WIDTH=32, MAX_PACKET_LEN=8, NET_ADDR=4, 
  parameter ADDRX = 0, ADDRY = 0
)(
  input Clock,
  input nReset, 
  // slave interface
  input logic  Ch_M_Req_XP, Ch_M_Req_XN, Ch_M_Req_YP, Ch_M_Req_YN, Ch_M_Req_PE,
  input logic  Ch_S_Req_XP, Ch_S_Req_XN, Ch_S_Req_YP, Ch_S_Req_YN, Ch_S_Req_PE,
  output logic Ch_Ack_XP, Ch_Ack_XN, Ch_Ack_YP, Ch_Ack_YN, Ch_Ack_PE, 
  input logic [DATA_WIDTH-1:0] Ch_Data_XP, Ch_Data_XN, Ch_Data_YP, Ch_Data_YN, Ch_Data_PE,
  // buffer destination address
  input logic [3:0] Des_Addr_XP, Des_Addr_XN, Des_Addr_YP, Des_Addr_YN, Des_Addr_PE,
  // buffer packet length and out pointer
  input logic [7:0] Ctr_XP, Ctr_XN, Ctr_YP, Ctr_YN, Ctr_PE,
  input logic [7:0] Ptr_XP, Ptr_XN, Ptr_YP, Ptr_YN, Ptr_PE,
  // master interface
  output logic M_Req_XP, M_Req_XN, M_Req_YP, M_Req_YN, M_Req_PE,
  input  logic M_Ack_XP, M_Ack_XN, M_Ack_YP, M_Ack_YN, M_Ack_PE,
  output logic [DATA_WIDTH-1:0] M_Data_XP, M_Data_XN, M_Data_YP, M_Data_YN, M_Data_PE
);

timeunit 1ns;
timeprecision 100ps;
  
  // buffer channel request signal = Ch_S_Req | Ch_M_Req
  logic Ch_Req_XP, Ch_Req_XN, Ch_Req_YP, Ch_Req_YN, Ch_Req_PE;

  always_comb begin
    Ch_Req_XP = Ch_S_Req_XP | Ch_M_Req_XP;
    Ch_Req_XN = Ch_S_Req_XN | Ch_M_Req_XN;
    Ch_Req_YP = Ch_S_Req_YP | Ch_M_Req_YP;
    Ch_Req_YN = Ch_S_Req_YN | Ch_M_Req_YN;
    Ch_Req_PE = Ch_S_Req_PE | Ch_M_Req_PE;
  end

  // state machine viarables
  typedef enum logic [2:0] {IDLE_XP, XNtoXP, YPtoXP, YNtoXP, PEtoXP} XP_state_type;
  XP_state_type XP_present_state, XP_next_state;

  typedef enum logic [2:0] {IDLE_XN, XPtoXN, YPtoXN, YNtoXN, PEtoXN} XN_state_type;
  XN_state_type XN_present_state, XN_next_state;

  typedef enum logic [2:0] {IDLE_YP, XPtoYP, XNtoYP, YNtoYP, PEtoYP} YP_state_type;
  YP_state_type YP_present_state, YP_next_state;

  typedef enum logic [2:0] {IDLE_YN, XPtoYN, XNtoYN, YPtoYN, PEtoYN} YN_state_type;
  YN_state_type YN_present_state, YN_next_state;

  typedef enum logic [2:0] {IDLE_PE, XPtoPE, XNtoPE, YPtoPE, YNtoPE} PE_state_type;
  PE_state_type PE_present_state, PE_next_state;

  logic [1:0] Nodex_Addr, Nodey_Addr;
  logic [3:0] Node_Addr;

  assign Nodex_Addr = ADDRX;
  assign Nodey_Addr = ADDRY;
  assign Node_Addr = {Nodex_Addr, Nodey_Addr};

  ///////////////////////////////
  // state machine
  ///////////////////////////////


  ///////////////////////////////
  // XP output state machine 
  ///////////////////////////////

  // PRESENT STATE ASSIGNMENTS
  always_ff @(posedge Clock, negedge nReset)
	if ( ! nReset )
		XP_present_state <= IDLE_XP;
	else
		XP_present_state <= XP_next_state;

  // NEXT STATE ASSIGNMENTS
  always_comb begin
	XP_next_state = IDLE_XP;

    case(XP_present_state)
    IDLE_XP: begin
        if( Des_Addr_XN[3:2] > Node_Addr[3:2] && Ch_Req_XN && (YP_present_state != XNtoYP) && (YN_present_state != XNtoYN) && (PE_present_state != XNtoPE) )
            XP_next_state = XNtoXP;
        else if( Des_Addr_YP[3:2] > Node_Addr[3:2] && Ch_Req_YP && (XN_present_state != YPtoXN) && (YN_present_state != YPtoYN) && (PE_present_state != YPtoPE) )
            XP_next_state = YPtoXP;
        else if( Des_Addr_YN[3:2] < Node_Addr[3:2] && Ch_Req_YN && (XN_present_state != YNtoXN) && (YP_present_state != YNtoYP) && (PE_present_state != YNtoPE) )
            XP_next_state = YNtoXP;
        else if( Des_Addr_PE[3:2] > Node_Addr[3:2] && Ch_Req_PE && (XN_present_state != PEtoXN) && (YP_present_state != PEtoYP) && (YN_present_state != PEtoYN) )
            XP_next_state = PEtoXP;
    end
    XNtoXP: begin
        if( Ptr_XN < Ctr_XN )
            XP_next_state = XNtoXP;
    end
    YPtoXP: begin
        if( Ptr_YP < Ctr_YP )
            XP_next_state = YPtoXP;
    end
    YNtoXP: begin
        if( Ptr_YN < Ctr_YN )
            XP_next_state = YNtoXP;
    end
    PEtoXP: begin
        if( Ptr_PE < Ctr_PE )
            XP_next_state = PEtoXP;
    end
    endcase
  end

  // multiplexer
  always_comb begin
    M_Req_XP = 0;
    M_Data_XP = '0;
    case(XP_present_state)
    XNtoXP:begin
        M_Req_XP  = Ch_M_Req_XN;
        M_Data_XP = Ch_Data_XN;
    end
    YPtoXP: begin
        M_Req_XP  = Ch_M_Req_YP;
        M_Data_XP = Ch_Data_YP;
    end
    YNtoXP: begin
        M_Req_XP  = Ch_M_Req_YN;
        M_Data_XP = Ch_Data_YN;
    end
    PEtoXP: begin
        M_Req_XP  = Ch_M_Req_PE;
        M_Data_XP = Ch_Data_PE;
    end
    endcase
  end

  ///////////////////////////////
  // XN output state machine 
  ///////////////////////////////

  // PRESENT STATE ASSIGNMENTS
  always_ff @(posedge Clock, negedge nReset)
	if ( ! nReset )
		XN_present_state <= IDLE_XN;
	else
		XN_present_state <= XN_next_state;

  // NEXT STATE ASSIGNMENTS
  always_comb begin
	XN_next_state = IDLE_XN;

    case(XN_present_state)
    IDLE_XN: begin
        if( (Des_Addr_XP[3:2] < Node_Addr[3:2]) && Ch_Req_XP && (YP_present_state != XPtoYP) && (YN_present_state != XPtoYN) && (PE_present_state != XPtoPE) )
            XN_next_state = XPtoXN;
        else if( (Des_Addr_YP[3:2] < Node_Addr[3:2]) && Ch_Req_YP && (XP_present_state != YPtoXP) && (YN_present_state != YPtoYN) && (PE_present_state != YPtoPE) )
            XN_next_state = YPtoXN;
        else if( (Des_Addr_YN[3:2] < Node_Addr[3:2]) && Ch_Req_YN && (XP_present_state != YNtoXP) && (YP_present_state != YNtoYP) && (PE_present_state != YNtoPE) )
            XN_next_state = YNtoXN;
        else if( (Des_Addr_PE[3:2] < Node_Addr[3:2]) && Ch_Req_PE && (XP_present_state != PEtoXP) && (YP_present_state != PEtoYP) && (YN_present_state != PEtoYN) )
            XN_next_state = PEtoXN;
    end
    XPtoXN: begin
        if( Ptr_XP < Ctr_XP )
            XN_next_state = XPtoXN;
    end
    YPtoXN: begin
        if( Ptr_YP < Ctr_YP )
            XN_next_state = YPtoXN;
    end
    YNtoXN: begin
        if( Ptr_YN < Ctr_YN )
            XN_next_state = YNtoXN;
    end
    PEtoXN: begin
        if( Ptr_PE < Ctr_PE )
            XN_next_state = PEtoXN;
    end
    endcase
  end

  // multiplexer
  always_comb begin
    M_Req_XN = 0;
    M_Data_XN = '0;
    case(XN_present_state)
    XPtoXN:begin
        M_Req_XN  = Ch_M_Req_XP;
        M_Data_XN = Ch_Data_XP;
    end
    YPtoXN: begin
        M_Req_XN  = Ch_M_Req_YP;
        M_Data_XN = Ch_Data_YP;
    end
    YNtoXN: begin
        M_Req_XN  = Ch_M_Req_YN;
        M_Data_XN = Ch_Data_YN;
    end
    PEtoXN: begin
        M_Req_XN  = Ch_M_Req_PE;
        M_Data_XN = Ch_Data_PE;
    end
    endcase
  end

  ///////////////////////////////
  // YP output state machine 
  ///////////////////////////////

  // PRESENT STATE ASSIGNMENTS
  always_ff @(posedge Clock, negedge nReset)
    if ( !nReset )
		YP_present_state <= IDLE_YP;
	else
		YP_present_state <= YP_next_state;

  // NEXT STATE ASSIGNMENTS
  always_comb begin
    YP_next_state = IDLE_YP;
    case(YP_present_state)
    IDLE_YP: begin
        if(Des_Addr_XP[3:2] == Node_Addr[3:2] && Des_Addr_XP[1:0] > Node_Addr[1:0] && Ch_Req_XP  && (XN_present_state != XPtoXN) && (YN_present_state != XPtoYN) && (PE_present_state != XPtoPE) )
            YP_next_state = XPtoYP;
        else if(Des_Addr_XN[3:2] == Node_Addr[3:2] && Des_Addr_XN[1:0] > Node_Addr[1:0] && Ch_Req_XN && (XP_present_state != XNtoXP) && (YN_present_state != XNtoYN) && (PE_present_state != XNtoPE) )
            YP_next_state = XNtoYP;
        else if(Des_Addr_YN[3:2] == Node_Addr[3:2] && Des_Addr_YN[1:0] > Node_Addr[1:0] && Ch_Req_YN && (XP_present_state != YNtoXP) && (XN_present_state != YNtoXN) && (PE_present_state != YNtoPE) )
            YP_next_state = YNtoYP;
        else if(Des_Addr_PE[3:2] == Node_Addr[3:2] && Des_Addr_PE[1:0] > Node_Addr[1:0] && Ch_Req_PE && (XP_present_state != PEtoXP) && (XN_present_state != PEtoXN) && (YN_present_state != PEtoYN) )
            YP_next_state = PEtoYP;
    end
    XPtoYP: begin
        if( Ptr_XP < Ctr_XP )
            YP_next_state = XPtoYP;
    end
    XNtoYP: begin
        if( Ptr_XN < Ctr_XN )
            YP_next_state = XNtoYP;
    end
    YNtoYP: begin
        if( Ptr_YN < Ctr_YN )
            YP_next_state = YNtoYP;
    end
    PEtoYP: begin
        if( Ptr_PE < Ctr_PE )
            YP_next_state = PEtoYP;
    end
    endcase
  end

    // multiplexer
  always_comb begin
    M_Req_YP = 0;
    M_Data_YP = '0;
    case(YP_present_state)
    XPtoYP: begin
		M_Req_YP = Ch_M_Req_XP;
		M_Data_YP = Ch_Data_XP;
    end
    XNtoYP: begin
		M_Req_YP = Ch_M_Req_XN;
		M_Data_YP = Ch_Data_XN;
    end
    YNtoYP: begin
		M_Req_YP = Ch_M_Req_YN;
		M_Data_YP = Ch_Data_YN;
    end
    PEtoYP: begin
		M_Req_YP = Ch_M_Req_PE;
		M_Data_YP = Ch_Data_PE;
    end
    endcase
  end

  ///////////////////////////////
  // YN output state machine 
  ///////////////////////////////

  always_ff @(posedge Clock, negedge nReset)
    if ( !nReset )
		YN_present_state <= IDLE_YN;
	else
		YN_present_state <= YN_next_state;

  always_comb begin
    YN_next_state = IDLE_YN;
    case(YN_present_state)
    IDLE_YN: begin
        if(Des_Addr_XP[3:2] == Node_Addr[3:2] && Des_Addr_XP[1:0] < Node_Addr[1:0] &&  Ch_Req_XP && (XN_present_state != XPtoXN) && (YP_present_state != XPtoYP) && (PE_present_state != XPtoPE) )
            YN_next_state = XPtoYN;
        else if(Des_Addr_XN[3:2] == Node_Addr[3:2] && Des_Addr_XN[1:0] < Node_Addr[1:0] && Ch_Req_XN && (XP_present_state != XNtoXP) && (YP_present_state != XNtoYP) && (PE_present_state != XNtoPE) )
            YN_next_state = XNtoYN;
        else if(Des_Addr_YP[3:2] == Node_Addr[3:2] && Des_Addr_YP[1:0] < Node_Addr[1:0] && Ch_Req_YP && (XP_present_state != YPtoXP) && (XN_present_state != YPtoXN) && (PE_present_state != YPtoPE) )
            YN_next_state = YPtoYN;
        else if(Des_Addr_PE[3:2] == Node_Addr[3:2] && Des_Addr_PE[1:0] < Node_Addr[1:0] && Ch_Req_PE && (XP_present_state != PEtoXP) && (XN_present_state != PEtoXN) && (YP_present_state != PEtoYP) )
            YN_next_state = PEtoYN;
    end
    XPtoYN: begin
        if( Ptr_XP < Ctr_XP )
            YN_next_state = XPtoYN;
    end
    XNtoYN: begin
        if( Ptr_XN < Ctr_XN )
            YN_next_state = XNtoYN;
    end
    YPtoYN: begin
        if( Ptr_YP < Ctr_YP )
            YN_next_state = YPtoYN;
    end
    PEtoYN: begin
        if( Ptr_PE < Ctr_PE )
            YN_next_state = PEtoYN;
    end
    endcase
  end

    // multiplexer
  always_comb begin
    M_Req_YN = 0;
    M_Data_YN = '0;
    case(YN_present_state)
    XPtoYN: begin
		M_Req_YN = Ch_M_Req_XP;
		M_Data_YN = Ch_Data_XP;
    end
    XNtoYN: begin
		M_Req_YN = Ch_M_Req_XN;
		M_Data_YN = Ch_Data_XN;
    end
    YPtoYN: begin
		M_Req_YN = Ch_M_Req_YP;
		M_Data_YN = Ch_Data_YP;
    end
    PEtoYN: begin
		M_Req_YN = Ch_M_Req_PE;
		M_Data_YN = Ch_Data_PE;
    end
    endcase
  end

  ///////////////////////////////
  // PE output state machine 
  ///////////////////////////////

  // present state
  always_ff @(posedge Clock, negedge nReset)
	if ( ! nReset )
		PE_present_state <= IDLE_PE;
	else
		PE_present_state <= PE_next_state;
    
  // next state
  always_comb begin
	PE_next_state = IDLE_PE;
    case(PE_present_state)
    IDLE_PE: begin
        if( Des_Addr_XP == Node_Addr && Ch_Req_XP && (XN_present_state != XPtoXN) && (YP_present_state != XPtoYP) && (YN_present_state != XPtoYN) )
            PE_next_state = XPtoPE;
        else if( Des_Addr_XN == Node_Addr && Ch_Req_XN && (XP_present_state != XNtoXP) && (YP_present_state != XNtoYP) && (YN_present_state != XNtoYN) )
            PE_next_state = XNtoPE;
        else if( Des_Addr_YP == Node_Addr && Ch_Req_YP && (XP_present_state != YPtoXP) && (XN_present_state != YPtoXN) && (YN_present_state != YPtoYN) )
            PE_next_state = YPtoPE;
        else if( Des_Addr_YN == Node_Addr && Ch_Req_YN && (XP_present_state != YNtoXP) && (XN_present_state != YNtoXN) && (YP_present_state != YNtoYP) )
            PE_next_state = YNtoPE;
    end
    XPtoPE: begin
        if( Ptr_XP < Ctr_XP )
            PE_next_state = XPtoPE;
    end
    XNtoPE: begin
        if( Ptr_XN < Ctr_XN )
            PE_next_state = XNtoPE;
    end
    YPtoPE: begin
        if( Ptr_YP < Ctr_YP )
            PE_next_state = YPtoPE;
    end
    YNtoPE: begin
        if( Ptr_YN < Ctr_YN )
            PE_next_state = YNtoPE;
    end
    endcase
  end

  // multiplexer
  always_comb begin
    M_Req_PE = 0;
    M_Data_PE = '0;
    case(PE_present_state)
    XPtoPE: begin
        M_Req_PE = Ch_M_Req_XP;
        M_Data_PE = Ch_Data_XP;
    end
    XNtoPE: begin
        M_Req_PE = Ch_M_Req_XN;
        M_Data_PE = Ch_Data_XN;
    end
    YPtoPE:begin
        M_Req_PE = Ch_M_Req_YP;
        M_Data_PE = Ch_Data_YP;
    end
    YNtoPE:begin
        M_Req_PE = Ch_M_Req_YN;
        M_Data_PE = Ch_Data_YN;
    end
    endcase
  end

  ///////////////////////////////
  // Ack feedback multiplexer
  ///////////////////////////////

  // XP Ack feedback multiplexer
  always_comb begin
    Ch_Ack_XP = 0;
    if(XN_present_state == XPtoXN)
        Ch_Ack_XP = M_Ack_XN;
    else if(YP_present_state == XPtoYP)
        Ch_Ack_XP = M_Ack_YP;
    else if(YN_present_state == XPtoYN)
        Ch_Ack_XP = M_Ack_YN;
    else if(PE_present_state == XPtoPE)
        Ch_Ack_XP = M_Ack_PE;
  end

  // XN Ack feedback multiplexer
  always_comb begin
    Ch_Ack_XN = 0;
    if(XP_present_state == XNtoXP)
        Ch_Ack_XN = M_Ack_XP;
    else if(YP_present_state == XNtoYP)
        Ch_Ack_XN = M_Ack_YP;
    else if(YN_present_state == XNtoYN)
        Ch_Ack_XN = M_Ack_YN;
    else if(PE_present_state == XNtoPE)
        Ch_Ack_XN = M_Ack_PE;
  end

  // YP Ack feedback multiplexer
  always_comb begin
    Ch_Ack_YP = 0;
    if(XP_present_state == YPtoXP)
        Ch_Ack_YP = M_Ack_XP;
    else if(XN_present_state == YPtoXN)
        Ch_Ack_YP = M_Ack_XN;
    else if(YN_present_state == YPtoYN)
        Ch_Ack_YP = M_Ack_YN;
    else if(PE_present_state == YPtoPE)
        Ch_Ack_YP = M_Ack_PE;
  end

  // YN Ack feedback multiplexer
  always_comb begin
    Ch_Ack_YN = 0;
    if(XP_present_state == YNtoXP)
        Ch_Ack_YN = M_Ack_XP;
    else if(XN_present_state == YNtoXN)
        Ch_Ack_YN = M_Ack_XN;
    else if(YP_present_state == YNtoYP)
        Ch_Ack_YN = M_Ack_YP;
    else if(PE_present_state == YNtoPE)
        Ch_Ack_YN = M_Ack_PE;
  end

  // PE Ack feedback multiplexer
  always_comb begin
    Ch_Ack_PE = 0;
    if(XP_present_state == PEtoXP)
        Ch_Ack_PE = M_Ack_XP;
    else if(XN_present_state == PEtoXN)
        Ch_Ack_PE = M_Ack_XN;
    else if(YP_present_state == PEtoYP)
        Ch_Ack_PE = M_Ack_YP;
    else if(YN_present_state == PEtoYN)
        Ch_Ack_PE = M_Ack_YN;
  end

endmodule
