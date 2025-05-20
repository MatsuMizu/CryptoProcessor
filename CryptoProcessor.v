module CryptoProcessor #(
    parameter BLOCK_SIZE = 64,
    parameter KEY_SIZE = 64,
    parameter CAPACITY = 512,
    parameter INTERNAL_STATE_SIZE = 576,
    parameter ROUNDS = 32,
    parameter MAX_BLOCKS = 1024
)(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [1:0] mode,
    input wire [KEY_SIZE-1:0] key,
    input wire [BLOCK_SIZE-1:0] iv_nonce,
    input wire [BLOCK_SIZE*MAX_BLOCKS-1:0] plaintext,
    input wire [15:0] num_blocks,
    output wire [BLOCK_SIZE*MAX_BLOCKS-1:0] ciphertext,
    output wire done
);

    // Внутренние сигналы
    wire [BLOCK_SIZE*MAX_BLOCKS-1:0] ecb_ciphertext, cbc_ciphertext, ctr_ciphertext;
    wire ecb_done, cbc_done, ctr_done;
    wire [15:0] dummy_num_blocks = num_blocks; // Для совместимости с ECB

    // Модуль ECB
    ecb_mode #(
        .BLOCK_SIZE(BLOCK_SIZE),
        .KEY_SIZE(KEY_SIZE),
        .MAX_BLOCKS(MAX_BLOCKS)
    ) ecb_inst (
        .clk(clk),
        .reset(reset),
        .start(start && (mode == 2'b00)),
        .key(key),
        .plaintext(plaintext),
        .num_blocks(dummy_num_blocks),
        .ciphertext(ecb_ciphertext),
        .done(ecb_done),
        .ready()
    );

    // Модуль CBC
    cbc_mode #(
        .BLOCK_SIZE(BLOCK_SIZE),
        .KEY_SIZE(KEY_SIZE),
        .CAPACITY(CAPACITY),
        .INTERNAL_STATE_SIZE(INTERNAL_STATE_SIZE),
        .ROUNDS(ROUNDS),
        .MAX_BLOCKS(MAX_BLOCKS)
    ) cbc_inst (
        .clk(clk),
        .reset(reset),
        .start(start && (mode == 2'b01)),
        .key(key),
        .iv(iv_nonce),
        .plaintext(plaintext),
        .num_blocks(num_blocks),
        .ciphertext(cbc_ciphertext),
        .done(cbc_done)
    );

    // Модуль CTR
    ctr_mode #(
        .BLOCK_SIZE(BLOCK_SIZE),
        .KEY_SIZE(KEY_SIZE),
        .CAPACITY(CAPACITY),
        .INTERNAL_STATE_SIZE(INTERNAL_STATE_SIZE),
        .ROUNDS(ROUNDS),
        .MAX_BLOCKS(MAX_BLOCKS)
    ) ctr_inst (
        .clk(clk),
        .reset(reset),
        .start(start && (mode == 2'b10)),
        .key(key),
        .nonce(iv_nonce),
        .plaintext(plaintext),
        .num_blocks(num_blocks),
        .ciphertext(ctr_ciphertext),
        .done(ctr_done)
    );

    // Мультиплексирование выходов
    assign ciphertext = (mode == 2'b00) ? ecb_ciphertext :
                       (mode == 2'b01) ? cbc_ciphertext :
                       (mode == 2'b10) ? ctr_ciphertext :
                       {BLOCK_SIZE*MAX_BLOCKS{1'b0}};

    assign done = (mode == 2'b00) ? ecb_done :
                 (mode == 2'b01) ? cbc_done :
                 (mode == 2'b10) ? ctr_done :
                 1'b0;

endmodule