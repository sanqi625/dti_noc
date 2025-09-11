
dti_pr:
	mkdir -p $(RTL_PATH)/work/dti_pr
	cd $(RTL_PATH)/work/dti_pr ;vcs -kdb -full64 -debug_access+all -sverilog -f $(RTL_PATH)/vc/dti_pr_flist.f +lint=PCWM +lint=TFIPC-L +define+TOY_SIM

isys:
	mkdir -p $(RTL_PATH)/work/sys
	cd $(RTL_PATH)/work/sys ;vcs -kdb -full64 -debug_access+all -sverilog -f $(RTL_PATH)/vc/dti_pr_iniu_sys_side_flist.f +lint=PCWM +lint=TFIPC-L +define+TOY_SIM

itop:
	mkdir -p $(RTL_PATH)/work/top
	cd $(RTL_PATH)/work/top ;vcs -kdb -full64 -debug_access+all -sverilog -f $(RTL_PATH)/vc/dti_pr_iniu_top_side_flist.f +lint=PCWM +lint=TFIPC-L +define+TOY_SIM

tsys:
	mkdir -p $(RTL_PATH)/work/sys
	cd $(RTL_PATH)/work/sys ;vcs -kdb -full64 -debug_access+all -sverilog -f $(RTL_PATH)/vc/dti_tniu_sys_side_flist.f +lint=PCWM +lint=TFIPC-L +define+TOY_SIM

ttop:
	mkdir -p $(RTL_PATH)/work/top
	cd $(RTL_PATH)/work/top ;vcs -kdb -full64 -debug_access+all -sverilog -f $(RTL_PATH)/vc/dti_tniu_top_side_flist.f +lint=PCWM +lint=TFIPC-L +define+TOY_SIM

verdi:
	verdi -sv +define+TOY_SIM -f $(RTL_PATH)/vc/dti_pr_flist.f 