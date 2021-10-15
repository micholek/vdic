module alu_tb;

	typedef enum bit [2:0] {
		AND_OPERATION = 3'b000,
		OR_OPERATION = 3'b001,
		ADD_OPERATION = 3'b100,
		SUB_OPERATION = 3'b101
	} operation_t;

	typedef bit [3:0] crc_t;

	typedef bit [10:0] packet_t;

	bit clk;
	bit rst_n;
	bit sin;
	wire sout;

	int A;
	int B;
	operation_t operation;
	crc_t crc;
	bit [98:0] in_packet;
	bit [6:0] in_bit_count;

	mtm_Alu DUT(
		.clk,
		.rst_n,
		.sin,
		.sout
	);

	initial begin : clk_gen
		clk = 0;
		forever begin : clk_frv
			#10 clk = ~clk;
		end
	end

	initial begin : tester
		reset_alu();

		A = 10;
		B = 20;
		operation = ADD_OPERATION;
		crc = 4'b0101; // pre-calculated for now

		in_packet = create_packet(B, A, operation, crc);
		repeat (98) begin : tester_send_packet
			@(negedge clk);
			sin = in_packet[98 - in_bit_count];
			in_bit_count++;
		end

		#2000 $finish;
	end

	task reset_alu();
		sin = 1'b1;
		in_bit_count = 0;
		rst_n = 1'b0;
		@(negedge clk);
		rst_n = 1'b1;
	endtask : reset_alu

	function packet_t create_data_packet(byte payload);
		return {2'b00, payload, 1'b1};
	endfunction : create_data_packet

	function packet_t create_cmd_packet(byte payload);
		return {2'b01, payload, 1'b1};
	endfunction : create_cmd_packet

	function bit [98:0] create_packet(int X, int Y, operation_t operation, crc_t crc);
		return {
			create_data_packet(X[31:24]),
			create_data_packet(X[23:16]),
			create_data_packet(X[15:8]),
			create_data_packet(X[7:0]),
			create_data_packet(Y[31:24]),
			create_data_packet(Y[23:16]),
			create_data_packet(Y[15:8]),
			create_data_packet(Y[7:0]),
			create_cmd_packet({1'b0, operation, crc})
		};
	endfunction : create_packet
endmodule : alu_tb
