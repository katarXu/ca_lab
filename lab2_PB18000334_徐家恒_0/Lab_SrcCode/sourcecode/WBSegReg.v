`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: WBSegReg
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Write Back Segment Register
//////////////////////////////////////////////////////////////////////////////////
//����˵��
    //WBSegReg��Write Back�μĴ�����
    //������IDSegReg.V�ж�Bram�ĵ��ú���չ����ͬʱ������һ��ͬ����д��Bram
    //���˴�����Ե��������ṩ��InstructionRam���������Զ��ۺ�Ϊblock memory����Ҳ��������Եĵ���xilinx��bram ip�ˣ���
    //ͬ����memory �൱�� �첽��memory ��������D����������Ҫʱ�������ز��ܶ�ȡ���ݡ�
    //��ʱ�����ͨ���μĴ������棬��ô��Ҫ����ʱ�������ز��ܽ����ݴ��ݵ�Ex��
    //����ڶμĴ���ģ���е��ø�ͬ��memory��ֱ�ӽ�������ݵ�WB������߼�
    //����memģ������ΪRD_raw��ͨ��assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw );
    //�Ӷ�ʵ��RD�μĴ���stall��clear����
//ʵ��Ҫ��  
    //����Ҫ��ȫWBSegRegģ�飬�貹ȫ��Ƭ�ν�ȡ����
    //DataRam DataRamInst (
    //    .clk    (???),                      //请完善代�?
    //    .wea    (???),                      //请完善代�?
    //    .addra  (???),                      //请完善代�?
    //    .dina   (???),                      //请完善代�?
    //    .douta  ( RD_raw         ),
    //    .web    ( WE2            ),
    //    .addrb  ( A2[31:2]       ),
    //    .dinb   ( WD2            ),
    //    .doutb  ( RD2            )
    //);   
//ע������
    //���뵽DataRam��addra���ֵ�ַ��һ����32bit
    //�����DataExtģ��ʵ�ַ��ֶ����ֽ�load
    //��ͨ����ȫ����ʵ�ַ��ֶ���store


module WBSegReg(
    input wire clk,
    input wire en,
    input wire clear,
    //Data Memory Access
    input wire [31:0] A,
    input wire [31:0] WD,
    input wire [3:0] WE,
    output wire [31:0] RD,
    output reg [1:0] LoadedBytesSelect,
    //Data Memory Debug
    input wire [31:0] A2,
    input wire [31:0] WD2,
    input wire [3:0] WE2,
    output wire [31:0] RD2,
    //input control signals
    input wire [31:0] ResultM,
    output reg [31:0] ResultW, 
    input wire [4:0] RdM,
    output reg [4:0] RdW,
    //output constrol signals
    input wire [2:0] RegWriteM,
    output reg [2:0] RegWriteW,
    input wire MemToRegM,
    output reg MemToRegW
    );
    
    //
    initial begin
        LoadedBytesSelect = 2'b00;
        RegWriteW         =  1'b0;
        MemToRegW         =  1'b0;
        ResultW           =     0;
        RdW               =  5'b0;
    end
    //
    always@(posedge clk)
        if(en) begin
            LoadedBytesSelect <= clear ? 2'b00 : A[1:0];
            RegWriteW         <= clear ?  1'b0 : RegWriteM;
            MemToRegW         <= clear ?  1'b0 : MemToRegM;
            ResultW           <= clear ?     0 : ResultM;
            RdW               <= clear ?  5'b0 : RdM;
        end

    wire [31:0] RD_raw;
    DataRam DataRamInst (
        .clk    ( clk            ),                      //�����ƴ���
        .wea    ( WE << A[1:0]           ),                      //�����ƴ���?
        .addra  ( A[31:2]        ),                      //�����ƴ���
        .dina   ( WD << (8 * A[1:0])           ),                      //�����ƴ���?
        .douta  ( RD_raw         ),
        .web    ( WE2            ),
        .addrb  ( A2[31:2]       ),
        .dinb   ( WD2            ),
        .doutb  ( RD2            )
    );   
    // Add clear and stall support
    // if chip not enabled, output output last read result
    // else if chip clear, output 0
    // else output values from bram
    // ���²��������޸�
    reg stall_ff= 1'b0;
    reg clear_ff= 1'b0;
    reg [31:0] RD_old=32'b0;
    always @ (posedge clk)
    begin
        stall_ff<=~en;
        clear_ff<=clear;
        RD_old<=RD_raw;
    end    
    assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw );

endmodule