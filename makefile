RTL_COMPILE_OUTPUT 	= $(CURRENT_PATH)/work/rtl_compile

TIMESTAMP			= $(shell date +%Y%m%d_%H%M_%S)
GIT_REVISION 		= $(shell git show -s --pretty=format:%h)
.PHONY: compile lint

compile:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -kdb -full64 -debug_access+all -sverilog -f $(SIM_FILELIST) +lint=PCWM +lint=TFIPC-L +define+TOY_SIM

lint:
	fde -file $(CURRENT_PATH)/qc/lint.tcl -flow lint

isa:
	cd ./rv_isa_test/build ;ctest -j64

intr:
	${RTL_COMPILE_OUTPUT}/simv +HEX=/home/zick/prj/dev-ooo-new/benchmark_output/interrupt.itcm.hex +DATA_HEX=/home/zick/prj/dev-ooo-new/benchmark_output/interrupt.dtcm.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log +REG_TRACE=reg_trace.log

dhry:
	${RTL_COMPILE_OUTPUT}/simv +fsdb+region +HEX=$(CURRENT_PATH)/rv_isa_test/dhry/dhrystone_itcm.hex +DATA_HEX=$(CURRENT_PATH)/rv_isa_test/dhry/dhrystone_dtcm.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log +REG_TRACE=reg_trace.log +FETCH=fetch.log | tee benchmark_output/dhry/$(TIMESTAMP)_$(GIT_REVISION).log

dhry_test:
	${RTL_COMPILE_OUTPUT}/simv +HEX=$(CURRENT_PATH)/rv_isa_test/dhry/dhrystone_itcm1000.hex +DATA_HEX=$(CURRENT_PATH)/rv_isa_test/dhry/dhrystone_dtcm1000.hex +TIMEOUT=2000000 | tee benchmark_output/dhry/$(TIMESTAMP)_$(GIT_REVISION).log

lsu_check:
	${RTL_COMPILE_OUTPUT}/simv +HEX=$(CURRENT_PATH)/lsu_test.itcm.hex +DATA_HEX=$(CURRENT_PATH)/lsu_test.dtcm.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log +REG_TRACE=reg_trace.log +FETCH=fetch.log

single_isa:
	${RTL_COMPILE_OUTPUT}/simv +HEX=$(CURRENT_PATH)/rv_isa_test/isa/rv32uf-p-fadd_itcm.hex +DATA_HEX=$(CURRENT_PATH)/rv_isa_test/isa/rv32uf-p-fadd_data.hex +TIMEOUT=200000 +WAVE +PC=pc_trace.log +REG_TRACE=reg_trace.log +FETCH=fetch.log

cm:
	${RTL_COMPILE_OUTPUT}/simv +HEX=$(CURRENT_PATH)/rv_isa_test/cm/coremark_itcm.hex +DATA_HEX=$(CURRENT_PATH)/rv_isa_test/cm/coremark_dtcm.hex  +TIMEOUT=0 +WAVE +PC=pc_trace.log +REG_TRACE=reg_trace.log | tee benchmark_output/cm/$(TIMESTAMP)_$(GIT_REVISION).log 
cm_test:
	${RTL_COMPILE_OUTPUT}/simv +HEX=/data/usr/huangt/hello_world_ht/toy_bm/coremark_itcm.hex +DATA_HEX=/data/usr/huangt/hello_world_ht/toy_bm/coremark_dtcm.hex  +TIMEOUT=0 +PC=pc_trace.log | tee benchmark_output/cm/$(TIMESTAMP)_$(GIT_REVISION).log 
cm_backup:
	${RTL_COMPILE_OUTPUT}/simv  +HEX=$(CURRENT_PATH)/rv_isa_test/dhry/coremark_itcm_1000.hex +DATA_HEX=$(CURRENT_PATH)/rv_isa_test/dhry/coremark_dtcm_1000.hex  +TIMEOUT=0 | tee benchmark_output/cm/$(TIMESTAMP)_$(GIT_REVISION).log

verdi:
	verdi -sv +define+TOY_SIM -f $(SIM_FILELIST) -ssf wave.fsdb