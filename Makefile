SIM ?= icarus
TOPLEVEL_LANG = verilog

VERILOG_SOURCES = \
	$(PWD)/src/pkg.sv \
	$(PWD)/src/sort8.sv \
	$(PWD)/src/Regset.sv \
	$(PWD)/src/write_ctrl.sv \
	$(PWD)/src/merge_ctrl.sv \
	$(PWD)/src/CompTree.sv \
	$(PWD)/src/Top4.sv

COMPILE_ARGS += -g2012

COCOTB_TOPLEVEL = Top4
COCOTB_TEST_MODULES = tb.cocotb.test_top4_txn

include $(shell cocotb-config --makefiles)/Makefile.sim
