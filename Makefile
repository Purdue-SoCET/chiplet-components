# created and developed by roboticowl4000
VERSION = 1.2.0
SHELL = /bin/bash

ORG = socet
PROJECT = chiplet

# DEBUG ENABLE
# only set this to 1 if build system debugging is needed, as a lot of information is stored by the build system
DEBUG = 0

# Colors
CLR_RST =    echo -ne "\033[0m";
CLR_BS_ERR = echo -ne "\033[0;31m";
CLR_BS_WRN = echo -ne "\033[0;34m";
CLR_SP_ERR = echo -ne "\033[0;33m";
CLR_SP_WRN = echo -ne "\033[0;35m";

help:
	@echo "----------------------------------------------------------------"
	@echo "Purdue SoCET Build System v$(VERSION)"
	@echo
	@echo "Administrative Targets:"
	@echo "  help           - shows this menu"
	@echo "  help_tb        - shows help for handling testbench data files"
	@echo "  buildsys_setup - sets up the build system"
	@echo "  clean          - removes netlists and build files"
	@echo "  veryclean      - removes all temp files"
	@echo "  test_colors    - displays color configuration"
	@echo
	@echo "FuseSoC Targets:"  
	@echo "  list_cores     - lists all available cores"
	@echo "  core_info_%    - displays info for the % core"
	@echo
	@echo "Simulation Targets:"
	@echo "  versim_%_src   - simulates the \"$(ORG):$(PROJECT):%\" design using"
	@echo "                   verilator"
	@echo "  qsim_%_src     - simulates the \"$(ORG):$(PROJECT):%\" design using"
	@echo "                   questasim"
	@echo "  qsim_%_syn     - simulates the synthesized \"$(ORG):$(PROJECT):%\""
	@echo "                   design using questasim"
	@echo "  qsimgui_%_src  - same as qsim_%_src, but uses the questasim gui"
	@echo "  qsimgui_%_syn  - same as qsim_%_syn, but uses the questasim gui"
	@echo
	@echo "Synthesis Targets:"
	@echo "  syn_%          - synthesizes the \"$(ORG):$(PROJECT):%\" design using"
	@echo "                   the tool specified in the SYN_TOOL variable"
	@echo
	@echo "Analysis Targets"
	@echo "  verlint_%      - lints the \"$(ORG):$(PROJECT):%\" design using"
	@echo "                   verilator"
	@echo "  schem_%        - creates a schematic of the \"$(ORG):$(PROJECT):%\""
	@echo "                   design using design vision"
	@echo
	@echo "Module Generation Targets"
	@echo "  module_%       - creates the % module testbench, source, and core"
	@echo "                   files, can specify the sub directory by adding"
	@echo "                   SUB_DIR=sub/directory/"
	@echo
	@echo "Required Software"
	@echo "  FuseSoC v2.3"
	@echo
	@echo "Compatible Software"
	@echo "  Synopsys Design Compiler Version K-2015.06-SP1"
	@echo "  QuestaSim vlog 10.7a Compiler 2018.03 Mar 26 2018"
	@echo "  Verilator 5.020 2024-01-01 rev v5.020"
	@echo
	@echo "----------------------------------------------------------------"

help_tb:
	@echo "----------------------------------------------------------------"
	@echo "Purdue SoCET Build System v$(VERSION)"
	@echo
	@echo "Testbench Data File Handling:"
	@echo "In order to pass data files to a testbench, the data files must"
	@echo "be included in the design's .core file's \"tb\" fileset. Any file"
	@echo "included this way has to be of type \"user\". The testbench will"
	@echo "be able to access these files as they appear in the core file."
	@echo "For example, if the file in the core is specified to be"
	@echo "\"data/meminit.hex : { file_type: user }\", then the testbench"
	@echo "should use the filepath \"data/meminit.hex\"."
	@echo 
	@echo "All testbench output files should be placed in the \"$(TB_OUT_DIR)\""
	@echo "directory by the testbench (this directory is created for you in"
	@echo "the runtime environment), and upon closure of the simulation"
	@echo "software the data files will be copied into \"$(TB_OUT_DIR_VIS)\"."
	@echo
	@echo "Note:"
	@echo "If it is necessary to see the files while the software is open,"
	@echo "they will be somewhere in the \"$(BUILD)\" directory. This "
	@echo "method is NOT recommended."
	@echo
	@echo "----------------------------------------------------------------"

test_colors:
	@$(CLR_BS_ERR)
	@echo "ERROR:    Build system error"
	@$(CLR_BS_WRN)
	@echo "WARNING   Build system warning"
	@$(CLR_SP_ERR)
	@echo "ERROR:    Sub-process error"
	@$(CLR_SP_WRN)
	@echo "WARNING:  Sub-process warning"
	@$(CLR_RST)



# SIMULATION TARGETS

versim_%_src: 
	@$(call sim_start,$*,sim,verilator,"Verilator")

	@fusesoc --cores-root . run --build-root $(BUILD) --run --target sim --tool verilator $(ORG):$(PROJECT):$*

	@$(call sim_end)

	@$(call finderr,$(BUILD),"*.eda.yml","Could not decode build directory structure.")
	@$(call finderr,$(BUILD),"waveform.vcd","Could not find waveform file.")
	@gtkwave $$(find $(BUILD) -name waveform.vcd) --save $$(dirname $$(find $(BUILD) -name "*.eda.yml"))/waves/$*.gtkw


qsim_%_src: 
	@$(call sim_start,$*,sim,modelsim,"QuestaSim CLI")

	@fusesoc --cores-root . run --build-root $(BUILD) --run --target sim --tool modelsim $(ORG):$(PROJECT):$*

	@$(call sim_end)


qsim_%_syn:
	@$(CLR_BS_ERR)
	@echo -e "\nSynthesis currently not supported.\n"
	@$(CLR_RST)
	@exit 1

	@$(call ftest,$(SYN)/$*.v,"Could not find the netlist for the $* design. Have you run \"make syn_$*\" yet?")
	@$(call sim_start,$*,syn_sim,modelsim,"QuestaSim CLI")

	@fusesoc --cores-root . run --build-root $(BUILD) --run --target syn_sim --tool modelsim $(ORG):$(PROJECT):$*

	@$(call sim_end)


qsimgui_%_src:
	@$(call sim_start,$*,sim,modelsim,"QuestaSim GUI")

	@$(call finderr,$(BUILD),"Makefile","Could not decode build directory structure.")
	@$(MAKE) -C $$(dirname $$(find $(BUILD) -name Makefile)) run-gui

	@$(call sim_end)


qsimgui_%_syn:
	@$(CLR_BS_ERR)
	@echo -e "\nSynthesis currently not supported.\n"
	@$(CLR_RST)
	@exit 1

	@$(call ftest,$(SYN)/$*.v,"Could not find the netlist for the $* design. Have you run \"make syn_$*\" yet?")
	@$(call sim_start,$*,syn_sim,modelsim,"QuestaSim GUI")

	@$(call finderr,$(BUILD),"Makefile","Could not decode build directory structure.")
	@$(MAKE) -C $$(dirname $$(find $(BUILD) -name Makefile)) run-gui

	@$(call sim_end)



# MAKE FUNCTIONS

define ftest = 
test -f $(1) || { $(CLR_BS_ERR) echo -ne "\nFILE ERROR ($(1)): "; $(CLR_RST) echo -e "$(2)\n"; false; }
endef

define finderr = 
find $(1) -name "$(2)" | grep . > /dev/null || { $(CLR_BS_ERR) echo -ne "\n$(3)\n\n" ; $(CLR_RST) false ; }
endef

define sim_start = 

echo "Simulating the $(ORG):$(PROJECT):$(1) using $(4)..."
$(MAKE) clean_build
$(call ftest,fusesoc.conf,"Could not find the FuseSoC configuration. Have you run \"make buildsys_setup\" yet?")
$(call ftest,$(SCRIPTS)/tb_datafiles.py,"Could not find the tb_datafiles script. Have you run \"make buildsys_setup\" yet?")
fusesoc --cores-root . run --build-root $(BUILD) --setup --build --target $(2) --tool $(3) $(ORG):$(PROJECT):$(1)
# python3 $(SCRIPTS)/tb_datafiles.py $$(find $(BUILD) -name "*.eda.yml") $(FS_DIRPAD)
$(call finderr,$(BUILD),"*.eda.yml","Could not decode build directory structure.")
find $(BUILD) -name "*.eda.yml" -exec python3 $(SCRIPTS)/tb_datafiles.py {} $(FS_DIRPAD) \;

$(debug_sim)

endef

define sim_end = 

# cp -r $$(find $(BUILD) -name "$(TB_OUT_DIR)")/ $(TB_OUT_DIR_VIS)/
@$(call finderr,$(BUILD),"$(TB_OUT_DIR)","Could not find testbench output files.")
find $(BUILD) -name "$(TB_OUT_DIR)" -exec cp -r {}/ $(TB_OUT_DIR_VIS)/ \;

endef



# Synthesis Variables
TECH_CORE = ece337:tech:AMI_05_LIB
TECH_DIR = /home/ecegrid/a/ece337/summer24-refactor/tech/ami05
TECH_LIB = $(TECH_DIR)/osu05_stdcells.db
TECH_LINK = $(TECH_LIB) dw_foundation.sldb
SYN_TOOL = design_compiler



# SYNTHESIS TARGETS

syn_%: clean_build
	@$(CLR_BS_ERR)
	@echo -e "\nSynthesis currently not supported.\n"
	@$(CLR_RST)
	@exit 1

	@$(call ftest,$(SCRIPTS)/synth.tcl,"Could not find synthesis script. Have you run \"make buildsys_setup\" yet?")
	@echo "Synthesizing the $(ORG):$(PROJECT):$* design using $(SYN_TOOL)..."
	@fusesoc --cores-root . run --build-root $(BUILD) --setup --build --run --target syn --tool $(SYN_TOOL) $(ORG):$(PROJECT):$*

	@$(call finderr,$(BUILD),"*.eda.yml","Could not decode build directory structure.")

	@echo "Storing reports for the $(ORG):$(PROJECT):$* design..."
	@mkdir -p $(REPORTS)
	@cp -r $$(dirname $$(find $(BUILD) -name "*.eda.yml"))/reports/* $(REPORTS)

	@echo "Checking synthesis log for errors and warnings..."
	@$(CLR_SP_ERR) grep -ix '^error.*$$' $(REPORTS)/synth.log; $(CLR_RST)
	@$(CLR_SP_WRN) grep -ix '^warning.*$$' $(REPORTS)/synth.log; $(CLR_RST)

	$(debug_syn)

	@$(call finderr,$(BUILD),"*.eda.yml","Could not decode build directory structure.")
	@$(call ftest,$$(dirname $$(find $(BUILD) -name "*.eda.yml"))/$*.v,"Synthesis failed to generate netlist.")

	@echo "Storing the netlist for the $(ORG):$(PROJECT):$* design..."
	@mkdir -p $(SYN)
	@find $(BUILD) -name "$*.v" -exec cp {} $(SYN)/ \;
	@$(MAKE) --no-print-directory _core_syn_$* > $(SYN)/$*_syn.core




# VARIABLES

# Course Library
PROJECT_LIB_DIR = /home/ecegrid/a/ece337/summer24-refactor/course-lib

# Directories
DIR_ROOT = tmp
BUILD = tmp/build
SYN = tmp/syn
SCRIPTS = tmp/scripts
REPORTS = reports
TB_OUT_DIR = tb_output_files
TB_OUT_DIR_VIS = tmp/tb_output_files

# FuseSoC behavior
# amount of directories that FuseSoC adds onto each file in the .eda.yml
FS_DIRPAD = 2
SCRIPT_SUBDIR = src/$(ORG)_$(PROJECT)_synfiles_0



# DEBUG COMMANDS

ifeq ($(DEBUG), 1)

define debug_sim =

@echo "Storing simulation debug information..."
@mkdir -p debug
@touch debug/FUSESOC_IGNORE
@cp -r $(DIR_ROOT) debug/sim
@cp Makefile debug/sim/Makefile
@cp fusesoc.conf debug/sim/fusesoc.conf
@rm -f debug.tar.gz
@tar -czf debug.tar.gz debug
@rm -r debug

endef

define debug_syn =

@echo "Storing synthesis debug information..."
@mkdir -p debug
@touch debug/FUSESOC_IGNORE
@cp -r $(DIR_ROOT) debug/syn
@cp Makefile debug/syn/Makefile
@cp fusesoc.conf debug/syn/fusesoc.conf
@cp -r $(REPORTS) debug/syn
@tar -czf debug.tar.gz debug

endef

else

define debug_sim = 
endef

define debug_syn = 
endef

endif



# ANALYSIS TARGETS

verlint_%:
	@fusesoc --cores-root . run --build-root $(BUILD) --setup --build --run --target lint --tool verilator $(ORG):$(PROJECT):$*

schem_%:
	@$(call ftest,$(SYN)/$*.v,"Could not find the netlist for the $* design. Have you run \"make syn_$*\" yet?")
	@dc_shell-t -x "set link_library \"$(TECH_LINK)\" ; read_file -format verilog -autoread -top $* $(SYN)/$*.v ; gui_start ; gui_create_schematic"



# SETUP TARGETS

buildsys_setup:
	@echo "Setting up Purdue SoCET Build System v$(VERSION)"
	@mkdir -p $(SCRIPTS)
	@$(MAKE) --no-print-directory _syntcl > $(SCRIPTS)/synth.tcl
	@$(MAKE) --no-print-directory _fusesoc_conf > fusesoc.conf
	@$(MAKE) --no-print-directory _tb_datafiles > $(SCRIPTS)/tb_datafiles.py
	@$(MAKE) --no-print-directory _synfiles_core > $(SCRIPTS)/synfiles.core
	@echo "Done!"



# MODULE GENERATION TARGETS

SUB_DIR ?= .
module_%: $(SUB_DIR)
	@echo "Creating files for module $* in ${SUB_DIR} ..."
	@mkdir -p ${SUB_DIR}/source
	@mkdir -p ${SUB_DIR}/testbench
	@mkdir -p ${SUB_DIR}/waves
	@$(MAKE) --no-print-directory _core_$* > $(SUB_DIR)/$*.core
	@$(MAKE) --no-print-directory _module_$* > $(SUB_DIR)/source/$*.sv
	@$(MAKE) --no-print-directory _testbench_$* > $(SUB_DIR)/testbench/tb_$*.sv
	@touch $(SUB_DIR)/waves/$*.do
	@touch $(SUB_DIR)/waves/$*.gtkw
	@echo "Done!"



# FUSESOC TARGETS

list_cores:
	@fusesoc --cores-root . core list

core_info_%:
	@fusesoc --cores-root . core show $*

# fusesoc library setup commands look like this: fusesoc library add fusesoc_cores git@github.com:fusesoc/fusesoc-cores
# make sure to use the ssh method rather than the https method when loading from non-public git repos
# use fusesoc library update to update



# CLEAN TARGETS

clean: clean_build clean_syn clean_debug clean_eda

veryclean: clean_reports clean_debug clean_fs clean clean_build clean_syn clean_scripts
	@rm -rf $(DIR_ROOT)

clean_build:
	@echo "Removing build files..."
	@rm -rf $(BUILD)

clean_syn:
	@echo "Removing generated netlists... "
	@rm -rf $(SYN)

clean_scripts:
	@echo "Removing generated scripts"
	@rm -rf $(SCRIPTS)

clean_reports:
	@echo "Removing generated reports"
	@rm -rf $(REPORTS)

clean_tbdata:
	@echo "Removing testbench output files"
	@rm -rf $(TB_OUT_DIR_VIS)

clean_debug:
	@echo "Removing debug information..."
	@rm -rf debug/ debug.tar.gz

clean_fs:
	@echo "Removing FuseSoC configuration"
	@rm -rf fusesoc.conf

clean_eda:
	@echo "Removing EDA tool specific files"
	@rm -rf default.svf command.log transcript filenames.log WORK_autoread *.pvl *.syn *.mr



# TEMPLATE TARGETS (DO NOT MODIFY OR RUN)

_module_%:
	@echo "\`timescale 1ns / 10ps"
	@echo
	@echo "module $* #("
	@echo "    // parameters"
	@echo ") ("
	@echo "    input clk, n_rst"
	@echo ");"
	@echo
	@echo
	@echo
	@echo "endmodule"
	@echo

_testbench_%:
	@echo "\`timescale 1ns / 10ps"
	@echo "/* verilator coverage_off */"
	@echo
	@echo "module tb_$* ();"
	@echo
	@echo "    localparam CLK_PERIOD = 10ns;"
	@echo
	@echo "    initial begin"
	@echo "        \$$dumpfile(\"waveform.vcd\");"
	@echo "        \$$dumpvars;"
	@echo "    end"
	@echo
	@echo "    logic clk, n_rst;"
	@echo
	@echo "    // clockgen"
	@echo "    always begin"
	@echo "        clk = 0;"
	@echo "        #(CLK_PERIOD / 2.0);"
	@echo "        clk = 1;"
	@echo "        #(CLK_PERIOD / 2.0);"
	@echo "    end"
	@echo
	@echo "    task reset_dut;"
	@echo "    begin"
	@echo "        n_rst = 0;"
	@echo "        @(posedge clk);"
	@echo "        @(posedge clk);"
	@echo "        @(negedge clk);"
	@echo "        n_rst = 1;"
	@echo "        @(posedge clk);"
	@echo "        @(posedge clk);"
	@echo "    end"
	@echo "    endtask"
	@echo
	@echo "    $* #() DUT (.*);"
	@echo
	@echo "    initial begin"
	@echo "        n_rst = 1;"
	@echo
	@echo "        reset_dut;"
	@echo
	@echo "        \$$finish;"
	@echo "    end"
	@echo "endmodule"
	@echo
	@echo "/* verilator coverage_on */"
	@echo

_core_%:
	@echo "CAPI=2:"
	@echo "name: \"$(ORG):$(PROJECT):$*:1.0.0\""
	@echo "description: \"\""
	@echo 
	@echo "filesets:"
	@echo "    rtl:"
	@echo "        files:"
	@echo "            - \"source/$*.sv\""
	@echo "        file_type: systemVerilogSource"
	@echo "        # depend:"
	@echo "        #     - \"fusesoc:core:name\""
	@echo
	@echo "    synth:"
	@echo "        depend:"
	@echo "            - \"$(TECH_CORE)\""
	@echo "            - \"$(ORG):$(PROJECT):$*_syn\""
	@echo
	@echo "    tb:"
	@echo "        files:"
	@echo "            - \"testbench/tb_$*.sv\""
	@echo "            - \"waves/$*.do\": { file_type: user }"
	@echo "            - \"waves/$*.gtkw\": { file_type: user }"
	@echo "            # - \"data/file.txt\": { file_type: user }"
	@echo "        file_type: systemVerilogSource"
	@echo
	@echo "    synfiles:"
	@echo "        depend:"
	@echo "            - \"$(ORG):$(PROJECT):synfiles\""
	@echo
	@echo "targets:"
	@echo "    default: &default"
	@echo "        filesets:"
	@echo "            - rtl"
	@echo "        toplevel: $*"
	@echo
	@echo "    sim: &sim"
	@echo "        <<: *default"
	@echo "        default_tool: verilator"
	@echo "        filesets_append:"
	@echo "            - tb"
	@echo "        toplevel: tb_$*"
	@echo "        tools:"
	@echo "            modelsim:"
	@echo "                vsim_options:"
	@echo "                    - -vopt"
	@echo "                    - -voptargs='+acc'"
	@echo "                    - -t ps"
	@echo "                    - -do waves/$*.do"
	@echo "                    - -onfinish stop"
	@echo "                    - -do \"set PrefSource(OpenOnFinish) 0 ; set PrefMain(LinePrefix) \\\"\\\" ; set PrefMain(colorizeTranscript) 1\""
	@echo "                    - -coverage"
	@echo "                vlog_options:"
	@echo "                    - +cover"
	@echo "            verilator:"
	@echo "                verilator_options:"
	@echo "                    - --cc"
	@echo "                    - --trace"
	@echo "                    - --main"
	@echo "                    - --timing"
	@echo "                    - --coverage"
	@echo "                make_options:"
	@echo "                    - -j"
	@echo
	@echo "    lint:"
	@echo "        <<: *default"
	@echo "        default_tool: verilator"
	@echo "        filesets_append:"
	@echo "            - tb"
	@echo "        tools:"
	@echo "            verilator:"
	@echo "                mode: lint-only"
	@echo "                verilator_options:"
	@echo "                    - --timing"
	@echo "                    - -Wall"
	@echo
	@echo "    syn:"
	@echo "        <<: *default"
	@echo "        filesets_append:"
	@echo "            - synfiles"
	@echo "        default_tool: design_compiler"
	@echo "        toplevel: $*"
	@echo "        tools:"
	@echo "            design_compiler:"
	@echo "                script_dir: \"$(SCRIPT_SUBDIR)\""
	@echo "                dc_script: \"synth.tcl\""
	@echo "                report_dir: \"$(REPORTS)\""
	@echo "                target_library: \"$(TECH_LIB)\""
	@echo "                link_library: \"$(TECH_LINK)\""
	@echo 
	@echo "    syn_sim:"
	@echo "        <<: *sim"
	@echo "        filesets:"
	@echo "            - synth"
	@echo "            - tb"
	@echo

_fusesoc_conf:
#	@echo "[library.$(TECH_CORE)]"
#	@echo "location = $(TECH_DIR)"
#	@echo "sync-type = local"
#	@echo
#	@echo "[library.course-lib]"
#	@echo "location = $(PROJECT_LIB_DIR)"
#	@echo "sync-type = local"
	@echo

_core_syn_%:
	@echo "CAPI=2:"
	@echo "name: \"$(ORG):$(PROJECT):$*_syn\""
	@echo
	@echo "filesets:"
	@echo "    netlist:"
	@echo "        files:"
	@echo "            - \"$*.v\""
	@echo "        file_type: systemVerilogSource"
	@echo
	@echo "targets:"
	@echo "    default:"
	@echo "        filesets:"
	@echo "            - netlist"
	@echo "        toplevel: $*"
	@echo

_tb_datafiles:
	@echo "import yaml, sys, os, subprocess"
	@echo 
	@echo "fusesoc_pad_dirs = int(sys.argv[2])"
	@echo "edayml = sys.argv[1]"
	@echo 
	@echo "buildroot = os.path.dirname(edayml)"
	@echo "subprocess.check_output([\"mkdir\", buildroot + \"/\" + \"$(TB_OUT_DIR)\"])"
	@echo "with open(edayml) as stream:"
	@echo "    try:"
	@echo "        edainfo = yaml.safe_load(stream)"
	@echo "        for file in edainfo[\"files\"]:"
	@echo "            if file[\"file_type\"] == \"user\":"
	@echo "                newfile = buildroot + \"/\" + \"/\".join(file[\"name\"].split(\"/\")[fusesoc_pad_dirs:])"
	@echo "                oldfile = buildroot + \"/\" + file[\"name\"]"
	@echo "                subprocess.run([\"mkdir\", \"-p\", os.path.dirname(newfile)])"
	@echo "                subprocess.run([\"cp\", oldfile, newfile])"
	@echo "    except yaml.YAMLError as exc:"
	@echo "        print(\"Error reading .eda.yml\")"
	@echo

_syntcl:
	@echo "source \$$READ_SOURCES.tcl"
	@echo "elaborate \$$TOP_MODULE"
	@echo "uniquify"
	@echo
	@echo "# set_max_delay <delay> -from \"<input>\" -to \"<output>\""
	@echo "# set_max_area <area>"
	@echo "# set_max_total_power <power> mW"
	@echo "# create_clock <clock_name> -name <clock_name> -period <clock period>"
	@echo
	@echo "compile -map_effort medium"
	@echo "report_timing -path full -delay max -max_paths 1 -nworst 1 > \$$REPORT_DIR/\$$TOP_MODULE.rep"
	@echo "report_area >> \$$REPORT_DIR/\$$TOP_MODULE.rep"
	@echo "report_power -hierarchy >> \$$REPORT_DIR/\$$TOP_MODULE.rep"
	@echo 
	@echo "write_file -format verilog -hierarchy -output \$$TOP_MODULE.v"
	@echo "check_design"
	@echo "quit"
	@echo

_synfiles_core:
	@echo "CAPI=2:"
	@echo "name: \"$(ORG):$(PROJECT):synfiles\""
	@echo 
	@echo "filesets:"
	@echo "    scripts:"
	@echo "        files:"
	@echo "            - \"synth.tcl\""
	@echo "        file_type: user"
	@echo 
	@echo "targets:"
	@echo "    default:"
	@echo "        filesets:"
	@echo "            - scripts"
	@echo
