class alu_input_monitor extends uvm_component;

    `uvm_component_utils(alu_input_monitor)

    local virtual alu_bfm bfm;

    uvm_analysis_port#(sequence_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual alu_bfm)::get(null, "*", "bfm", bfm)) begin
            `uvm_fatal("ALU INPUT MONITOR", "Failed to get BFM")
        end
        ap = new("ap", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        bfm.alu_input_monitor_h = this;
    endfunction : connect_phase

    function void write_to_monitor(alu_input_t alu_input);
        sequence_item seq = new("seq");
        seq.alu_input = alu_input;
        `uvm_info("ALU INPUT MONITOR", seq.convert2string(), UVM_HIGH);
        ap.write(seq);
    endfunction : write_to_monitor

endclass : alu_input_monitor
