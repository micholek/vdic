interface alu_bfm;
    import alu_pkg::*;

    bit clk;
    bit rst_n;
    bit sin;
    wire sout;

    alu_input_t alu_input;
    alu_output_t alu_output;
    tb_state_t tb_state = TEST_STATE;

    initial begin : clk_gen
        clk = 0;
        forever begin : clk_frv
            #10 clk = ~clk;
        end
    end

    task reset_alu();
        sin = 1'b1;
        rst_n = 1'b0;
        @(negedge clk);
        rst_n = 1'b1;
    endtask : reset_alu

    task send_input(alu_input_t alu_in);
        in_packets_t in_packets;
        alu_input = alu_in;
        if (alu_input.action == RESET_ACTION) begin
            reset_alu();
            return;
        end

        in_packets = create_in_packets();
        foreach (in_packets[i,j]) begin
            @(negedge clk);
            sin = in_packets[i][j];
        end

        @(negedge sout);
        if (alu_input.removed_packets_from_A || alu_input.removed_packets_from_B ||
                alu_input.invalid_crc || !(alu_input.operation inside {`ALL_OPERATIONS})) begin
            packet_t out_error_packet;
            receive_error_packet(out_error_packet);
            alu_output.error_flags = out_error_packet[7-:2*$bits(error_flags_t)];
            alu_output.parity = out_error_packet[1];
        end else begin
            out_packets_t out_success_packets;
            receive_success_packets(out_success_packets);
            alu_output.C = {out_success_packets[0][8-:8], out_success_packets[1][8-:8],
                out_success_packets[2][8-:8], out_success_packets[3][8-:8]};
            alu_output.flags = out_success_packets[4][7-:$bits(flags_t)];
            alu_output.crc = out_success_packets[4][3-:$bits(out_crc_t)];
        end

        tb_state = SCORE_AND_COV_STATE;
        @(negedge clk);
    endtask : send_input

    task receive_error_packet(output packet_t packet);
        foreach (packet[i]) begin
            @(negedge clk);
            packet[i] = sout;
        end
    endtask : receive_error_packet

    task receive_success_packets(output out_packets_t packets);
        foreach (packets[i,j]) begin
            @(negedge clk);
            packets[i][j] = sout;
        end
    endtask : receive_success_packets

    function in_packets_t create_in_packets();
        return {
            alu_input.removed_packets_from_A > 0 ? 11'b11111111111 : create_data_packet(alu_input.A[31:24]),
            alu_input.removed_packets_from_A > 1 ? 11'b11111111111 : create_data_packet(alu_input.A[23:16]),
            alu_input.removed_packets_from_A > 2 ? 11'b11111111111 : create_data_packet(alu_input.A[15:8]),
            alu_input.removed_packets_from_A > 3 ? 11'b11111111111 : create_data_packet(alu_input.A[7:0]),
            alu_input.removed_packets_from_B > 0 ? 11'b11111111111 : create_data_packet(alu_input.B[31:24]),
            alu_input.removed_packets_from_B > 1 ? 11'b11111111111 : create_data_packet(alu_input.B[23:16]),
            alu_input.removed_packets_from_B > 2 ? 11'b11111111111 : create_data_packet(alu_input.B[15:8]),
            alu_input.removed_packets_from_B > 3 ? 11'b11111111111 : create_data_packet(alu_input.B[7:0]),
            create_cmd_packet({1'b0, alu_input.operation, alu_input.crc})
        };
    endfunction : create_in_packets

    function packet_t create_cmd_packet(byte payload);
        return {2'b01, payload, 1'b1};
    endfunction : create_cmd_packet

    function packet_t create_data_packet(byte payload);
        return {2'b00, payload, 1'b1};
    endfunction : create_data_packet

    alu_input_monitor alu_input_monitor_h;

    initial begin : alu_input_monitor_thread__operation
        forever begin
            @(posedge clk);
            if (tb_state == SCORE_AND_COV_STATE) begin
                alu_input_monitor_h.write_to_monitor(alu_input);
            end
        end
    end : alu_input_monitor_thread__operation

    initial begin : alu_input_monitor_thread__reset
        forever begin
            @(negedge rst_n);
            if (alu_input_monitor_h != null)
                alu_input_monitor_h.write_to_monitor(alu_input);
        end
    end : alu_input_monitor_thread__reset

    result_monitor result_monitor_h;

    initial begin : result_monitor_thread
        forever begin
            @(posedge clk);
            if (tb_state == SCORE_AND_COV_STATE) begin
                result_monitor_h.write_to_monitor(alu_output);
                tb_state = TEST_STATE;
            end
        end
    end : result_monitor_thread

endinterface : alu_bfm