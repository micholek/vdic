class testbench;

    virtual alu_bfm bfm;

    function new(virtual alu_bfm bfm);
        this.bfm = bfm;
    endfunction : new

    tester tester_h;
    coverage coverage_h;
    scoreboard scoreboard_h;

    task execute();
        tester_h = new(bfm);
        coverage_h = new(bfm);
        scoreboard_h = new(bfm);
        fork
            tester_h.execute();
            coverage_h.execute();
            scoreboard_h.execute();
        join_none
    endtask : execute

endclass : testbench
