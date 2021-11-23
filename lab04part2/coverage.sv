module coverage(alu_bfm bfm);
    import alu_pkg::*;

    bit [31:0] A;
    bit [31:0] B;
    bit [2:0] operation;
    bit [2:0] removed_packets_from_A;
    bit [2:0] removed_packets_from_B;
    action_t action;
    bit should_randomize_crc;

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

        cp_should_randomize_crc : coverpoint should_randomize_crc {
            bins C3_random_crc[] = {0, 1};
        }
    endgroup : error_cov

    operation_cov operation_c;
    data_cov data_c;
    error_cov error_c;

    initial begin
        operation_c = new();
        data_c = new();
        error_c = new();
        forever begin
            @(posedge bfm.clk);
            if (bfm.tb_state === SCORE_AND_COV_STATE || !bfm.rst_n) begin
                A = bfm.A;
                B = bfm.B;
                operation = bfm.operation;
                removed_packets_from_A = bfm.removed_packets_from_A;
                removed_packets_from_B = bfm.removed_packets_from_B;
                action = bfm.action;
                should_randomize_crc = bfm.should_randomize_crc;
                operation_c.sample();
                data_c.sample();
                error_c.sample();
            end
        end
    end


endmodule : coverage
