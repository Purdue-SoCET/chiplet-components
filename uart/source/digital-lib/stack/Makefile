TOP = tb_stack.sv
TB = /uvm_tb
#IF = /uvm_tb/stack_if.svh
SRC = /src/socetlib_stack.sv

build:
	vlog +incdir+src+tb \
	+acc \
	+cover \
	-L $$QUESTA_HOME/uvm-1.2  $(STACK) uvm_tb/$(TOP) \
	-logfile tb_compile.log \
	-printinfilenames=file_search.log

run:
	vsim -c tb_stack -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="stack_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "do wave.do" -do "run -all" &

run_gui:
	vsim -i tb_stack -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="stack_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "do wave.do" -do "run -all" &

clean:
	rm -rf work
	rm -rf mitll90_Dec2019_all
	rm -rf covhtmlreport
	rm *.log
	rm transcript
	rm *.wlf

.phony: build, run, run_gui, clean