class alu_agent extends uvm_agent;

    `uvm_component_utils(alu_agent)

    alu_agent_config alu_agent_config_h;

    tester tester_h;
    driver driver_h;
    scoreboard scoreboard_h;
    coverage coverage_h;
    alu_input_monitor alu_input_monitor_h;
    result_monitor result_monitor_h;

    uvm_tlm_fifo#(random_alu_input_transaction) alu_input_f;
    uvm_analysis_port#(random_alu_input_transaction) cmd_mon_ap;
    uvm_analysis_port#(result_transaction) result_ap;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(alu_agent_config)::get(this, "", "config", alu_agent_config_h))
            `uvm_fatal("AGENT", "Failed to get config object");

        if (alu_agent_config_h.get_is_active() == UVM_ACTIVE) begin : make_stimulus
            alu_input_f = new("alu_input_f", this);
            tester_h = tester::type_id::create("tester_h", this);
            driver_h = driver::type_id::create("driver_h", this);
        end

        alu_input_monitor_h = alu_input_monitor::type_id::create("alu_input_monitor_h", this);
        result_monitor_h = result_monitor::type_id::create("result_monitor_h", this);

        coverage_h = coverage::type_id::create("coverage_h", this);
        scoreboard_h = scoreboard::type_id::create("scoreboard_h", this);

        cmd_mon_ap = new("cmd_mon_ap", this);
        result_ap = new("result_ap", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        if (alu_agent_config_h.get_is_active() == UVM_ACTIVE) begin : make_stimulus
            driver_h.alu_input_port.connect(alu_input_f.get_export);
            tester_h.alu_input_port.connect(alu_input_f.put_export);
        end

        alu_input_monitor_h.ap.connect(cmd_mon_ap);
        result_monitor_h.ap.connect(result_ap);

        alu_input_monitor_h.ap.connect(scoreboard_h.alu_input_f.analysis_export);
        alu_input_monitor_h.ap.connect(coverage_h.analysis_export);
        result_monitor_h.ap.connect(scoreboard_h.analysis_export);
    endfunction : connect_phase

endclass : alu_agent
