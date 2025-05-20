module tb_CryptoProcessor();
    // Параметры теста
    parameter BLOCK_SIZE = 64;
    parameter KEY_SIZE = 64;
    parameter NUM_BLOCKS = 2;
    parameter MAX_BLOCKS = 1024;

    // Сигналы
    reg clk;
    reg reset;
    reg start;
    reg [1:0] mode;
    reg [KEY_SIZE-1:0] key;
    reg [BLOCK_SIZE-1:0] iv_nonce;
    reg [BLOCK_SIZE*MAX_BLOCKS-1:0] plaintext;
    wire [BLOCK_SIZE*MAX_BLOCKS-1:0] ciphertext;
    wire done;
    reg [15:0] num_blocks;
    
    integer i;
    reg [8*8:1] mode_str; // Строка для имени режима

    // Инстанциация тестируемого модуля
    CryptoProcessor #(
        .BLOCK_SIZE(BLOCK_SIZE),
        .KEY_SIZE(KEY_SIZE),
        .MAX_BLOCKS(MAX_BLOCKS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .mode(mode),
        .key(key),
        .iv_nonce(iv_nonce),
        .plaintext(plaintext),
        .num_blocks(num_blocks),
        .ciphertext(ciphertext),
        .done(done)
    );

    // Генерация тактового сигнала
    always #5 clk = ~clk;

    // Определение имени режима для вывода
    always @(mode) begin
        case(mode)
            2'b00: mode_str = "ECB";
            2'b01: mode_str = "CBC";
            2'b10: mode_str = "CTR";
            default: mode_str = "UNKNOWN";
        endcase
    end

    // Основной тестовый процесс
    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        mode = 2'b00;
        key = 64'h0123456789ABCDEF;
        iv_nonce = 64'hFEDCBA9876543210;
        num_blocks = NUM_BLOCKS;
        
        plaintext = {BLOCK_SIZE*MAX_BLOCKS{1'b0}};
        plaintext[0 +: BLOCK_SIZE*NUM_BLOCKS] = {64'hA5A5A5A5A5A5A5A5, 64'hA5A5A5A5A5A5A5A5};

        // Запуск теста
        #20 reset = 0;
        
        $display("\n=== Starting Encryption Test ===");
        $display("Mode: %s", mode_str);
        $display("Key: %h", key);
        $display("IV/Nonce: %h", iv_nonce);
        $display("Number of blocks: %0d", num_blocks);
        
        // Вывод plaintext
        $display("\nPlaintext blocks:");
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
            $display("Block %0d: %h", i, plaintext[i*BLOCK_SIZE +: BLOCK_SIZE]);
        end

        // Запуск шифрования
        #10 start = 1;
        #10 start = 0;
        
        // Ожидание завершения
        wait(done);
        
        // Вывод результатов
        $display("\nCiphertext blocks:");
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
            $display("Block %0d: %h", i, ciphertext[i*BLOCK_SIZE +: BLOCK_SIZE]);
        end
        
        $display("\n=== Test Completed ===");
        $finish;
    end
endmodule