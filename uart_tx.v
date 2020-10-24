`timescale 1ns/100ps
module uart_tx
#(
parameter C_BAUD_RATE  = 115200    ,                 //baud rate,unit is Hz
parameter C_CLK_FREQ   = 100000000 ,                 //I_clk frequency,unit is Hz
parameter C_DATA_WIDTH = 8         ,                 //data width, default is 8
parameter C_STOP_WIDTH = 1         ,                 //stop bit number, default is 1, 1.5 should set to 2
parameter C_CHECK      = 1         ,                 //check bit setting, 0 means none, 1 means even, 2 means odd
parameter C_MSB        = 0                           //data order, 1 means msb, 0 means lsb, default is lsb
)
(
input                          I_clk              ,  //clock
input                          I_rst              ,  //sync reset,high valid
input       [C_DATA_WIDTH-1:0] I_data             ,  //data to be send
input                          I_data_v           ,  //data valid,high valid
output reg                     O_tx = 1'b1        ,  //uart tx port
output reg                     O_tx_ready = 1'b1     //uart transmit is ready,high valid
);

localparam C_BIT_PERIOD = C_CLK_FREQ/C_BAUD_RATE-1;
localparam C_BIT_NUM = C_DATA_WIDTH + 1 + (C_CHECK != 0) + C_STOP_WIDTH - 1;
localparam C_BIT_PERIOD_WIDTH = F_width(C_BIT_PERIOD);
localparam C_BIT_NUM_WIDTH = F_width(C_BIT_NUM);

reg [11:0] S_data = 0;
reg S_data_v = 0;
reg [C_BIT_PERIOD_WIDTH-1:0] S_bit_cnt = 0;
reg [C_BIT_NUM_WIDTH-1:0] S_bit_num = 0;

always @(posedge I_clk)
begin
    if(I_data_v)
    begin
        S_data[C_DATA_WIDTH:0] <= C_MSB ? {F_invert(I_data),1'b0} : {I_data,1'b0};
        S_data[C_DATA_WIDTH+1] <= (C_CHECK == 0) ? 1'b1 : (C_CHECK == 1) ? (^I_data) : !(^I_data);
        S_data[11:C_DATA_WIDTH+2] <= ~0;
    end
    else if(S_data_v && (S_bit_cnt == C_BIT_PERIOD))
    begin
        S_data <= S_data >> 1;
    end
end

always @(posedge I_clk)
begin
    if(I_data_v && O_tx_ready)
        S_data_v <= 1'b1;
    else if(C_BIT_NUM == S_bit_num && S_bit_cnt == C_BIT_PERIOD)
        S_data_v <= 1'b0;
    
    if(I_rst)
        O_tx_ready <= 1'b1;
    else if(S_data_v && O_tx_ready)
        O_tx_ready <= 1'b0;
    else if(S_bit_num == 'd0 && S_bit_cnt == 'd0)
        O_tx_ready <= 1'b1;
    
    if(!S_data_v || (S_bit_cnt == C_BIT_PERIOD))
        S_bit_cnt <= 'd0;
    else
        S_bit_cnt <= S_bit_cnt + 'd1;
    
    if(!S_data_v || ((S_bit_cnt == C_BIT_PERIOD) && (C_BIT_NUM == S_bit_num)))
        S_bit_num <= 'd0;
    else if(S_bit_cnt == C_BIT_PERIOD)
        S_bit_num <= S_bit_num + 'd1;
end

always @(posedge I_clk)
begin
    if(S_data_v && (S_bit_cnt == 'd0))
        O_tx <= S_data[0];
    else if(O_tx_ready)
        O_tx <= 1'b1;
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

function [C_DATA_WIDTH-1:0] F_invert;
input [C_DATA_WIDTH-1:0] I_data;
integer i;
begin

for(i=0;i<C_DATA_WIDTH;i=i+1)
F_invert[i] = I_data[C_DATA_WIDTH-1-i];

end
endfunction

endmodule

