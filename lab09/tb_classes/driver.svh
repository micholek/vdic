class driver extends uvm_driver#(sequence_item);

    `uvm_component_utils(driver)

    protected virtual alu_bfm bfm;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual alu_bfm)::get(null, "*", "bfm", bfm)) begin
            `uvm_fatal("DRIVER", "Failed to get BFM")
        end
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        sequence_item seq;
        void'(begin_tr(seq));
        forever begin : seq_loop
            seq_item_port.get_next_item(seq);
            bfm.send_input(seq.alu_input, seq.alu_output);
            seq_item_port.item_done();
        end : seq_loop
        end_tr(seq);
    endtask : run_phase

endclass : driver
