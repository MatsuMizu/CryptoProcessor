module cbc_mode #(
    parameter BLOCK_SIZE = 64,
    parameter KEY_SIZE = 64,
    parameter CAPACITY = 512,
    parameter INTERNAL_STATE_SIZE = 576,
    parameter ROUNDS = 32,
    parameter MAX_BLOCKS = 1024  // Максимальное число блоков
)(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [KEY_SIZE-1:0] key,
    input wire [BLOCK_SIZE-1:0] iv,
    input wire [BLOCK_SIZE*MAX_BLOCKS-1:0] plaintext,  // Входные данные (все блоки)
    input wire [15:0] num_blocks,  // Количество блоков (1..MAX_BLOCKS)
    output reg [BLOCK_SIZE*MAX_BLOCKS-1:0] ciphertext,  // Выходные данные
    output reg done
);

    // Внутренние сигналы
    reg [BLOCK_SIZE-1:0] feedback;
    wire [BLOCK_SIZE-1:0] xor_out;
    wire [BLOCK_SIZE-1:0] cipher_out;
    reg cipher_start;
    wire cipher_done;
    reg [15:0] block_counter;
    wire [BLOCK_SIZE-1:0] current_plaintext;  // Изменено с reg на wire

    // FSM состояния
    parameter IDLE = 2'b00;
    parameter LOAD_BLOCK = 2'b01;
    parameter ENCRYPT = 2'b10;
    parameter DONE_STATE = 2'b11;
    reg [1:0] state;

    // Выбор текущего блока plaintext
    assign current_plaintext = plaintext[block_counter*BLOCK_SIZE +: BLOCK_SIZE];

    // XOR с обратной связью (CBC)
    assign xor_out = current_plaintext ^ feedback;

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
        .start(cipher_start),
        .key(key),
        .plaintext(xor_out),
        .ciphertext(cipher_out),
        .done(cipher_done)
    );

    // Основной FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            feedback <= iv;
            block_counter <= 0;
            done <= 0;
            cipher_start <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        feedback <= iv;  // Инициализация IV
                        block_counter <= 0;
                        state <= LOAD_BLOCK;
                    end
                end

                LOAD_BLOCK: begin
                    cipher_start <= 1;
                    state <= ENCRYPT;
                end

                ENCRYPT: begin
                    cipher_start <= 0;
                    if (cipher_done) begin
                        // Сохраняем шифртекст для текущего блока
                        ciphertext[block_counter*BLOCK_SIZE +: BLOCK_SIZE] <= cipher_out;
                        feedback <= cipher_out;  // Обновляем обратную связь
                        
                        if (block_counter == num_blocks - 1) begin
                            state <= DONE_STATE;
                        end else begin
                            block_counter <= block_counter + 1;
                            state <= LOAD_BLOCK;
                        end
                    end
                end

                DONE_STATE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule