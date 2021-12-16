class alu_input_monitor extends uvm_component;

    `uvm_component_utils(alu_input_monitor)

    uvm_analysis_port#(random_alu_input_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        virtual alu_bfm bfm;
        if(!uvm_config_db#(virtual alu_bfm)::get(null, "*", "bfm", bfm)) begin
            `uvm_fatal("ALU INPUT MONITOR", "Failed to get BFM")
        end
        bfm.alu_input_monitor_h = this;
        ap = new("ap", this);
    endfunction : build_phase

    function void write_to_monitor(alu_input_t alu_input);
        random_alu_input_transaction random_alu_input = new("random_alu_input");
        random_alu_input.alu_input = alu_input;
        `uvm_info("ALU INPUT MONITOR", random_alu_input.convert2string(), UVM_HIGH);
        ap.write(random_alu_input);
    endfunction : write_to_monitor

endclass : alu_input_monitor
