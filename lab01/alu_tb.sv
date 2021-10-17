module alu_tb;

    typedef enum bit [2:0] {
        AND_OPERATION = 3'b000,
        OR_OPERATION = 3'b001,
        ADD_OPERATION = 3'b100,
        SUB_OPERATION = 3'b101
    } operation_t;

    typedef bit [3:0] in_crc_t;
    typedef bit [2:0] out_crc_t;

    typedef bit [10:0] packet_t;

    typedef packet_t[0:8] in_packets_t;

    bit clk;
    bit rst_n;
    bit sin;
    wire sout;

    int A;
    int B;
    bit [2:0] operation;
    in_packets_t in_packets;

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
            A = generate_operand();
            B = generate_operand();
            operation = generate_operation();

            in_packets = create_in_packets(A, B, operation);
            foreach (in_packets[i,j]) begin : tester_send_packet
                @(negedge clk);
                sin = in_packets[i][j];
            end

            begin : tester_temp_check
                // Temporary checking if the structure of data stream is correct.
                automatic bit [98:0] in_stream = in_packets;
                automatic int actual_A = {
                    in_stream[96-:8], in_stream[85-:8], in_stream[74-:8], in_stream[63-:8]
                };
                automatic int actual_B = {
                    in_stream[52-:8], in_stream[41-:8], in_stream[30-:8], in_stream[19-:8]
                };
                automatic byte actual_cmd_payload = in_stream[8-:8];
                assert({in_stream[98], in_stream[87], in_stream[76], in_stream[65], in_stream[54],
                            in_stream[43], in_stream[32], in_stream[21], in_stream[10]}
                        === 9'b000000000)
                else begin
                    $display("Invalid first bits of packets");
                    test_result = "FAILED";
                end
                assert({in_stream[97], in_stream[86], in_stream[75], in_stream[64], in_stream[53],
                            in_stream[42], in_stream[31], in_stream[20], in_stream[9]}
                        === 9'b000000001)
                else begin
                    $display("Invalid second bits of packets");
                    test_result = "FAILED";
                end
                assert({in_stream[88], in_stream[77], in_stream[66], in_stream[55], in_stream[44],
                            in_stream[33], in_stream[22], in_stream[11], in_stream[0]}
                        === 9'b111111111)
                else begin
                    $display("Invalid last bits of packets");
                    test_result = "FAILED";
                end
                assert(actual_A === A)
                else begin
                    $display("Invalid first operand (expected: %0d, actual: %0d", A, actual_A);
                    test_result = "FAILED";
                end
                assert(actual_B === B)
                else begin
                    $display("Invalid second operand (expected: %0d, actual: %0d", B, actual_B);
                    test_result = "FAILED";
                end
                assert(actual_cmd_payload === {1'b0, operation, calculate_in_crc(A, B, operation)})
                else begin
                    $display("Invalid cmd packet payload for A = %0d, B = %0d, op = %0d", A, B,
                        operation, "(actual: %0h)", actual_cmd_payload);
                    test_result = "FAILED";
                end
            end
        end

        $finish;
    end

    final begin : finish_of_the_test
        $display("Test %s", test_result);
    end

    function bit [2:0] generate_operation();
        return 3'($random);
    endfunction : generate_operation

    function int generate_operand();
        int operand;
        automatic bit randomize_res = std::randomize(operand) with {
            operand dist { 0 := 1, [1:32'hfffffffe] :/ 2, 32'hffffffff := 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $display("Generating random operand failed");
            test_result = "FAILED";
        end
        return operand;
    endfunction : generate_operand

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

    function in_packets_t create_in_packets(int X, int Y, bit [2:0] operation);
        automatic in_crc_t crc = calculate_in_crc(X, Y, operation);
        return {
            create_data_packet(X[31:24]),
            create_data_packet(X[23:16]),
            create_data_packet(X[15:8]),
            create_data_packet(X[7:0]),
            create_data_packet(Y[31:24]),
            create_data_packet(Y[23:16]),
            create_data_packet(Y[15:8]),
            create_data_packet(Y[7:0]),
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

endmodule : alu_tb
