module ecb_mode #(
    parameter BLOCK_SIZE = 64,      // Размер блока (например, 128 бит для AES)
    parameter KEY_SIZE = 64,        // Размер ключа
    parameter MAX_BLOCKS = 1024      // Максимальное число блоков
)(
    input wire clk,                  // Тактовый сигнал
    input wire reset,                // Сброс
    input wire start,                // Сигнал начала шифрования
    input wire [KEY_SIZE-1:0] key,   // Ключ шифрования
    input wire [BLOCK_SIZE*MAX_BLOCKS-1:0] plaintext, // Входные данные (все блоки)
    input wire [15:0] num_blocks,    // Фактическое число блоков (1..MAX_BLOCKS)
    output reg [BLOCK_SIZE*MAX_BLOCKS-1:0] ciphertext, // Выходные данные
    output reg done,                 // Сигнал завершения
    output reg ready                 // Готовность принять новый блок
);

    // Внутренние сигналы
    wire [BLOCK_SIZE-1:0] current_plaintext;  // Изменено с reg на wire
    wire [BLOCK_SIZE-1:0] block_cipher_output;
    reg block_cipher_start;
    wire block_cipher_done;
    reg [15:0] block_counter;

    // Выбор текущего блока
    assign current_plaintext = plaintext[block_counter*BLOCK_SIZE +: BLOCK_SIZE];

    // Инстанс блочного шифра
    gage_ingage_cipher #(
        .BLOCK_SIZE(BLOCK_SIZE),
        .KEY_SIZE(KEY_SIZE)
    ) cipher (
        .clk(clk),
        .reset(reset),
        .start(block_cipher_start),
        .key(key),
        .plaintext(current_plaintext),
        .ciphertext(block_cipher_output),
        .done(block_cipher_done)
    );

    // FSM состояния
    localparam IDLE    = 2'b00;
    localparam LOAD    = 2'b01;
    localparam ENCRYPT = 2'b10;
    localparam DONE_ST = 2'b11;
    reg [1:0] state;

    // Логика конечного автомата
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            ready <= 1;
            block_cipher_start <= 0;
            block_counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1;
                    if (start) begin
                        ready <= 0;
                        block_counter <= 0;
                        state <= LOAD;
                    end
                end

                LOAD: begin
                    block_cipher_start <= 1;
                    state <= ENCRYPT;
                end

                ENCRYPT: begin
                    block_cipher_start <= 0;
                    if (block_cipher_done) begin
                        // Сохраняем результат для текущего блока
                        ciphertext[block_counter*BLOCK_SIZE +: BLOCK_SIZE] <= block_cipher_output;
                        
                        if (block_counter == num_blocks - 1) begin
                            state <= DONE_ST;
                        end else begin
                            block_counter <= block_counter + 1;
                            state <= LOAD;
                        end
                    end
                end

                DONE_ST: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule