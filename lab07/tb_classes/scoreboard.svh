class scoreboard extends uvm_subscriber#(alu_output_t);

    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo#(alu_input_t) alu_input_f;

    string test_result;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        test_result = "PASSED";
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

    protected function alu_output_t get_expected_output(alu_input_t alu_input);
        operation_t op;
        automatic alu_output_t out = alu_output_t'(0);
        automatic bit [32:0] aux_buffer = 33'b0;
        if (alu_input.removed_packets_from_A > 0 || alu_input.removed_packets_from_B > 0) begin
            out.error_flags.data = 1;
        end else if (alu_input.invalid_crc === 1) begin
            out.error_flags.crc = 1;
        end else if ($cast(op, alu_input.operation) === 0) begin
            out.error_flags.op = 1;
        end
        if (out.error_flags != error_flags_t'(0)) begin
            out.parity = ^{1'b1, out.error_flags, out.error_flags};
        end else begin
            automatic bit [31:0] A = alu_input.A;
            automatic bit [31:0] B = alu_input.B;
            case (op)
                AND_OPERATION: begin
                    out.C = A & B;
                end
                OR_OPERATION: begin
                    out.C = A | B;
                end
                ADD_OPERATION: begin
                    aux_buffer = {1'b0, A} + {1'b0, B};
                    out.C = A + B;
                    out.flags.overflow = ~(A[31] ^ B[31]) & (A[31] ^ out.C[31]);
                end
                SUB_OPERATION: begin
                    aux_buffer = {1'b0, A} - {1'b0, B};
                    out.C = A - B;
                    out.flags.overflow = (A[31] ^ B[31]) & (A[31] ^ out.C[31]);
                end
                default: begin
                    $fatal(1, "Unreachable - unexpected operation");
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
        alu_input_f = new ("alu_input_f", this);
    endfunction : build_phase

    function void write(alu_output_t t);
        alu_input_t alu_input;
        alu_output_t alu_output;

        alu_input.action = RESET_ACTION;
        do
            if (!alu_input_f.try_get(alu_input)) begin
                $fatal(1, "Missing command in self checker");
            end
        while (alu_input.action == RESET_ACTION);
        alu_output = get_expected_output(alu_input);
        if (alu_output.error_flags !== error_flags_t'(0)) begin
            assert({t.error_flags, t.error_flags} === {alu_output.error_flags,
                        alu_output.error_flags}) else begin
                $error("Test failed - invalid error flags (actual: %06b, expected: %06b)",
                    {t.error_flags, t.error_flags}, {alu_output.error_flags,
                        alu_output.error_flags},
                    "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d, ",
                    alu_input.A, alu_input.B, alu_input.operation,
                    alu_input.removed_packets_from_A, alu_input.removed_packets_from_B,
                    "random CRC = %0d)", alu_input.invalid_crc);
                test_result = "FAILED";
            end
            assert(t.parity === alu_output.parity) else begin
                $error("Test failed - invalid parity bit (actual: %0d, expected: %0d)",
                    t.parity, alu_output.parity,
                    "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                    alu_input.A, alu_input.B, alu_input.operation,
                    alu_input.removed_packets_from_A, alu_input.removed_packets_from_B);
                test_result = "FAILED";
            end
        end else begin
            bit [54:0] out_stream;
            assert(t.C === alu_output.C) else begin
                $error("Test failed - invalid result (actual: %0h, expected: %0h)",
                    t.C, alu_output.C,
                    "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                    alu_input.A, alu_input.B, alu_input.operation,
                    alu_input.removed_packets_from_A, alu_input.removed_packets_from_B);
            end
            assert(t.flags === alu_output.flags) else begin
                $error("Test failed - invalid flags (actual %04b, expected: %04b)",
                    t.flags, alu_output.flags,
                    "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                    alu_input.A, alu_input.B, alu_input.operation,
                    alu_input.removed_packets_from_A, alu_input.removed_packets_from_B);
            end
            assert(t.crc === alu_output.crc) else begin
                $error("Test failed - invalid CRC (actual %03b, expected: %03b)",
                    t.crc, alu_output.crc,
                    "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                    alu_input.A, alu_input.B, alu_input.operation,
                    alu_input.removed_packets_from_A, alu_input.removed_packets_from_B);
            end
        end
    endfunction : write

    function void report_phase(uvm_phase phase);
        string color = test_result == "PASSED" ? "92" : "91";
        $display("\033[%sm********** Test %s **********\033[m", color, test_result);
    endfunction : report_phase

endclass : scoreboard
