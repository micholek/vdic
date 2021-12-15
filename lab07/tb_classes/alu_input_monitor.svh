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
        `uvm_info("ALU INPUT MONITOR", $sformatf(
                "\nA=%08h, B=%08h, rem_A=%0d, rem_B=%0d, op=%03b, invalid_crc=%b, crc=%04b, act=%b",
                alu_input.A, alu_input.B, alu_input.removed_packets_from_A,
                alu_input.removed_packets_from_B, alu_input.operation, alu_input.invalid_crc,
                alu_input.crc, alu_input.action), UVM_HIGH);
        random_alu_input.alu_input = alu_input;
        ap.write(random_alu_input);
    endfunction : write_to_monitor

endclass : alu_input_monitor
