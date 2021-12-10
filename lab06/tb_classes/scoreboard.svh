class scoreboard extends uvm_component;

    `uvm_component_utils(scoreboard)

    virtual alu_bfm bfm;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    protected function out_crc_t calculate_out_crc(bit [31:0] op_result, bit [3:0] out_flags);
        automatic bit [36:0] d = {op_result, 1'b0, out_flags};
        static out_crc_t c = 0;
        return {
            d[36] ^ d[34] ^ d[31] ^ d[30] ^ d[29] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[17] ^
            d[16] ^ d[15] ^ d[13] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[3] ^ d[2] ^ d[1] ^ c[0] ^ c[2],
            d[36] ^ d[35] ^ d[33] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^
            d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^
            c[2],
            d[35] ^ d[32] ^ d[31] ^ d[30] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[18] ^ d[17] ^
            d[16] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[1]
        };
    endfunction : calculate_out_crc

    protected function alu_output_t get_expected_output(bit [31:0] X, bit [31:0] Y,
            bit [2:0] operation, bit [2:0] removed_packets_from_X, bit [2:0] removed_packets_from_Y,
            bit should_randomize_crc);
        operation_t op;
        automatic alu_output_t out = alu_output_t'(0);
        automatic bit [32:0] aux_buffer = 33'b0;
        if (removed_packets_from_X > 0 || removed_packets_from_Y > 0) begin
            out.error_flags.data = 1;
        end else if (should_randomize_crc === 1) begin
            out.error_flags.crc = 1;
        end else if ($cast(op, operation) === 0) begin
            out.error_flags.op = 1;
        end
        if (out.error_flags != error_flags_t'(0)) begin
            out.parity = ^{1'b1, out.error_flags, out.error_flags};
        end else begin
            case (op)
                AND_OPERATION: begin
                    out.C = X & Y;
                end
                OR_OPERATION: begin
                    out.C = X | Y;
                end
                ADD_OPERATION: begin
                    aux_buffer = {1'b0, X} + {1'b0, Y};
                    out.C = X + Y;
                    out.flags.overflow = ~(X[31] ^ Y[31]) & (X[31] ^ out.C[31]);
                end
                SUB_OPERATION: begin
                    aux_buffer = {1'b0, X} - {1'b0, Y};
                    out.C = X - Y;
                    out.flags.overflow = (X[31] ^ Y[31]) & (X[31] ^ out.C[31]);
                end
                default: begin
                    $error("Unreachable - unexpected operation");
                    bfm.test_result = "FAILED";
                    $finish;
                end
            endcase
            out.flags.carry = aux_buffer[32] === 1'b1;
            out.flags.negative = out.C[31] === 1'b1;
            out.flags.zero = out.C === 0;
            out.crc = calculate_out_crc(out.C, out.flags);
            out.error_flags = 3'b000;
        end
        return out;
    endfunction : get_expected_output

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual alu_bfm)::get(null, "*", "bfm", bfm))
            $fatal(1, "Failed to get BFM");
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        packet_t out_error_packet;
        out_packets_t out_success_packets;
        alu_output_t alu_output;
        forever begin
            @(negedge bfm.sout);
            alu_output = get_expected_output(
                bfm.A, bfm.B, bfm.operation, bfm.removed_packets_from_A,
                bfm.removed_packets_from_B, bfm.should_randomize_crc);
            if (alu_output.error_flags !== error_flags_t'(0)) begin
                bfm.receive_error_packet(out_error_packet);
                assert(out_error_packet[7-:2*$bits(error_flags_t)] === {alu_output.error_flags,
                            alu_output.error_flags}) else begin
                    $error("Test failed - invalid error flags (actual: %06b, expected: %06b)",
                        out_error_packet[7-:6], {3'(alu_output.error_flags),
                            3'(alu_output.error_flags)},
                        "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d, ",
                        bfm.A, bfm.B, bfm.operation, bfm.removed_packets_from_A,
                        bfm.removed_packets_from_B, "random CRC = %0d)",
                        bfm.should_randomize_crc);
                    bfm.test_result = "FAILED";
                end
                assert(out_error_packet[1] === alu_output.parity) else begin
                    $error("Test failed - invalid parity bit (actual: %0d, expected: %0d)",
                        out_error_packet[1], alu_output.parity,
                        "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                        bfm.A, bfm.B, bfm.operation, bfm.removed_packets_from_A,
                        bfm.removed_packets_from_B);
                    bfm.test_result = "FAILED";
                end
            end else begin
                bit [54:0] out_stream;
                bit [31:0] actual_C;
                flags_t actual_flags;
                out_crc_t actual_crc;
                bfm.receive_success_packets(out_success_packets);
                out_stream = out_success_packets;
                actual_C = {out_stream[52-:8], out_stream[41-:8], out_stream[30-:8],
                    out_stream[19-:8]};
                assert(actual_C === alu_output.C) else begin
                    $error("Test failed - invalid result (actual: %0h, expected: %0h)",
                        actual_C, alu_output.C,
                        "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                        bfm.A, bfm.B, bfm.operation, bfm.removed_packets_from_A,
                        bfm.removed_packets_from_B);
                end
                actual_flags = out_success_packets[4][7-:$bits(flags_t)];
                assert(actual_flags === alu_output.flags) else begin
                    $error("Test failed - invalid flags (actual %04b, expected: %04b)",
                        actual_flags, alu_output.flags,
                        "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                        bfm.A, bfm.B, bfm.operation, bfm.removed_packets_from_A,
                        bfm.removed_packets_from_B);
                end
                actual_crc = out_success_packets[4][3-:$bits(out_crc_t)];
                assert(actual_crc === alu_output.crc) else begin
                    $error("Test failed - invalid CRC (actual %03b, expected: %03b)",
                        actual_crc, alu_output.crc,
                        "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                        bfm.A, bfm.B, bfm.operation, bfm.removed_packets_from_A,
                        bfm.removed_packets_from_B);
                end
            end
            bfm.tb_state = TEST_STATE;
        end
    endtask : run_phase
    
    function void report_phase(uvm_phase phase);
        string color = bfm.test_result == "PASSED" ? "92" : "91";
        $display("\033[%sm********** Test %s **********\033[m", color, bfm.test_result);
    endfunction : report_phase

endclass : scoreboard
