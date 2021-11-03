module alu_tb;

    typedef enum bit [2:0] {
        AND_OPERATION = 3'b000,
        OR_OPERATION = 3'b001,
        ADD_OPERATION = 3'b100,
        SUB_OPERATION = 3'b101
    } operation_t;

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
        int C;
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

    bit clk;
    bit rst_n;
    bit sin;
    wire sout;

    int A;
    int B;
    bit [2:0] operation;
    in_packets_t in_packets;
    bit [2:0] removed_packets_from_A;
    bit [2:0] removed_packets_from_B;
    action_t action;

    bit data_sent;

    packet_t out_error_packet;
    out_packets_t out_success_packets;
    alu_output_t alu_output;

    string test_result = "PASSED";

    mtm_Alu DUT(
        .clk,
        .rst_n,
        .sin,
        .sout
    );

    initial begin : clk_gen
        clk = 0;
        forever begin : clk_frv
            #10 clk = ~clk;
        end
    end

    initial begin : tester
        reset_alu();

        repeat(1000) begin
            wait(data_sent === 1'b0);
            action = generate_action();
            if (action === RESET_ACTION) begin
                reset_alu();
                continue;
            end

            removed_packets_from_A = generate_removed_packets_number();
            removed_packets_from_B = generate_removed_packets_number();
            A = generate_operand(removed_packets_from_A);
            B = generate_operand(removed_packets_from_B);
            operation = generate_operation();
            in_packets = create_in_packets(A, B, operation, removed_packets_from_A,
                removed_packets_from_B);

            foreach (in_packets[i,j]) begin : tester_send_packet
                @(negedge clk);
                sin = in_packets[i][j];
            end
            data_sent = 1;
        end

        $finish;
    end

    initial begin : scoreboard
        forever begin
            @(negedge sout);
            if (data_sent) begin
                alu_output = get_expected_output(
                    A, B, operation, removed_packets_from_A, removed_packets_from_B);
                if (3'(alu_output.error_flags) !== 3'b000) begin
                    foreach (out_error_packet[i]) begin
                        @(negedge clk);
                        out_error_packet[i] = sout;
                    end
                    assert(out_error_packet[7-:6] === {3'(alu_output.error_flags),
                                3'(alu_output.error_flags)}) else begin
                        $error("Test failed - invalid error flags (actual: %06b, expected: %06b)",
                            out_error_packet[7-:6], {3'(alu_output.error_flags),
                                3'(alu_output.error_flags)},
                            "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                            A, B, operation, removed_packets_from_A, removed_packets_from_B);
                        test_result = "FAILED";
                    end
                    assert(out_error_packet[1] === alu_output.parity) else begin
                        $error("Test failed - invalid parity bit (actual: %0d, expected: %0d)",
                            out_error_packet[1], alu_output.parity,
                            "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                            A, B, operation, removed_packets_from_A, removed_packets_from_B);
                        test_result = "FAILED";
                    end
                end else begin
                    bit [54:0] out_stream;
                    int actual_C;
                    bit [3:0] actual_flags;
                    foreach (out_success_packets[i,j]) begin
                        @(negedge clk);
                        out_success_packets[i][j] = sout;
                    end
                    out_stream = out_success_packets;
                    actual_C = {out_stream[52-:8], out_stream[41-:8], out_stream[30-:8],
                        out_stream[19-:8]};
                    assert(actual_C === alu_output.C) else begin
                        $error("Test failed - invalid result (actual: %0h, expected: %0h)",
                            actual_C, alu_output.C,
                            "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                            A, B, operation, removed_packets_from_A, removed_packets_from_B);
                    end
                    actual_flags = out_success_packets[4][7-:4];
                    assert(actual_flags === alu_output.flags) else begin
                        $error("Test failed - invalid flags (actual %04b, expected: %04b)",
                            actual_flags, alu_output.flags,
                            "\n(A = %0h, B = %0h, operation = %0d, rem_A = %0d, rem_B = %0d)",
                            A, B, operation, removed_packets_from_A, removed_packets_from_B);
                    end
                end
                data_sent = 0;
            end
        end
    end : scoreboard

    final begin : finish_of_the_test
        $display("Test %s", test_result);
    end

    function action_t generate_action();
        action_t action;
        automatic bit randomize_res = std::randomize(action) with {
            action dist { RESET_ACTION := 1, OPERATION_ACTION := 3 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $display("Generating action failed");
            test_result = "FAILED";
        end
        return action;
    endfunction : generate_action

    function bit [2:0] generate_operation();
        return 3'($random);
    endfunction : generate_operation

    function int generate_operand(bit [2:0] removed_packets);
        int operand;
        automatic bit randomize_res = std::randomize(operand) with {
            operand dist { 0 := 1, [1:32'hfffffffe] :/ 2, 32'hffffffff := 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $display("Generating random operand failed");
            test_result = "FAILED";
        end
        if (removed_packets > 0) begin
            operand[31-:8] = 8'b11111111;
        end
        if (removed_packets > 1) begin
            operand[23-:8] = 8'b11111111;
        end
        if (removed_packets > 2) begin
            operand[15-:8] = 8'b11111111;
        end
        if (removed_packets > 3) begin
            operand[7-:8] = 8'b11111111;
        end
        return operand;
    endfunction : generate_operand

    function bit [2:0] generate_removed_packets_number();
        bit [2:0] removed_packets_number;
        automatic bit randomize_res = std::randomize(removed_packets_number) with {
            removed_packets_number dist { 0 := 4, [1:4] :/ 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $display("Generating number of packets to remove failed");
            test_result = "FAILED";
        end
        return removed_packets_number;
    endfunction : generate_removed_packets_number

    task reset_alu();
        sin = 1'b1;
        rst_n = 1'b0;
        @(negedge clk);
        rst_n = 1'b1;
    endtask : reset_alu

    function bit is_cmd_packet(packet_t packet);
        return packet[9] == 1'b1;
    endfunction : is_cmd_packet

    function packet_t create_data_packet(byte payload);
        return {2'b00, payload, 1'b1};
    endfunction : create_data_packet

    function packet_t create_cmd_packet(byte payload);
        return {2'b01, payload, 1'b1};
    endfunction : create_cmd_packet

    function in_packets_t create_in_packets(int X, int Y, bit [2:0] operation,
            bit [2:0] removed_packets_from_X, bit [2:0] removed_packets_from_Y);
        automatic in_crc_t crc = calculate_in_crc(X, Y, operation);
        return {
            removed_packets_from_X > 0 ? 11'b11111111111 : create_data_packet(X[31:24]),
            removed_packets_from_X > 1 ? 11'b11111111111 : create_data_packet(X[23:16]),
            removed_packets_from_X > 2 ? 11'b11111111111 : create_data_packet(X[15:8]),
            removed_packets_from_X > 3 ? 11'b11111111111 : create_data_packet(X[7:0]),
            removed_packets_from_Y > 0 ? 11'b11111111111 : create_data_packet(Y[31:24]),
            removed_packets_from_Y > 1 ? 11'b11111111111 : create_data_packet(Y[23:16]),
            removed_packets_from_Y > 2 ? 11'b11111111111 : create_data_packet(Y[15:8]),
            removed_packets_from_Y > 3 ? 11'b11111111111 : create_data_packet(Y[7:0]),
            create_cmd_packet({1'b0, operation, crc})
        };
    endfunction : create_in_packets

    function in_crc_t calculate_in_crc(int X, int Y, bit [2:0] operation);
        automatic bit [67:0] d = {X, Y, 1'b1, operation};
        static in_crc_t c = 0;
        return {
            d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^
            d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^
            d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^
            d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3],
            d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^
            d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^
            d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^
            d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3],
            d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^
            d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^
            d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^
            d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3],
            d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^
            d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^
            d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^
            d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2]
        };
    endfunction : calculate_in_crc

    function alu_output_t get_expected_output(int X, int Y, bit [2:0] operation,
            bit [2:0] removed_packets_from_X, bit [2:0] removed_packets_from_Y);
        operation_t op;
        automatic alu_output_t out = 0;
        automatic bit error_occured = 0;
        automatic bit [32:0] aux_buffer = 33'b0;
        if (removed_packets_from_X > 0 || removed_packets_from_Y > 0) begin
            out.error_flags.data = 1;
            error_occured = 1;
        end else if ($cast(op, operation) === 0) begin
            out.error_flags.op = 1;
            error_occured = 1;
        end
        if (error_occured) begin
            out.parity = ~(^{1'b1, out.error_flags});
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
                    assert(0) else begin
                        $error("Unreachable - unexpected operation");
                        test_result = "FAILED";
                        $finish;
                    end
                end
            endcase
            out.flags.carry = aux_buffer[32] === 1'b1;
            out.flags.negative = out.C < 0;
            out.flags.zero = out.C === 0;
            out.error_flags = 3'b000;
        end

        return out;
    endfunction : get_expected_output

endmodule : alu_tb
