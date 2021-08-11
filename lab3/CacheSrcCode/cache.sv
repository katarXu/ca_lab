

module cache #(
    parameter  LINE_ADDR_LEN = 3, // line�ڵ�ַ���ȣ�������ÿ��line����2^3��word
    parameter  SET_ADDR_LEN  = 3, // ���ַ���ȣ�������һ����2^3=8��
    parameter  TAG_ADDR_LEN  = 6, // tag����
    parameter  WAY_CNT       = 3  // �������ȣ�������ÿ�����ж���·line��������ֱ��ӳ����cache����˸ò���û�õ�
)(
    input  clk, rst,
    output miss,               // ��CPU������miss�ź�
    input  [31:0] addr,        // ��д�����ַ
    input  rd_req,             // �������ź�
    output reg [31:0] rd_data, // ���������ݣ�һ�ζ�һ��word
    input  wr_req,             // д�����ź�
    input  [31:0] wr_data      // Ҫд������ݣ�һ��дһ��word
);

localparam MEM_ADDR_LEN    = TAG_ADDR_LEN + SET_ADDR_LEN ; // ���������ַ���� MEM_ADDR_LEN�������С=2^MEM_ADDR_LEN��line
localparam UNUSED_ADDR_LEN = 32 - TAG_ADDR_LEN - SET_ADDR_LEN - LINE_ADDR_LEN - 2 ;       // ����δʹ�õĵ�ַ�ĳ���

localparam LINE_SIZE       = 1 << LINE_ADDR_LEN  ;         // ���� line �� word ���������� 2^LINE_ADDR_LEN ��word ÿ line
localparam SET_SIZE        = 1 << SET_ADDR_LEN   ;         // ����һ���ж����飬�� 2^SET_ADDR_LEN ����

reg [            31:0] cache_mem    [SET_SIZE][WAY_CNT][LINE_SIZE]; // SET_SIZE���飬ÿ������WAY_CNT��line��ÿ��line��LINE_SIZE��word
reg [TAG_ADDR_LEN-1:0] cache_tags   [SET_SIZE][WAY_CNT];            // SET_SIZE*WAY_CNT��TAG
reg                    valid        [SET_SIZE][WAY_CNT];            // SET_SIZE*WAY_CNT��valid(��Чλ)
reg                    dirty        [SET_SIZE][WAY_CNT];            // SET_SIZE*WAY_CNT��dirty(��λ)

wire [              2-1:0]   word_addr;                   // �������ַaddr��ֳ���5������
wire [  LINE_ADDR_LEN-1:0]   line_addr;
wire [   SET_ADDR_LEN-1:0]    set_addr;
wire [   TAG_ADDR_LEN-1:0]    tag_addr;
wire [UNUSED_ADDR_LEN-1:0] unused_addr;

enum  {IDLE, SWAP_OUT, SWAP_IN, SWAP_IN_OK} cache_stat;    // cache ״̬����״̬����
                                                           // IDLE���������SWAP_OUT�������ڻ�����SWAP_IN�������ڻ��룬SWAP_IN_OK����������һ���ڵ�д��cache������

reg  [   SET_ADDR_LEN-1:0] mem_rd_set_addr = 0;
reg  [   TAG_ADDR_LEN-1:0] mem_rd_tag_addr = 0;
wire [   MEM_ADDR_LEN-1:0] mem_rd_addr = {mem_rd_tag_addr, mem_rd_set_addr};
reg  [   MEM_ADDR_LEN-1:0] mem_wr_addr = 0;

reg  [31:0] mem_wr_line [LINE_SIZE];
wire [31:0] mem_rd_line [LINE_SIZE];

wire mem_gnt;      // ������Ӧ��д�������ź�

assign {unused_addr, tag_addr, set_addr, line_addr, word_addr} = addr;  // ��� 32bit ADDR

reg cache_hit = 1'b0;

enum {FIFO, LRU} strategy;    //��������
integer lru_time;   //lruʱ���¼
reg [WAY_CNT - 1: 0] hit_addr; //����λ��
reg [WAY_CNT - 1: 0] replace_addr; //����λ��
reg [15: 0] lru_record[SET_SIZE][WAY_CNT]; //ÿ?���LRU��¼
reg [WAY_CNT: 0] fifo_record[SET_SIZE][WAY_CNT]; //ÿ?���ڵ�FIFO��λ��¼


always @ (*) begin              // �ж� �����address �Ƿ��� cache ������
    cache_hit = 1'b0;
    for(integer i = 0; i < WAY_CNT; i = i + 1)
    begin
        if(valid[set_addr][i] && cache_tags[set_addr][i] == tag_addr)   // ��� cache line��Ч������tag�������ַ�е�tag��ȣ�������
        begin
            cache_hit = 1'b1;
            hit_addr = i;
            break;
        end
    end                    
end
always@(*) 
begin
    if (~cache_hit & (wr_req | rd_req))
    begin
        if(strategy == LRU)
        begin
            replace_addr = 0;
            for (integer i = 1; i < WAY_CNT; i = i + 1)
            begin
                if (lru_record[set_addr][i] < lru_record[set_addr][replace_addr])
                    replace_addr = i;
            end
        end
        else if(strategy == FIFO)
        begin
            automatic integer free = 0;
            for (integer i = 0;i < WAY_CNT ;i = i + 1 )
            begin
                if (fifo_record[set_addr][i] == 0)
                begin
                    replace_addr = i;
                    free = 1;
                    break;
                end
            end
            if (free == 0)
            begin
                for (integer i = 0;i < WAY_CNT ;i = i + 1)
                begin
                    if (fifo_record[set_addr][i] == WAY_CNT)
                    begin
                        replace_addr = i;
                        fifo_record[set_addr][i] = 0;
                        break;
                    end
                end
            end
            if (fifo_record[set_addr][replace_addr] == 0)
            begin
                for (integer i = 0;i < WAY_CNT ;i = i + 1 )
                    fifo_record[set_addr][i] = fifo_record[set_addr][i] + 1;
            end
        end
    end
end
always @ (posedge clk or posedge rst) begin     // ?? cache ???
    if(rst) begin
        cache_stat <= IDLE;
        lru_time <= 0;
        strategy <= LRU;//FIFO
        //strategy <= FIFO;
        for(integer i = 0; i < SET_SIZE; i++) begin
            for(integer j = 0; j < WAY_CNT; j = j + 1)
            begin
                dirty[i][j] = 1'b0;
                valid[i][j] = 1'b0;
                lru_record[i][j] = 0;
                fifo_record[i][j] = 0;
            end
        end
        for(integer k = 0; k < LINE_SIZE; k++)
            mem_wr_line[k] <= 0;
        mem_wr_addr <= 0;
        {mem_rd_tag_addr, mem_rd_set_addr} <= 0;
        rd_data <= 0;
    end else begin
        lru_time = lru_time + 1;
        case(cache_stat)
        IDLE:       begin
                        if(cache_hit) begin
                            if(rd_req) begin    // ���cache���У������Ƕ�����
                                rd_data <= cache_mem[set_addr][hit_addr][line_addr];   //��ֱ�Ӵ�cache��ȡ��Ҫ��������
                            end else if(wr_req) begin // ���cache���У�������д����
                                cache_mem[set_addr][hit_addr][line_addr] <= wr_data;   // ��ֱ����cache��д������
                                dirty[set_addr][hit_addr] <= 1'b1;                     // д���ݵ�ͬʱ����λ
                            end 
                            lru_record[set_addr][hit_addr] <= lru_time;
                        end else begin
                            if(wr_req | rd_req) begin   // ��� cache δ���У������ж�д��������Ҫ���л���
                                if(valid[set_addr][replace_addr] & dirty[set_addr][replace_addr]) begin    // ��� Ҫ�����cache line ������Ч�����࣬����Ҫ�Ƚ�������
                                    cache_stat  <= SWAP_OUT;
                                    mem_wr_addr <= {cache_tags[set_addr][replace_addr], set_addr};
                                    mem_wr_line <= cache_mem[set_addr][replace_addr];
                                end else begin                                   // ��֮������Ҫ������ֱ�ӻ���
                                    cache_stat  <= SWAP_IN;
                                end
                                {mem_rd_tag_addr, mem_rd_set_addr} <= {tag_addr, set_addr};
                            end
                        end
                    end
        SWAP_OUT:   begin
                        if(mem_gnt) begin           // ������������ź���Ч��˵�������ɹ���������һ״̬
                            cache_stat <= SWAP_IN;
                        end
                    end
        SWAP_IN:    begin
                        if(mem_gnt) begin           // ������������ź���Ч��˵������ɹ���������һ״̬
                            cache_stat <= SWAP_IN_OK;
                        end
                    end
        SWAP_IN_OK: begin           // ��һ�����ڻ���ɹ��������ڽ����������lineд��cache��������tag���ø�valid���õ�dirty
                        for(integer i=0; i<LINE_SIZE; i++)  cache_mem[mem_rd_set_addr][replace_addr][i] <= mem_rd_line[i];
                        cache_tags[mem_rd_set_addr][replace_addr] <= mem_rd_tag_addr;
                        valid     [mem_rd_set_addr][replace_addr] <= 1'b1;
                        dirty     [mem_rd_set_addr][replace_addr] <= 1'b0;
                        lru_record[mem_rd_set_addr][replace_addr] <= lru_time;
                        cache_stat <= IDLE;        // �ص�����״̬
                    end
        endcase
    end
end

wire mem_rd_req = (cache_stat == SWAP_IN );
wire mem_wr_req = (cache_stat == SWAP_OUT);
wire [   MEM_ADDR_LEN-1 :0] mem_addr = mem_rd_req ? mem_rd_addr : ( mem_wr_req ? mem_wr_addr : 0);

assign miss = (rd_req | wr_req) & ~(cache_hit && cache_stat==IDLE) ;     // �� �ж�д����ʱ�����cache�����ھ���(IDLE)״̬������δ���У���miss=1

main_mem #(     // ���棬ÿ�ζ�д��line Ϊ��λ
    .LINE_ADDR_LEN  ( LINE_ADDR_LEN          ),
    .ADDR_LEN       ( MEM_ADDR_LEN           )
) main_mem_instance (
    .clk            ( clk                    ),
    .rst            ( rst                    ),
    .gnt            ( mem_gnt                ),
    .addr           ( mem_addr               ),
    .rd_req         ( mem_rd_req             ),
    .rd_line        ( mem_rd_line            ),
    .wr_req         ( mem_wr_req             ),
    .wr_line        ( mem_wr_line            )
);

endmodule





