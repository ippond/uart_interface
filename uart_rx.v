`timescale 1ns/100ps
module uart_rx
#(
parameter C_BAUD_RATE  = 115200    ,            //baud rate,unit is Hz
parameter C_CLK_FREQ   = 100000000 ,            //I_clk frequency,unit is Hz
parameter C_DATA_WIDTH = 8         ,            //data width, default is 8
parameter C_STOP_WIDTH = 1         ,            //stop bit number, default is 1, 1.5 should set to 2
parameter C_CHECK      = 1         ,            //check bit setting, 0 means none, 1 means even, 2 means odd
parameter C_MSB        = 0                      //data order, 1 means msb, 0 means lsb, default is lsb
)
(
input                          I_clk         ,  //clock
input                          I_rst         ,  //sync reset,high valid
input                          I_rx          ,  //uart rx port
output reg  [C_DATA_WIDTH-1:0] O_data = 0    ,  //receive data
output reg                     O_data_v = 0     //receive data valid,high valid 
);

localparam C_BIT_PERIOD = C_CLK_FREQ/C_BAUD_RATE-1;
localparam C_BIT_HALF_PERIOD = C_BIT_PERIOD/2-1;
localparam C_BIT_NUM = C_DATA_WIDTH + 1 + (C_CHECK != 0) + C_STOP_WIDTH - 1;
localparam C_BIT_PERIOD_WIDTH = F_width(C_BIT_PERIOD);
localparam C_BIT_NUM_WIDTH = F_width(C_BIT_NUM);

reg S_rx_v = 0;
reg [C_BIT_PERIOD_WIDTH-1:0] S_bit_cnt = 0;
reg [C_BIT_NUM_WIDTH-1:0] S_bit_num = 0;
reg S_check_right = 0;
reg S_stop_right = 0;
reg S_rx = 0;

always @(posedge I_clk)
begin
    S_rx <= I_rx;
    if(I_rst)
        S_rx_v <= 1'b0;
    else if(!I_rx && S_rx)
        S_rx_v <= 1'b1;
    else if(((S_bit_cnt == C_BIT_HALF_PERIOD) && (C_BIT_NUM == S_bit_num)) || (S_bit_num == 'd0 && S_bit_cnt < C_BIT_HALF_PERIOD && I_rx))
        S_rx_v <= 1'b0;
end

always @(posedge I_clk)
begin
    if(!S_rx_v || (S_bit_cnt == C_BIT_PERIOD))
        S_bit_cnt <= 'd0;
    else
        S_bit_cnt <= S_bit_cnt + 'd1;
    
    if(!S_rx_v || ((S_bit_cnt == C_BIT_HALF_PERIOD) && (C_BIT_NUM == S_bit_num)))
        S_bit_num <= 'd0;
    else if(S_bit_cnt == C_BIT_PERIOD)
        S_bit_num <= S_bit_num + 'd1;
end

assign S_check_bit = (C_CHECK == 1) ? (^O_data) : !(^O_data);

always @(posedge I_clk)
begin
    if(S_bit_num>'d0 && S_bit_num<=C_DATA_WIDTH && S_bit_cnt == C_BIT_HALF_PERIOD)
        O_data <= C_MSB ? {O_data[C_DATA_WIDTH-2:0],I_rx} : {I_rx,O_data[C_DATA_WIDTH-1:1]};
    if((S_bit_num == C_DATA_WIDTH+1) && (S_bit_cnt == C_BIT_HALF_PERIOD))
        S_check_right <= (C_CHECK == 0) ? 1'b1 : (I_rx == S_check_bit);
    if(!I_rx && S_rx)
        S_stop_right <= 1'b1;
    else if(S_bit_num>C_BIT_NUM-C_STOP_WIDTH && S_bit_num<=C_BIT_NUM && S_bit_cnt == C_BIT_HALF_PERIOD)
        S_stop_right <= S_stop_right && I_rx;
    
    if((S_bit_cnt == C_BIT_HALF_PERIOD) && (C_BIT_NUM == S_bit_num))
        O_data_v <= S_check_right && S_stop_right;
    else
        O_data_v <= 1'b0;
end

function integer F_width;
input integer I_num;
integer i;
begin
    for(i=0;2**i<=I_num;i=i+1)
    F_width = i;
    F_width = i;
end
endfunction

endmodule
