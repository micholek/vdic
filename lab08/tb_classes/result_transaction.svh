class result_transaction extends uvm_transaction;

    alu_output_t alu_output;

    function new(string name = "");
        super.new(name);
    endfunction : new

    function void do_copy(uvm_object rhs);
        result_transaction copied_transaction_h;
        assert(rhs != null) else
            `uvm_fatal("RESULT TRANSACTION", "Tried to copy null transaction");
        super.do_copy(rhs);
        assert($cast(copied_transaction_h,rhs)) else
            `uvm_fatal("RESULT TRANSACTION", "Failed cast in do_copy");
        alu_output = copied_transaction_h.alu_output;
    endfunction : do_copy

    function string convert2string();
        return $sformatf("C=%08h, f=%04b, err_f=%03b, crc=%03b, par=%b", alu_output.C,
            alu_output.flags, alu_output.error_flags, alu_output.crc, alu_output.parity);
    endfunction : convert2string

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        result_transaction compared_transaction_h;
        assert(rhs != null) else begin
            `uvm_fatal("RESULT TRANSACTION", "Tried to compare null transaction");
        end
        if (!$cast(compared_transaction_h, rhs)) begin
            return 0;
        end
        return super.do_compare(rhs, comparer) && (compared_transaction_h.alu_output == alu_output);
    endfunction : do_compare

endclass : result_transaction
