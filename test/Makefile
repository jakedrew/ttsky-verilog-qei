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
	vvp $(BUILD)/sim.vvp

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
