`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Bingnan Chen (cbn990512@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: bht.sv
// Tool Versions: Vivado 2017.4.1
// Description: two-bits prediction file
//////////////////////////////////////////////////////////////////////////////////


//功能说明
    // 实现2-bits分支预测�?
//实验要求  
    // 自行设计

module bht (
    input clk, 
    input rst, 
    input [7:0] tag, 
    input [7:0] tagE, 
    input br, 
    input [6:0] Opcode_EX, 
    output PredictF //预测结果标志
);
//Branch Opcode
localparam BR_OP = 7'b110_0011; 

reg [1:0] Valid[255 : 0] ; 

assign PredictF = Valid[tag][1]; 

localparam A = 2'b00; 
localparam B = 2'b01; 
localparam C = 2'b10; 
localparam D = 2'b11; 

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        for (integer i = 0; i < 256; i++ ) begin
            Valid[i] <= A; 
        end
    end
    else begin
        if (Opcode_EX == BR_OP) begin
            if (br) begin
                Valid[tagE] <= (Valid[tagE] == D) ? D : Valid[tagE] + 2'b01;
            end
            else begin
                Valid[tagE] <= (Valid[tagE] == A) ? A : Valid[tagE] - 2'b01; 
            end
        end
    end
end

endmodule