class scoreboard extends uvm_subscriber#(result_transaction);

    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo#(random_alu_input_transaction) alu_input_f;

    protected string test_result;

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

    protected function result_transaction get_expected_output(
            random_alu_input_transaction alu_input_transaction);
        result_transaction expected = new("expected");
        alu_input_t alu_input = alu_input_transaction.alu_input;
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
        expected.alu_output = out;
        return expected;
    endfunction : get_expected_output

    function void build_phase(uvm_phase phase);
        alu_input_f = new ("alu_input_f", this);
    endfunction : build_phase

    function void write(result_transaction t);
        random_alu_input_transaction random_alu_input_t;
        result_transaction result;
        string result_info;

        do
            if (!alu_input_f.try_get(random_alu_input_t)) begin
                $fatal(1, "Missing command in self checker");
            end
        while (random_alu_input_t.alu_input.action == RESET_ACTION);
        result = get_expected_output(random_alu_input_t);

        result_info = { random_alu_input_t.convert2string(), "\n\t   Actual: ", t.convert2string(),
            "\n\t Expected: ", result.convert2string() };

        if (!result.compare(t)) begin
            `uvm_error("SELF CHECKER", { "FAIL\n", result_info })
            test_result = "FAILED";
        end else begin
            `uvm_info("SELF CHECKER", { "PASS\n", result_info }, UVM_HIGH)
        end
    endfunction : write

    function void report_phase(uvm_phase phase);
        string color = test_result == "PASSED" ? "92" : "91";
        $display("\033[%sm********** Test %s **********\033[m", color, test_result);
    endfunction : report_phase

endclass : scoreboard
