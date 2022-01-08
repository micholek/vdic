class random_sequence extends uvm_sequence#(sequence_item);

    `uvm_object_utils(random_sequence)

    function new(string name = "random_sequence");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info("SEQ_RANDOM", "", UVM_MEDIUM)

        `uvm_create(req)
        `uvm_do_with(req, {alu_input.action == RESET_ACTION;})
        repeat (1000) begin : random_loop
            `uvm_rand_send(req);
        end
    endtask : body

endclass : random_sequence
