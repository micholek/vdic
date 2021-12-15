class tester extends uvm_component;
    `uvm_component_utils(tester)

    uvm_put_port#(random_alu_input_transaction) alu_input_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        alu_input_port = new("command_port", this);
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
            random_alu_input.alu_input.crc = generate_in_crc(random_alu_input.alu_input);
            alu_input_port.put(random_alu_input);
        end

        #500;
        phase.drop_objection(this);
    endtask : run_phase

    protected function in_crc_t generate_in_crc(alu_input_t alu_input);
        bit [31:0] X = alu_input.A;
        bit [31:0] Y = alu_input.B;
        bit [2:0] operation = alu_input.operation;
        bit [67:0] d = {X, Y, 1'b1, operation};
        static in_crc_t c = 0;
        automatic in_crc_t crc = {
            d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^
            d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^
            d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^
            d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3],
            d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^
            d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^
            d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^
            d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3],
            d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^
            d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^
            d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^
            d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3],
            d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^
            d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^
            d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^
            d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2]
        };
        if (alu_input.invalid_crc) begin
            in_crc_t invalid_crc2;
            do begin
                invalid_crc2 = in_crc_t'($random);
            end while (invalid_crc2 === crc);
            return invalid_crc2;
        end else begin
            return crc;
        end
    endfunction : generate_in_crc

endclass : tester
