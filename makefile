
comp:
	mkdir -p $(RTL_PATH)/work/niu
	$(RTL_PATH)/fexpand/fexpand -i $(RTL_PATH)/vc/niu_flist.f -o $(RTL_PATH)/work/niu/flielist.f
	cd $(RTL_PATH)/work; vcs -kdb -full64 -debug_access+all -sverilog -f $(RTL_PATH)/work/niu/flielist.f +lint=PCWM +lint=TFIPC-L +define+TOY_SIM

verdi:
	verdi -sv +define+TOY_SIM -f $(RTL_PATH)/work/niu/flielist.f