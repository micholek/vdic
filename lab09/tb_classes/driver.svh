class driver extends uvm_component;

    `uvm_component_utils(driver)

    virtual alu_bfm bfm;
    uvm_get_port#(random_alu_input_transaction) alu_input_port;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual alu_bfm)::get(null, "*", "bfm", bfm)) begin
            `uvm_fatal("DRIVER", "Failed to get BFM")
        end
        alu_input_port = new("alu_input_port", this);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        random_alu_input_transaction alu_input;
        forever begin
            alu_input_port.get(alu_input);
            bfm.send_input(alu_input.alu_input);
        end
    endtask : run_phase

endclass : driver
