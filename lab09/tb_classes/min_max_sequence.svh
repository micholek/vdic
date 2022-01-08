class min_max_sequence extends uvm_sequence#(sequence_item);

    `uvm_object_utils(min_max_sequence)

    function new(string name = "min_max_sequence");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info("SEQ_MIN_MAX", "", UVM_MEDIUM)

        `uvm_do_with(req, {alu_input.action == RESET_ACTION;})
        repeat (1000) begin : random_loop
            `uvm_do_with(
                req,
                {
                    alu_input.A dist { 0 := 1, 32'hffffffff := 1 };
                    alu_input.B dist { 0 := 1, 32'hffffffff := 1 };
                }
            );
        end
    endtask : body

endclass : min_max_sequence
