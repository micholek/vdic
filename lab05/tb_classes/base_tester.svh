virtual class base_tester extends uvm_component;

    `uvm_component_utils(base_tester)

    virtual alu_bfm bfm;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual alu_bfm)::get(null, "*","bfm", bfm))
            $fatal(1, "Failed to get BFM");
    endfunction : build_phase

    pure virtual protected function action_t generate_action();

    pure virtual protected function bit [2:0] generate_operation();

    pure virtual protected function bit [31:0] generate_operand(bit [2:0] removed_packets);

    pure virtual protected function bit [2:0] generate_removed_packets_number();

    pure virtual protected function in_packets_t create_in_packets(bit [31:0] X, bit [31:0] Y,
        bit [2:0] operation, bit [2:0] removed_packets_from_X, bit [2:0] removed_packets_from_Y);

    task run_phase(uvm_phase phase);
        in_packets_t in_packets;

        phase.raise_objection(this);

        bfm.reset_alu();

        repeat(1000) begin
            wait(bfm.tb_state === TEST_STATE);
            bfm.action = generate_action();
            if (bfm.action === RESET_ACTION) begin
                bfm.reset_alu();
                continue;
            end

            bfm.removed_packets_from_A = generate_removed_packets_number();
            bfm.removed_packets_from_B = generate_removed_packets_number();
            bfm.A = generate_operand(bfm.removed_packets_from_A);
            bfm.B = generate_operand(bfm.removed_packets_from_B);
            bfm.operation = generate_operation();
            in_packets = create_in_packets(bfm.A, bfm.B, bfm.operation, bfm.removed_packets_from_A,
                bfm.removed_packets_from_B);
            bfm.send_packets(in_packets);
            bfm.tb_state = SCORE_AND_COV_STATE;
        end

        phase.drop_objection(this);
    endtask : run_phase

endclass : base_tester
