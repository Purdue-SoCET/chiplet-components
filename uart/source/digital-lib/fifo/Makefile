TOP = tb_uvm_fifo.sv
TB = uvm_tb/
RTL = src/socetlib_fifo.sv

build:
	vlog +incdir+src+uvm_tb+uvm_tb/clk_agent \
	+acc \
	+cover \
	-L $$QUESTA_HOME/uvm-1.2 $(FIFO) uvm_tb/$(TOP) \
	-logfile tb_compile.log \
	-printinfilenames=file_search.log

run:
	vsim -c tb_uvm_fifo -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="base_int_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "coverage save -onexit coverage.ucdb" -do "run -all" &

run-period_10ns_test:
	vsim -c tb_uvm_fifo -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="period_10ns_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "do wave.do" -do "run -all" &

run-period_20ns_test:
	vsim -c tb_uvm_fifo -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="period_20ns_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "do wave.do" -do "run -all" &

run-read_write_test:
	vsim -c tb_uvm_fifo -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="read_write_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "do wave.do" -do "run -all" &

run-clear_test:
	vsim -c tb_uvm_fifo -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="clear_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "do wave.do" -do "run -all" &

run-nrst_test:
	vsim -c tb_uvm_fifo -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="nrst_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "do wave.do" -do "run -all" &

run-full_random_test:
	vsim -c tb_uvm_fifo -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="full_random_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "coverage save -onexit coverage.ucdb" -do "run -all" &

run_gui:
	vsim -i tb_uvm_fifo -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME="base_int_test" \
	+UVM_VERBOSITY=UVM_LOW \
	-do "do wave.do" -do "run -all" &

view_cov:
	vsim -viewcov coverage.ucdb

clean:
	rm -rf work
	rm -rf mitll90_Dec2019_all
	rm -rf covhtmlreport
	rm *.log
	rm transcript
	rm *.ucdb
	rm *.wlf
	rm *.vstf

.phony: build, run, run_gui, clean
