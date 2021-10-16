module alu_tb;

    typedef enum bit [2:0] {
        AND_OPERATION = 3'b000,
        OR_OPERATION = 3'b001,
        ADD_OPERATION = 3'b100,
        SUB_OPERATION = 3'b101
    } operation_t;

    typedef bit [3:0] in_crc_t;

    typedef bit [10:0] packet_t;

    typedef packet_t[0:8] in_packets_t;

    bit clk;
    bit rst_n;
    bit sin;
    wire sout;

    int A;
    int B;
    operation_t operation;
    in_packets_t in_packets;
    packet_t out_packets[0:4];

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

        A = 10;
        B = 20;
        operation = ADD_OPERATION;

        in_packets = create_in_packets(A, B, operation);
        foreach (in_packets[i,j]) begin : tester_send_packet
            @(negedge clk);
            sin = in_packets[i][j];
        end

        @(negedge sout);
        foreach (out_packets[i,j]) begin
            @(negedge clk);
            out_packets[i][j] = sout;
            if (i === 0 && j === 0 && is_cmd_packet(out_packets[0])) begin
                break;
            end
        end

        #2000 $finish;
    end

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

    function in_packets_t create_in_packets(int X, int Y, operation_t operation);
        automatic in_crc_t crc = calculate_in_crc(Y, X, operation);
        return {
            create_data_packet(Y[31:24]),
            create_data_packet(Y[23:16]),
            create_data_packet(Y[15:8]),
            create_data_packet(Y[7:0]),
            create_data_packet(X[31:24]),
            create_data_packet(X[23:16]),
            create_data_packet(X[15:8]),
            create_data_packet(X[7:0]),
            create_cmd_packet({1'b0, operation, crc})
        };
    endfunction : create_in_packets

    function in_crc_t calculate_in_crc(int X, int Y, operation_t operation);
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
