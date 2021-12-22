class min_max_alu_input_transaction extends random_alu_input_transaction;

    `uvm_object_utils(min_max_alu_input_transaction)

    constraint min_max_only {
        alu_input.A dist { 0 := 1, 32'hffffffff := 1 };
        alu_input.B dist { 0 := 1, 32'hffffffff := 1 };
    }

    function new(string name="");
        super.new(name);
    endfunction : new

endclass : min_max_alu_input_transaction
