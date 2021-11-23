module top;
    alu_bfm    bfm();

    tester     tester_i(bfm);
    coverage   coverage_i(bfm);
    scoreboard scoreboard_i(bfm);

    mtm_Alu alu(
        .clk(bfm.clk),
        .rst_n(bfm.rst_n),
        .sin(bfm.sin),
        .sout(bfm.sout)
    );
endmodule : top
