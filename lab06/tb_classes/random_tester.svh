class random_tester extends base_tester;

    `uvm_component_utils (random_tester)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    protected function action_t generate_action();
        action_t action;
        automatic bit randomize_res = std::randomize(action) with {
            action dist { RESET_ACTION := 1, OPERATION_ACTION := 3 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $fatal(1, "Generating action failed");
        end
        return action;
    endfunction : generate_action

    protected function bit [2:0] generate_operation();
        return 3'($random);
    endfunction : generate_operation

    protected function bit [31:0] generate_operand();
        bit [31:0] operand;
        automatic bit randomize_res = std::randomize(operand) with {
            operand dist { 0 := 1, [1:32'hfffffffe] :/ 2, 32'hffffffff := 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $fatal(1, "Generating random operand failed");
        end
        return operand;
    endfunction : generate_operand

    protected function bit [2:0] generate_removed_packets_number();
        bit [2:0] removed_packets_number;
        automatic bit randomize_res = std::randomize(removed_packets_number) with {
            removed_packets_number dist { 0 := 4, [1:4] :/ 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $fatal(1, "Generating number of packets to remove failed");
        end
        return removed_packets_number;
    endfunction : generate_removed_packets_number

    protected function bit generate_should_randomize_crc();
        bit should_randomize;
        automatic bit randomize_res = std::randomize(should_randomize) with {
            should_randomize dist { 0 := 3, 1 := 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $fatal(1, "Generating crc randomize flag failed");
        end
        return should_randomize;
    endfunction : generate_should_randomize_crc

    protected function in_crc_t generate_in_crc(bit [31:0] X, bit [31:0] Y, bit [2:0] operation,
            bit invalid_crc);
        automatic bit [67:0] d = {X, Y, 1'b1, operation};
        static in_crc_t c = 0;
        automatic in_crc_t crc = {
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
        if (invalid_crc) begin
            in_crc_t invalid_crc;
            do begin
                invalid_crc = in_crc_t'($random);
            end while (invalid_crc === crc);
            return invalid_crc;
        end else begin
            return crc;
        end
    endfunction : generate_in_crc

endclass : random_tester
