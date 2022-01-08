class random_alu_input_transaction extends uvm_transaction;

    `uvm_object_utils(random_alu_input_transaction)

    rand alu_input_t alu_input;

    constraint data {
        alu_input.action dist { RESET_ACTION := 1, OPERATION_ACTION := 3 };
        alu_input.removed_packets_from_A dist { 0 := 4, [1:4] :/ 1 };
        alu_input.removed_packets_from_B dist { 0 := 4, [1:4] :/ 1 };
        alu_input.invalid_crc dist { 0 := 3, 1 := 1 };
    }

    function void do_copy(uvm_object rhs);
        random_alu_input_transaction copied_transaction_h;
        if (rhs == null) begin
            `uvm_fatal("ALU INPUT TRANSACTION", "Tried to copy from a null pointer")
        end
        super.do_copy(rhs);
        if (!$cast(copied_transaction_h,rhs)) begin
            `uvm_fatal("ALU INPUT TRANSACTION", "Tried to copy wrong type.")
        end
        alu_input = copied_transaction_h.alu_input;
    endfunction : do_copy

    function random_alu_input_transaction clone_me();
        random_alu_input_transaction clone;
        uvm_object tmp;
        tmp = this.clone();
        $cast(clone, tmp);
        return clone;
    endfunction : clone_me

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        random_alu_input_transaction compared_transaction_h;
        if (rhs == null) begin
            `uvm_fatal("ALU INPUT TRANSACTION", "Tried to do comparison to a null pointer");
        end
        if (!$cast(compared_transaction_h,rhs)) begin
            return 0;
        end
        return super.do_compare(rhs, comparer) && (compared_transaction_h.alu_input == alu_input);
    endfunction : do_compare

    function string convert2string();
        return $sformatf(
            "A=%08h, B=%08h, rem_A=%0d, rem_B=%0d, op=%03b, invalid_crc=%b, crc=%04b, act=%b",
            alu_input.A, alu_input.B, alu_input.removed_packets_from_A,
            alu_input.removed_packets_from_B, alu_input.operation, alu_input.invalid_crc,
            alu_input.crc, alu_input.action);
    endfunction : convert2string

    function void post_randomize();
        alu_input.crc = generate_in_crc(alu_input);
    endfunction : post_randomize

    protected function in_crc_t generate_in_crc(alu_input_t alu_input);
        bit [31:0] X = alu_input.A;
        bit [31:0] Y = alu_input.B;
        bit [2:0] operation = alu_input.operation;
        bit [67:0] d = {X, Y, 1'b1, operation};
        static in_crc_t c = 0;
        in_crc_t crc = {
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
        if (alu_input.invalid_crc) begin
            in_crc_t invalid_crc;
            do begin
                invalid_crc = in_crc_t'($random);
            end while (invalid_crc === crc);
            return invalid_crc;
        end else begin
            return crc;
        end
    endfunction : generate_in_crc

    function new (string name = "");
        super.new(name);
    endfunction : new

endclass : random_alu_input_transaction
