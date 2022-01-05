package alu_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

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

    typedef bit [3:0] in_crc_t;

    typedef struct packed {
        bit [31:0] A;
        bit [31:0] B;
        bit [2:0] removed_packets_from_A;
        bit [2:0] removed_packets_from_B;
        bit [2:0] operation;
        bit invalid_crc;
        in_crc_t crc;
        action_t action;
    } alu_input_t;

    typedef bit [2:0] out_crc_t;

    typedef struct packed {
        bit [31:0] C;
        flags_t flags;
        error_flags_t error_flags;
        out_crc_t crc;
        bit parity;
    } alu_output_t;

    typedef bit [10:0] packet_t;

    typedef packet_t[0:8] in_packets_t;
    typedef packet_t[0:4] out_packets_t;

    typedef enum {
        COLOR_BOLD_BLACK_ON_GREEN,
        COLOR_BOLD_BLACK_ON_RED,
        COLOR_BOLD_BLACK_ON_YELLOW,
        COLOR_BOLD_BLUE_ON_WHITE,
        COLOR_BLUE_ON_WHITE,
        COLOR_DEFAULT
    } print_color;

    function void set_print_color(print_color c);
        string ctl;
        case(c)
            COLOR_BOLD_BLACK_ON_GREEN: ctl = "\033\[1;30m\033\[102m";
            COLOR_BOLD_BLACK_ON_RED: ctl = "\033\[1;30m\033\[101m";
            COLOR_BOLD_BLACK_ON_YELLOW: ctl = "\033\[1;30m\033\[103m";
            COLOR_BOLD_BLUE_ON_WHITE: ctl= "\033\[1;34m\033\[107m";
            COLOR_BLUE_ON_WHITE: ctl = "\033\[0;34m\033\[107m";
            COLOR_DEFAULT: ctl = "\033\[0m\n";
            default: begin
                $error("set_print_color: bad argument");
                ctl = "";
            end
        endcase
        $write(ctl);
    endfunction : set_print_color

    `include "env_config.svh"
    `include "alu_agent_config.svh"

    `include "random_alu_input_transaction.svh"
    `include "min_max_alu_input_transaction.svh"
    `include "result_transaction.svh"

    `include "coverage.svh"
    `include "tester.svh"
    `include "scoreboard.svh"
    `include "driver.svh"
    `include "alu_input_monitor.svh"
    `include "result_monitor.svh"
    `include "alu_agent.svh"
    `include "env.svh"

    `include "dual_test.svh"

endpackage : alu_pkg
