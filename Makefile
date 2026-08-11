SIM ?= icarus
TOPLEVEL_LANG = verilog

VERILOG_SOURCES = \
	$(PWD)/pkg.sv \
	$(PWD)/sort8.sv \
	$(PWD)/Regset.sv \
	$(PWD)/write_ctrl.sv \
	$(PWD)/merge_ctrl.sv \
	$(PWD)/CompTree.sv \
	$(PWD)/Top4.sv

COMPILE_ARGS += -g2012

COCOTB_TOPLEVEL = Top4
COCOTB_TEST_MODULES = test_top4_txn

include $(shell cocotb-config --makefiles)/Makefile.sim
