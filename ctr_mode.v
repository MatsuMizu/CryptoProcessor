module ctr_mode #(
    parameter BLOCK_SIZE = 64,       // Размер блока
    parameter KEY_SIZE = 64,         // Размер ключа
    parameter CAPACITY = 512,        // Sponge capacity
    parameter INTERNAL_STATE_SIZE = 576, // CAPACITY + BLOCK_SIZE
    parameter ROUNDS = 32,           // Число раундов
    parameter MAX_BLOCKS = 1024      // Максимальное число блоков
)(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [KEY_SIZE-1:0] key,
    input wire [BLOCK_SIZE-1:0] nonce,  // Аналог IV в CTR
    input wire [BLOCK_SIZE*MAX_BLOCKS-1:0] plaintext,  // Входные данные (все блоки)
    input wire [15:0] num_blocks,       // Фактическое число блоков (1..MAX_BLOCKS)
    output reg [BLOCK_SIZE*MAX_BLOCKS-1:0] ciphertext, // Выходные данные
    output reg done
);

    // Внутренние сигналы
    reg [BLOCK_SIZE-1:0] counter;
    reg [BLOCK_SIZE-1:0] block_cipher_input;
    wire [BLOCK_SIZE-1:0] block_cipher_output;
    reg block_cipher_start;
    wire block_cipher_done;
    reg [15:0] block_counter;
    wire [BLOCK_SIZE-1:0] current_plaintext;  // Изменено с reg на wire

    // Выбор текущего блока plaintext
    assign current_plaintext = plaintext[block_counter*BLOCK_SIZE +: BLOCK_SIZE];

    // Инстанс шифра
    gage_ingage_cipher #(
        .CAPACITY(CAPACITY),
        .RATE(BLOCK_SIZE),
        .INTERNAL_STATE_SIZE(INTERNAL_STATE_SIZE),
        .ROUNDS(ROUNDS),
        .BLOCK_SIZE(BLOCK_SIZE),
        .KEY_SIZE(KEY_SIZE)
    ) cipher (
        .clk(clk),
        .reset(reset),
        .start(block_cipher_start),
        .key(key),
        .plaintext(block_cipher_input),
        .ciphertext(block_cipher_output),
        .done(block_cipher_done)
    );

    // FSM состояния
    localparam IDLE    = 2'b00;
    localparam ENCRYPT = 2'b01;
    localparam XOR     = 2'b10;
    localparam DONE    = 2'b11;
    reg [1:0] state;

    // FSM логика
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            block_cipher_start <= 0;
            counter <= nonce;
            block_counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        block_counter <= 0;
                        counter <= nonce;  // Сброс счетчика на nonce
                        state <= ENCRYPT;
                    end
                end

                ENCRYPT: begin
                    block_cipher_input <= counter;
                    block_cipher_start <= 1;
                    state <= XOR;
                end

                XOR: begin
                    block_cipher_start <= 0;
                    if (block_cipher_done) begin
                        // XOR текущего блока plaintext с выходом шифра
                        ciphertext[block_counter*BLOCK_SIZE +: BLOCK_SIZE] <= 
                            current_plaintext ^ block_cipher_output;
                        
                        // Инкремент счетчика и переход к следующему блоку
                        counter <= counter + 1;
                        
                        if (block_counter == num_blocks - 1) begin
                            state <= DONE;
                        end else begin
                            block_counter <= block_counter + 1;
                            state <= ENCRYPT;
                        end
                    end
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule