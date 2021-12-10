class min_max_tester extends random_tester;

    `uvm_component_utils(min_max_tester)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    protected function bit [31:0] generate_operand();
        bit [31:0] operand;
        automatic bit randomize_res = std::randomize(operand) with {
            operand dist { 0 := 1, 32'hffffffff := 1 };
        };
        assert(randomize_res === 1'b1)
        else begin
            $fatal(1, "Generating random operand failed");
        end
        return operand;
    endfunction : generate_operand

endclass : min_max_tester
