# test/Makefile
TOP_MODULE       ?= tt_um_jakedrew_qei
TB_TOP           ?= tt_um_jakedrew_qei_tb

SRC_DIR          ?= ../src
BUILD            ?= build

# verilog sources
PROJECT_SOURCES  ?= $(SRC_DIR)/qei.v
TB_SOURCES       ?= $(TB_TOP).v

# gate-level support (set GATES=yes and ensure PDK_ROOT & gate_level_netlist.v exist)
ifeq ($(GATES),yes)
  IVERILOG_DEFS  += -DGL_TEST -DFUNCTIONAL -DUSE_POWER_PINS -DSIM -DUNIT_DELAY=\#1
  GL_SOURCES     += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
  GL_SOURCES     += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
  GL_SOURCES     += $(PWD)/gate_level_netlist.v
  SIM_SOURCES     = $(GL_SOURCES) $(TB_SOURCES)
else
  SIM_SOURCES     = $(PROJECT_SOURCES) $(TB_SOURCES)
endif

.PHONY: test lint clean waves

test: $(BUILD)/sim.vvp
	@set -e; \
	vvp $(BUILD)/sim.vvp; rc=$$?; \
	if [ -f $(BUILD)/wave.vcd ]; then cp -f $(BUILD)/wave.vcd tb.vcd; fi; \
	if [ $$rc -eq 0 ]; then \
	  echo '<testsuite tests="1" failures="0"><testcase classname="$(TOP_MODULE)" name="rtl"/></testsuite>' > results.xml; \
	else \
	  echo '<testsuite tests="1" failures="1"><testcase classname="$(TOP_MODULE)" name="rtl"><failure message="simulation failed"/></testcase></testsuite>' > results.xml; \
	fi; \
	exit $$rc



$(BUILD)/sim.vvp: $(SIM_SOURCES) | $(BUILD)
	iverilog -g2012 -o $(BUILD)/sim.vvp $(IVERILOG_DEFS) $(SIM_SOURCES)

$(BUILD):
	mkdir -p $(BUILD)

# lint the verilog / RTL (skipped when GATES=yes)
lint:
ifeq ($(GATES),yes)
	@echo "lint: skipped for gate-level"
else
	verilator --lint-only -Wall $(PROJECT_SOURCES)
endif

clean:
	rm -rf $(BUILD)
