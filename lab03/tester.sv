module tester(alu_bfm bfm);
    import alu_pkg::*;

    function action_t generate_action();
        action_t action;
        automatic bit randomize_res = std::randomize(action) with {
            action dist { RESET_ACTION := 1, OPERATION_ACTION := 3 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $error("Generating action failed");
            bfm.test_result = "FAILED";
            $finish;
        end
        return action;
    endfunction : generate_action

    function bit [2:0] generate_operation();
        return 3'($random);
    endfunction : generate_operation

    function bit [31:0] generate_operand(bit [2:0] removed_packets);
        bit [31:0] operand;
        automatic bit randomize_res = std::randomize(operand) with {
            operand dist { 0 := 1, [1:32'hfffffffe] :/ 2, 32'hffffffff := 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $error("Generating random operand failed");
            bfm.test_result = "FAILED";
            $finish;
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
            $error("Generating number of packets to remove failed");
            bfm.test_result = "FAILED";
            $finish;
        end
        return removed_packets_number;
    endfunction : generate_removed_packets_number

    function bit generate_should_randomize_crc();
        bit should_randomize;
        automatic bit randomize_res = std::randomize(should_randomize) with {
            should_randomize dist { 0 := 3, 1 := 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $error("Generating crc randomize flag failed");
            bfm.test_result = "FAILED";
            $finish;
        end
        return should_randomize;
    endfunction : generate_should_randomize_crc

    function packet_t create_cmd_packet(byte payload);
        return {2'b01, payload, 1'b1};
    endfunction : create_cmd_packet

    function packet_t create_data_packet(byte payload);
        return {2'b00, payload, 1'b1};
    endfunction : create_data_packet

    function in_crc_t calculate_in_crc(bit [31:0] X, bit [31:0] Y, bit [2:0] operation);
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

    function in_packets_t create_in_packets(bit [31:0] X, bit [31:0] Y, bit [2:0] operation,
            bit [2:0] removed_packets_from_X, bit [2:0] removed_packets_from_Y);
        in_crc_t random_crc;
        automatic in_crc_t crc = calculate_in_crc(X, Y, operation);
        bfm.should_randomize_crc = generate_should_randomize_crc();
        if (bfm.should_randomize_crc) begin
            do begin
                random_crc = in_crc_t'($random);
            end while (random_crc === crc);
        end
        return {
            removed_packets_from_X > 0 ? 11'b11111111111 : create_data_packet(X[31:24]),
            removed_packets_from_X > 1 ? 11'b11111111111 : create_data_packet(X[23:16]),
            removed_packets_from_X > 2 ? 11'b11111111111 : create_data_packet(X[15:8]),
            removed_packets_from_X > 3 ? 11'b11111111111 : create_data_packet(X[7:0]),
            removed_packets_from_Y > 0 ? 11'b11111111111 : create_data_packet(Y[31:24]),
            removed_packets_from_Y > 1 ? 11'b11111111111 : create_data_packet(Y[23:16]),
            removed_packets_from_Y > 2 ? 11'b11111111111 : create_data_packet(Y[15:8]),
            removed_packets_from_Y > 3 ? 11'b11111111111 : create_data_packet(Y[7:0]),
            create_cmd_packet({1'b0, operation, bfm.should_randomize_crc ? random_crc : crc})
        };
    endfunction : create_in_packets

    initial begin
        in_packets_t in_packets;

        bfm.reset_alu();
        repeat(1000) begin
            wait(bfm.tb_state === TEST_STATE);
            bfm.action = generate_action();
            if (bfm.action === RESET_ACTION) begin
                bfm.reset_alu();
                continue;
            end

            bfm.removed_packets_from_A = generate_removed_packets_number();
            bfm.removed_packets_from_B = generate_removed_packets_number();
            bfm.A = generate_operand(bfm.removed_packets_from_A);
            bfm.B = generate_operand(bfm.removed_packets_from_B);
            bfm.operation = generate_operation();
            in_packets = create_in_packets(bfm.A, bfm.B, bfm.operation, bfm.removed_packets_from_A,
                bfm.removed_packets_from_B);
            bfm.send_packets(in_packets);
            bfm.tb_state = SCORE_AND_COV_STATE;
        end

        $finish;
    end
endmodule : tester
