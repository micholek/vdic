-F dut.f
alu_pkg.sv
alu_bfm.sv
-incdir ./tb_classes
top.sv

-uvm
-uvmhome /cad/XCELIUM1909/tools/methodology/UVM/CDNS-1.2/sv
+UVM_NO_RELNOTES
+UVM_VERBOSITY=MEDIUM
-linedebug
-fsmdebug
-uvmlinedebug
