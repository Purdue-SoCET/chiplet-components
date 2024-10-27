`ifndef MESSAGE_TABLE_IF_VH
`define MESSAGE_TABLE_IF_VH

interface message_table_if #(parameter NUM_MSGS=4);
    logic [NUM_MSGS-1:0] trigger_send;

    modport msg_table(
        input trigger_send
    );
endinterface

`endif
