class min_max_tester extends random_tester;

    `uvm_component_utils (random_tester)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new


    protected function bit [31:0] generate_operand(bit [2:0] removed_packets);
        bit [31:0] operand;
        automatic bit randomize_res = std::randomize(operand) with {
            operand dist { 0 := 1, 32'hffffffff := 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $error("Generating random operand failed");
            bfm.test_result = "FAILED";
            $finish;
        end
        return operand;
    endfunction : generate_operand

endclass : min_max_tester
