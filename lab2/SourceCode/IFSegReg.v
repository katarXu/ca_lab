`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: IFSegReg
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: PC Register
//////////////////////////////////////////////////////////////////////////////////
//����˵��
    //IDSegReg��IF-ID�μĴ���
//ʵ��Ҫ��  
    //�����޸�

module IFSegReg(
    input wire clk,
    input wire en, clear,
    input wire [31:0] PC_In,
    output reg [31:0] PCF
    );
    initial PCF = 0;
    
    always@(posedge clk)
        if(en) begin
            if(clear)
                PCF <= 0;
            else 
                PCF <= PC_In;
        end
    
endmodule

