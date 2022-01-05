class tester extends uvm_component;
    `uvm_component_utils(tester)

    uvm_put_port#(random_alu_input_transaction) alu_input_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        alu_input_port = new("alu_input_port", this);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        random_alu_input_transaction random_alu_input;

        phase.raise_objection(this);

        random_alu_input = new("random_alu_input");
        random_alu_input.alu_input.action = RESET_ACTION;
        alu_input_port.put(random_alu_input);

        random_alu_input = random_alu_input_transaction::type_id::create("random_alu_input");

        repeat (1000) begin
            assert(random_alu_input.randomize());
            alu_input_port.put(random_alu_input);
        end

        #500;
        phase.drop_objection(this);
    endtask : run_phase

endclass : tester
