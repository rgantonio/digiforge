# ==== CONFIGURABLE VARIABLES ====
VERILATOR       := verilator

TEST_MODULE     := tb_counter

INCLUDE_DIRS    := +incdir+tb/tasks

FLIST_DIRS		:= flists
FILELIST        := $(TEST_MODULE).flist
FILE_PATH 		:= $(FLIST_DIRS)/$(FILELIST)

VLT_FLAGS       := -O0
VLT_FLAGS       += --trace
VLT_FLAGS	    += --trace-structs

VLT_WAIVE 		:= -Wno-CASEINCOMPLETE
VLT_WAIVE 		+= -Wno-WIDTHTRUNC
VLT_WAIVE 		+= -Wno-WIDTHEXPAND

BIN_DIR			:= bin
OBJ_DIR         := obj_dir

# Derived from $(FILE_PATH)
SRCS := $(shell cat $(FILE_PATH))

# ==== BUILD TARGET ====
all: $(BIN_DIR)/$(TEST_MODULE)

$(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/$(TEST_MODULE): $(BIN_DIR) $(FILE_PATH)
	$(VERILATOR) --sv $(SRCS) $(INCLUDE_DIRS) $(VLT_WAIVE) $(VLT_FLAGS) --binary -o $(TEST_MODULE)
	cp $(OBJ_DIR)/$(TEST_MODULE) $(BIN_DIR)/.
	rm -rf $(OBJ_DIR)


questasim.do: $(FILE_PATH)
	@echo 'Generating $@'
	@echo vlib work > $@
	@echo vlog -sv -f $(FILE_PATH) $(INCLUDE_DIRS) >> $@
	@echo vsim -voptargs=\"+acc\" work.$(TEST_MODULE) >> $@
	@echo add wave -r \/\* >> $@
	@echo run -all >> $@

questasim-run: questasim.do
	@echo 'Running Questasim simulatio w/ Command Line Interface'
	vsim -c -do questasim.do

questasim-run-gui: questasim.do
	@echo 'Running Questasim simulation w/ GUI'
	vsim -gui -do questasim.do

# ==== CLEAN ====
clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR) *.vcd transcript *.do work *.wlf

.PHONY: all clean questasim.do
