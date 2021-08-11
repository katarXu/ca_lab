`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: HarzardUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Deal with harzards in pipline
//////////////////////////////////////////////////////////////////////////////////
//����˵��
    //HarzardUnit����������ˮ�߳�ͻ��ͨ���������ݣ�forward�Լ���ˢ��ˮ�ν��������غͿ�����أ�����߼���·
    //�������ʵ�֡�ǰ�ڲ���CPU��ȷ��ʱ��������ÿ����ָ������������ָ�Ȼ��ֱ�Ӱѱ�ģ�������Ϊ����forward����stall����flush 
//����
    //CpuRst                                    �ⲿ�źţ�������ʼ��CPU����CpuRst==1ʱCPUȫ�ָ�λ���㣨���жμĴ���flush����Cpu_Rst==0ʱcpu��ʼִ��ָ��
    //ICacheMiss, DCacheMiss                    Ϊ����ʵ��Ԥ���źţ���ʱ�������ӣ���������cache miss
    //BranchE, JalrE, JalD                      ���������������
    //Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW     ��������������أ��ֱ��ʾԴ�Ĵ���1���룬Դ�Ĵ���2���룬Ŀ��Ĵ�������
    //RegReadE RegReadD[1]==1                   ��ʾA1��Ӧ�ļĴ���ֵ��ʹ�õ��ˣ�RegReadD[0]==1��ʾA2��Ӧ�ļĴ���ֵ��ʹ�õ��ˣ�����forward�Ĵ���
    //RegWriteM, RegWriteW                      ��������������أ�RegWrite!=3'b0˵����Ŀ��Ĵ�����д�����
    //MemToRegE                                 ��ʾEx�ε�ǰָ�� ��Data Memory�м������ݵ��Ĵ�����
//���
    //StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW    ��������μĴ�������stall��ά��״̬���䣩��flush�����㣩
    //Forward1E, Forward2E                                                              ����forward
//ʵ��Ҫ��  
    //��ȫģ��  
    
    
module HarzardUnit(
    input wire CpuRst, ICacheMiss, DCacheMiss, 
    input wire BranchE, JalrE, JalD, 
    input wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
    input wire [1:0] RegReadE,
    input wire MemToRegE,
    input wire [2:0] RegWriteM, RegWriteW,
    output reg StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW,
    output reg [1:0] Forward1E, Forward2E
    );
    always @ (*)
        if(CpuRst)
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b0101010101;
        else if(DCacheMiss | ICacheMiss)
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b1010101010;
        else if(BranchE | JalrE)
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b0001010000;
        else if(MemToRegE & ((RdE==Rs1D)||(RdE==Rs2D)) )
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b1010010000;
        else if(JalD)
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b0001000000;
        else
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b0000000000;
    //Forward Register Source 1
    always@(*)begin
        if( (RegWriteM!=3'b0) && (RegReadE[1]!=0) && (RdM==Rs1E) &&(RdM!=5'b0) )
            Forward1E<=2'b10;
        else if( (RegWriteW!=3'b0) && (RegReadE[1]!=0) && (RdW==Rs1E) &&(RdW!=5'b0) )
            Forward1E<=2'b01;
        else
            Forward1E<=2'b00;
    end
    //Forward Register Source 2
    always@(*)begin
        if( (RegWriteM!=3'b0) && (RegReadE[0]!=0) && (RdM==Rs2E) &&(RdM!=5'b0) )
            Forward2E<=2'b10;
        else if( (RegWriteW!=3'b0) && (RegReadE[0]!=0) && (RdW==Rs2E) &&(RdW!=5'b0) )
            Forward2E<=2'b01;
        else
            Forward2E<=2'b00;
    end      

endmodule

  