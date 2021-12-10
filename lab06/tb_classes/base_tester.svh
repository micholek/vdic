virtual class base_tester extends uvm_component;

    uvm_put_port#(alu_input_t) alu_input_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    pure virtual protected function action_t generate_action();

    pure virtual protected function bit [2:0] generate_operation();

    pure virtual protected function bit [31:0] generate_operand();

    pure virtual protected function bit [2:0] generate_removed_packets_number();

    pure virtual protected function bit generate_should_randomize_crc();

    pure virtual protected function in_crc_t generate_in_crc(bit [31:0] X, bit [31:0] Y,
        bit [2:0] operation, bit invalid_crc);

    function void build_phase(uvm_phase phase);
        alu_input_port = new("alu_input_port", this);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        alu_input_t alu_input;

        phase.raise_objection(this);

        alu_input.action = RESET_ACTION;
        alu_input_port.put(alu_input);

        repeat(1000) begin
            alu_input.action = generate_action();
            alu_input.A = generate_operand();
            alu_input.B = generate_operand();
            alu_input.removed_packets_from_A = generate_removed_packets_number();
            alu_input.removed_packets_from_B = generate_removed_packets_number();
            alu_input.operation = generate_operation();
            alu_input.should_randomize_crc = generate_should_randomize_crc();
            alu_input.crc = generate_in_crc(alu_input.A, alu_input.B, alu_input.operation,
                alu_input.should_randomize_crc);
            alu_input_port.put(alu_input);
        end

        #1000;

        phase.drop_objection(this);
    endtask : run_phase

endclass : base_tester
