class min_max_test extends alu_base_test;

    `uvm_component_utils(min_max_test)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new

    task run_phase(uvm_phase phase);
        min_max_sequence min_max = new("min_max");
        phase.raise_objection(this);
        min_max.start(sequencer_h);
        phase.drop_objection(this);
    endtask : run_phase

endclass : min_max_test
