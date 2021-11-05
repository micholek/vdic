interface alu_bfm;
    import alu_pkg::*;

    bit clk;
    bit rst_n;
    bit sin;
    wire sout;

    bit [31:0] A;
    bit [31:0] B;
    bit [2:0] operation;
    bit [2:0] removed_packets_from_A;
    bit [2:0] removed_packets_from_B;
    action_t action;
    bit should_randomize_crc;
    tb_state_t tb_state;

    string test_result = "PASSED";

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

    task send_packets(in_packets_t packets);
        foreach (packets[i,j]) begin : tester_send_packet
            @(negedge bfm.clk);
            bfm.sin = packets[i][j];
        end
    endtask : send_packets

    task receive_error_packet(output packet_t packet);
        foreach (packet[i]) begin
            @(negedge bfm.clk);
            packet[i] = bfm.sout;
        end
    endtask : receive_error_packet

    task receive_success_packets(output out_packets_t packets);
        foreach (packets[i,j]) begin
            @(negedge bfm.clk);
            packets[i][j] = bfm.sout;
        end
    endtask : receive_success_packets

endinterface : alu_bfm