class alu_input_monitor extends uvm_component;

    `uvm_component_utils(alu_input_monitor)

    uvm_analysis_port#(alu_input_t) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        virtual alu_bfm bfm;
        if(!uvm_config_db#(virtual alu_bfm)::get(null, "*", "bfm", bfm)) begin
            $fatal(1, "Failed to get BFM");
        end
        bfm.alu_input_monitor_h = this;
        ap = new("ap", this);
    endfunction : build_phase

    function void write_to_monitor(alu_input_t alu_input);
        ap.write(alu_input);
    endfunction : write_to_monitor

endclass : alu_input_monitor
