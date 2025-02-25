project_new socet_chiplet_endpoint_0_0_1 -overwrite
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY endpoint
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_bus-components_bus_protocol_if_0.0.1/bus_protocol_if.sv
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_digital-lib_counter_0.0.1/src/socetlib_counter.sv
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_digital-lib_lfsr_0.0.1/src/socetlib_lfsr.sv
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_digital-lib_crc_0.0.1/src/socetlib_crc.sv
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_chiplet_endpoint_0.0.1/source/endpoint.sv
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_chiplet_endpoint_0.0.1/source/cache.sv
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_chiplet_endpoint_0.0.1/source/tx_fsm.sv
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_chiplet_endpoint_0.0.1/source/rx_fsm.sv
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_chiplet_endpoint_0.0.1/source/req_fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE src/socet_chiplet_endpoint_0.0.1/source/message_table.sv
set_global_assignment -name SEARCH_PATH src/socet_chiplet_include_0.0.1/source
set_global_assignment -name SEARCH_PATH src/socet_chiplet_endpoint_0.0.1/include
