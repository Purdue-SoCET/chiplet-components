`ifndef END_IF_VH
`define END_IF_VH

interface endnode_if;
    // Input signals from external connections to the end node
    logic uart_rx_in; // UART RX input signal
    logic start_tx;   // Start signal for TX
    flit_t flit_tx;   // Flit to be transmitted
    comma_sel_t comma_sel; // Comma select signal

    // Output signals from the end node to external connections
    logic uart_out_tx; // UART TX output signal
    logic done;        // Transmission done signal
    logic err_tx;      // TX error signal

    // Input signals for RX path
    comma_sel_t comma_sel_rx;
    logic done_rx;
    logic err_rx;
    logic crc_corr_rx;
    flit_t flit_rx;

    // Modport definitions
    modport eif(
        input uart_rx_in, start_tx, flit_tx, comma_sel_tx,
        output uart_out_tx, done_tx, err_tx, comma_sel_rx, done_rx, err_rx, crc_corr_rx, flit_rx
    );
endinterface

`endif // END_IF_VH