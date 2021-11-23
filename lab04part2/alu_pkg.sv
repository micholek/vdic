package alu_pkg;
    typedef enum bit {
        TEST_STATE = 0,
        SCORE_AND_COV_STATE = 1
    } tb_state_t;

    typedef enum bit [2:0] {
        AND_OPERATION = 3'b000,
        OR_OPERATION = 3'b001,
        ADD_OPERATION = 3'b100,
        SUB_OPERATION = 3'b101
    } operation_t;
    `define ALL_OPERATIONS AND_OPERATION, OR_OPERATION, ADD_OPERATION, SUB_OPERATION

    typedef enum bit {
        RESET_ACTION = 0,
        OPERATION_ACTION = 1
    } action_t;

    typedef struct packed {
        bit carry;
        bit overflow;
        bit zero;
        bit negative;
    } flags_t;

    typedef struct packed {
        bit data;
        bit crc;
        bit op;
    } error_flags_t;

    typedef struct packed {
        bit [31:0] C;
        flags_t flags;
        error_flags_t error_flags;
        bit [2:0] crc;
        bit parity;
    } alu_output_t;

    typedef bit [3:0] in_crc_t;
    typedef bit [2:0] out_crc_t;

    typedef bit [10:0] packet_t;

    typedef packet_t[0:8] in_packets_t;
    typedef packet_t[0:4] out_packets_t;
endpackage : alu_pkg
