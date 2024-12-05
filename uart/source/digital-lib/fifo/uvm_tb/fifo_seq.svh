import uvm_pkg::*;
`include "uvm_macros.svh"
`include "fifo_transaction.svh"

class fifo_seq #(type T = logic [7:0], int DEPTH = 8, int ITEMS = 101) extends uvm_sequence#(transaction#(T, DEPTH));
    `uvm_object_param_utils(fifo_seq#(T, DEPTH, ITEMS))

    function new(string name = "fifo_seq");
        super.new(name);
    endfunction //new()

    task body();
        transaction#(T, DEPTH) req_item;
        req_item = transaction#(T, DEPTH)::type_id::create("req_item");

        repeat(ITEMS) begin
            start_item(req_item);
            if (!req_item.randomize()) begin
                `uvm_fatal("FIFO_Sequence", "Unable to randomize")
            end
            finish_item(req_item);
        end
    endtask
endclass //fifo_seq extends uvm_sequence

class read_write_fifo_seq #(type T = logic [7:0], int DEPTH = 8) extends uvm_sequence#(transaction#(T, DEPTH));
    `uvm_object_param_utils(read_write_fifo_seq#(T, DEPTH))

    function new(string name = "read_write_fifo_seq");
        super.new(name);
    endfunction //new()

    task body();
        transaction#(T, DEPTH) req_item;
        req_item = transaction#(T, DEPTH)::type_id::create("req_item");

        repeat(DEPTH + 1) begin
            start_item(req_item);
            if (!req_item.randomize()) begin
                `uvm_fatal("FIFO_Sequence", "Unable to randomize")
            end
            req_item.WEN = 1;
            req_item.REN = 0;
            req_item.clear = 0;
            finish_item(req_item);
        end
        repeat(DEPTH + 1) begin
            start_item(req_item);
            req_item.WEN = 0;
            req_item.REN = 1;
            req_item.clear = 0;
            finish_item(req_item);
        end
    endtask
endclass //read_write_fifo_seq extends uvm_sequence

class clear_fifo_seq #(type T = logic [7:0], int DEPTH = 8) extends uvm_sequence#(transaction#(T, DEPTH));
    `uvm_object_param_utils(clear_fifo_seq#(T, DEPTH))

    function new(string name = "clear_fifo_seq");
        super.new(name);
    endfunction //new()

    task body();
        transaction#(T, DEPTH) req_item;
        req_item = transaction#(T, DEPTH)::type_id::create("req_item");

        repeat(DEPTH / 2) begin
            start_item(req_item);
            if (!req_item.randomize()) begin
                `uvm_fatal("FIFO_Sequence", "Unable to randomize")
            end
            req_item.WEN = 1;
            req_item.REN = 0;
            req_item.clear = 0;
            finish_item(req_item);
        end

        start_item(req_item);
        req_item.clear = 1;
        finish_item(req_item);

        repeat(DEPTH + 1) begin
            start_item(req_item);
            if (!req_item.randomize()) begin
                `uvm_fatal("FIFO_Sequence", "Unable to randomize")
            end
            req_item.WEN = 1;
            req_item.REN = 0;
            req_item.clear = 0;
            finish_item(req_item);
        end

        start_item(req_item);
        req_item.clear = 1;
        finish_item(req_item);

        start_item(req_item);
        req_item.clear = 1;
        finish_item(req_item);
    endtask
endclass //clear_fifo_seq extends uvm_sequence

class fifo_sequencer#(type T = logic [7:0], int DEPTH = 8) extends uvm_sequencer#(transaction#(T, DEPTH));
    `uvm_component_utils(fifo_sequencer#(T, DEPTH))

    function new(string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()
endclass //fifo_sequencer extends uvm_sequencer
