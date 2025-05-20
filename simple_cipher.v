module gage_ingage_cipher #(
    parameter CAPACITY = 512,
    parameter RATE = 64,
    parameter INTERNAL_STATE_SIZE = 576,
    parameter ROUNDS = 32,
    parameter BLOCK_SIZE = 64,
    parameter KEY_SIZE = 64
)(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [KEY_SIZE-1:0] key,
    input wire [BLOCK_SIZE-1:0] plaintext,
    output reg [BLOCK_SIZE-1:0] ciphertext,
    output reg done
);

    // Состояния FSM
    localparam IDLE = 1'b0;
    localparam PROCESSING = 1'b1;

    reg state;
    reg [2:0] counter; // Счетчик для имитации задержки

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            ciphertext <= 0;
            counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= PROCESSING;
                        counter <= 3'b1; // Начинаем счет
                    end
                end

                PROCESSING: begin
                    if (counter == 3'b0) begin
                        // "Шифрование" - просто инвертируем биты для примера
                        ciphertext <= plaintext ^ {BLOCK_SIZE{1'b1}};
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        counter <= counter - 1;
                    end
                end
            endcase
        end
    end

endmodule