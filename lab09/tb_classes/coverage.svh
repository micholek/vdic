class coverage extends uvm_subscriber#(sequence_item);

    `uvm_component_utils(coverage)

    local bit [31:0] A;
    local bit [31:0] B;
    local bit [2:0] operation;
    local bit [2:0] removed_packets_from_A;
    local bit [2:0] removed_packets_from_B;
    local action_t action;
    local bit invalid_crc;

    covergroup operation_cov;
        option.name = "cg_operation_cov";

        cp_operation : coverpoint operation {
            bins A1_operations[] = {`ALL_OPERATIONS};
            bins A2_operation_after_operation[] = (`ALL_OPERATIONS => `ALL_OPERATIONS);
        }

        cp_action : coverpoint action {
            bins reset_after_operation = (OPERATION_ACTION => RESET_ACTION);
            bins operation_after_reset = (RESET_ACTION => OPERATION_ACTION);
        }

        cross_operation_action : cross cp_operation, cp_action {
            bins A3_reset_after_and = binsof(cp_operation.A1_operations) intersect {AND_OPERATION}
            && binsof(cp_action.reset_after_operation);
            bins A3_reset_after_or = binsof(cp_operation.A1_operations) intersect {OR_OPERATION}
            && binsof(cp_action.reset_after_operation);
            bins A3_reset_after_add = binsof(cp_operation.A1_operations) intersect {ADD_OPERATION}
            && binsof(cp_action.reset_after_operation);
            bins A3_reset_after_sub = binsof(cp_operation.A1_operations) intersect {SUB_OPERATION}
            && binsof(cp_action.reset_after_operation);
            bins A4_and_after_reset = binsof(cp_operation.A1_operations) intersect {AND_OPERATION}
            && binsof(cp_action.operation_after_reset);
            bins A4_or_after_reset = binsof(cp_operation.A1_operations) intersect {OR_OPERATION}
            && binsof(cp_action.operation_after_reset);
            bins A4_add_after_reset = binsof(cp_operation.A1_operations) intersect {ADD_OPERATION}
            && binsof(cp_action.operation_after_reset);
            bins A4_sub_after_reset = binsof(cp_operation.A1_operations) intersect {SUB_OPERATION}
            && binsof(cp_action.operation_after_reset);
            ignore_bins operation_transition = binsof(cp_operation.A2_operation_after_operation);
        }
    endgroup : operation_cov

    covergroup data_cov;
        option.name = "cg_data_cov";

        cp_operation : coverpoint operation {
            wildcard ignore_bins invalid_operations = {3'b?1?};
        }

        cp_A : coverpoint A {
            bins min = {'h00000000};
            bins others = {['h00000001 : 'hfffffffe]};
            bins max = {'hffffffff};
        }

        cp_B : coverpoint B {
            bins min = {'h00000000};
            bins others = {['h00000001 : 'hfffffffe]};
            bins max = {'hffffffff};
        }

        cross_operation_A_B : cross cp_operation, cp_A, cp_B {
            bins B1_and_min = binsof(cp_operation) intersect {AND_OPERATION} &&
            (binsof(cp_A.min) || binsof(cp_B.min));
            bins B1_or_min = binsof(cp_operation) intersect{OR_OPERATION} &&
            (binsof(cp_A.min) || binsof(cp_B.min));
            bins B1_add_min = binsof(cp_operation) intersect {ADD_OPERATION} &&
            (binsof(cp_A.min) || binsof(cp_B.min));
            bins B1_sub_min = binsof(cp_operation) intersect {SUB_OPERATION} &&
            (binsof(cp_A.min) || binsof(cp_B.min));

            bins B2_and_max = binsof(cp_operation) intersect {AND_OPERATION} &&
            (binsof(cp_A.max) || binsof(cp_B.max));
            bins B2_or_max = binsof(cp_operation) intersect {OR_OPERATION} &&
            (binsof(cp_A.max) || binsof(cp_B.max));
            bins B2_add_max = binsof(cp_operation) intersect {ADD_OPERATION} &&
            (binsof(cp_A.max) || binsof(cp_B.max));
            bins B2_sub_max = binsof(cp_operation) intersect {SUB_OPERATION} &&
            (binsof(cp_A.max) || binsof(cp_B.max));

            ignore_bins others = binsof(cp_A.others) && binsof(cp_B.others);
        }
    endgroup : data_cov

    covergroup error_cov;
        option.name = "cg_error_cov";

        cp_removed_packets_from_A : coverpoint removed_packets_from_A {
            bins C1_removed_packets[] = {[0 : 4]};
        }

        cp_removed_packets_from_B : coverpoint removed_packets_from_B {
            bins C1_removed_packets[] = {[0 : 4]};
        }

        cp_operation : coverpoint operation {
            wildcard ignore_bins C2_all_operations = {3'b?0?};
        }

        cp_invalid_crc : coverpoint invalid_crc {
            bins C3_invalid_crc[] = {0, 1};
        }
    endgroup : error_cov

    function new(string name, uvm_component parent);
        super.new(name, parent);
        operation_cov = new();
        data_cov = new();
        error_cov = new();
    endfunction : new

    function void write(sequence_item t);
        A = t.alu_input.A;
        B = t.alu_input.B;
        operation = t.alu_input.operation;
        removed_packets_from_A = t.alu_input.removed_packets_from_A;
        removed_packets_from_B = t.alu_input.removed_packets_from_B;
        action = t.alu_input.action;
        invalid_crc = t.alu_input.invalid_crc;
        operation_cov.sample();
        data_cov.sample();
        error_cov.sample();
    endfunction : write

endclass : coverage
