`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: NPC_Generator
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Choose Next PC value
//////////////////////////////////////////////////////////////////////////////////
//����˵��
    //NPC_Generator����������Next PCֵ��ģ�飬���ݲ�ͬ����ת�ź�ѡ��ͬ����PCֵ
//����
    //PCF              �ɵ�PCֵ
    //JalrTarget       jalrָ��Ķ�Ӧ����תĿ��
    //BranchTarget     branchָ��Ķ�Ӧ����תĿ��
    //JalTarget        jalָ��Ķ�Ӧ����תĿ��
    //BranchE==1       Ex�׶ε�Branchָ��ȷ����ת
    //JalD==1          ID�׶ε�Jalָ��ȷ����ת
    //JalrE==1         Ex�׶ε�Jalrָ��ȷ����ת
//���
    //PC_In            NPC��ֵ
//ʵ��Ҫ��  
    //��ȫģ��

module NPC_Generator(
    input wire [31:0] PCF,JalrTarget, BranchTarget, JalTarget,
    input wire BranchE,JalD,JalrE,
    output reg [31:0] PC_In
    );
    always@(*)
    begin
        if(BranchE) PC_In <= BranchTarget;
        else if(JalrE) PC_In <= JalrTarget;
        else if(JalD) PC_In <= JalTarget;
        else PC_In <= PCF + 4;
    end
    
endmodule
