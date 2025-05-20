# CryptoProcessor with ECB, CBC, CTR Encryption Modes

## Project Description
Verilog implementation of a crypto processor supporting three block cipher modes:
- ECB (Electronic Codebook)
- CBC (Cipher Block Chaining)
- CTR (Counter)

Uses a simplified block cipher algorithm for demonstration purposes.

## Key Parameters
| Parameter            | Value | Description              |
|----------------------|-------|--------------------------|
| BLOCK_SIZE           | 64    | Data block size (bits)   |
| KEY_SIZE             | 64    | Encryption key size (bits) |
| ROUNDS               | 32    | Number of rounds         |
| MAX_BLOCKS           | 1024  | Maximum blocks to process |

## Interface
Main control signals:
- `clk`, `reset` - clock and reset
- `start` - processing trigger
- `mode[1:0]` - operation mode (00=ECB, 01=CBC, 10=CTR)  
- `key` - encryption key
- `iv_nonce` - initialization vector
- `plaintext` - input data
- `ciphertext` - output result
- `done` - completion flag

## Example Implementation
```verilog
// Example bit-inversion cipher (for testing)
ciphertext <= plaintext ^ {BLOCK_SIZE{1'b1}};
