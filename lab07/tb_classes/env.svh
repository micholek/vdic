class env extends uvm_env;

    `uvm_component_utils(env)

    tester tester_h;
    coverage coverage_h;
    scoreboard scoreboard_h;
    driver driver_h;
    alu_input_monitor alu_input_monitor_h;
    result_monitor result_monitor_h;
    uvm_tlm_fifo#(random_alu_input_transaction) alu_input_f;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        alu_input_f = new("alu_input_f", this);
        tester_h = tester::type_id::create("tester_h", this);
        driver_h = driver::type_id::create("drive_h", this);
        coverage_h = coverage::type_id::create ("coverage_h", this);
        scoreboard_h = scoreboard::type_id::create("scoreboard_h", this);
        alu_input_monitor_h = alu_input_monitor::type_id::create("alu_input_monitor_h", this);
        result_monitor_h = result_monitor::type_id::create("result_monitor_h", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        driver_h.alu_input_port.connect(alu_input_f.get_export);
        tester_h.alu_input_port.connect(alu_input_f.put_export);
        alu_input_f.put_ap.connect(coverage_h.analysis_export);
        alu_input_monitor_h.ap.connect(scoreboard_h.alu_input_f.analysis_export);
        result_monitor_h.ap.connect(scoreboard_h.analysis_export);
    endfunction : connect_phase

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        $write("\033\[1;30m\033\[103m");
        $write("*** Created tester type: %s", tester_h.get_type_name());
        $write("\033\[0m\n");
    endfunction : end_of_elaboration_phase

endclass : env
