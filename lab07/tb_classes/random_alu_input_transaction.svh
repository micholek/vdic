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

    function new (string name = "");
        super.new(name);
    endfunction : new

endclass : random_alu_input_transaction
