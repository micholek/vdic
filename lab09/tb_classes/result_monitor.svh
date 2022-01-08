class result_monitor extends uvm_component;

    `uvm_component_utils(result_monitor)

    local virtual alu_bfm bfm;

    uvm_analysis_port#(result_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void write_to_monitor(alu_output_t alu_output);
        result_transaction result_t = new("result_t");
        result_t.alu_output = alu_output;
        ap.write(result_t);
    endfunction : write_to_monitor

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual alu_bfm)::get(null, "*", "bfm", bfm)) begin
            `uvm_fatal("RESULT MONITOR", "Failed to get BFM")
        end
        ap = new("ap", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        bfm.result_monitor_h = this;
    endfunction : connect_phase

endclass : result_monitor
