# ==== CONFIGURABLE VARIABLES ====
VERILATOR       := verilator

TEST_MODULE     := tb_counter

INCLUDE_DIRS    := +incdir+sv/tb/tasks
INCLUDE_DIRS    += +incdir+sv/hlib

FLIST_DIRS		:= flists
FILELIST        := $(TEST_MODULE).flist
FILE_PATH 		:= $(FLIST_DIRS)/$(FILELIST)

VLT_FLAGS       := -O0
VLT_FLAGS       += --trace
VLT_FLAGS	    += --trace-structs

VLT_WAIVE 		:= -Wno-CASEINCOMPLETE
VLT_WAIVE 		+= -Wno-WIDTHTRUNC
VLT_WAIVE 		+= -Wno-WIDTHEXPAND
VLT_WAIVE 		+= -Wno-UNOPTFLAT

BIN_DIR			:= bin
OBJ_DIR         := obj_dir

# Derived from $(FILE_PATH)
SRCS := $(shell cat $(FILE_PATH))

# ==== Verilator ====
veri-build: $(BIN_DIR)/$(TEST_MODULE)

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/$(TEST_MODULE): $(BIN_DIR) $(FILE_PATH)
	$(VERILATOR) --sv $(SRCS) $(INCLUDE_DIRS) $(VLT_WAIVE) $(VLT_FLAGS) --binary -o $(TEST_MODULE)
	cp $(OBJ_DIR)/$(TEST_MODULE) $(BIN_DIR)/.
	rm -rf $(OBJ_DIR)

veri-run: veri-build
	@echo 'Running Verilator simulation'
	$(BIN_DIR)/$(TEST_MODULE)

# ==== QuestaSim ====
questasim.do: $(FILE_PATH)
	@echo 'Generating $@'
	@echo vlib work > $@
	@echo vlog -sv -f $(FILE_PATH) $(INCLUDE_DIRS) >> $@
	@echo vsim -voptargs=\"+acc\" work.$(TEST_MODULE) >> $@
	@echo add wave -r \/\* >> $@
	@echo run -all >> $@

questa-run: questasim.do
	@echo 'Running Questasim simulation w/ Command Line Interface'
	vsim -c -do questasim.do

questa-run-gui: questasim.do
	@echo 'Running Questasim simulation w/ GUI'
	vsim -gui -do questasim.do

# ==== CLEAN ====
clean-all: clean-veri clean-questa

clean-veri:
	rm -rf $(OBJ_DIR) $(BIN_DIR) *.vcd

clean-questa:
	rm -rf work transcript *.do *.wlf *.vcd

clean-chisel:
	rm -rf chisel/generated chisel/target chisel/test_run_dir

.PHONY: veri-build veri-run clean-all questasim.do questa-run questa-run-gui clean-veri clean-questa clean-chisel
