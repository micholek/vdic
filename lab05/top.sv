module top;

    import alu_pkg::*;

    alu_bfm    bfm();

    testbench testbench_h;

    mtm_Alu alu(
        .clk(bfm.clk),
        .rst_n(bfm.rst_n),
        .sin(bfm.sin),
        .sout(bfm.sout)
    );

    initial begin
        testbench_h = new(bfm);
        testbench_h.execute();
    end

    final begin : finish_of_the_test
        testbench_h.print_result();
    end

endmodule : top
