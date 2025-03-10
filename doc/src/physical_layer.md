# Physical Layer
    The Physical layer consists of 8b/10b encoding and 5 parallel uart ports to transmit data. Flits are supplied and encoded/decoded by the 
    phy managers into 8b/10b and are then sent to the parallel uarts. The phy managers are also responsible for inserting 8b/10b komma control flow 
    into packet transmission. The phy_manager_rx also implements crc checking to ensure no issues in flit transmission.
### PHY Managers
    The phy manager utilizes 8b 10b encoding which converts 8 bit words into 10 bit characters. This allows for extra error checking (only 256/1024 valid characters) and control flow insertion
    (can use extra characters to indicate starting and stoping of packets). For control flow we use special coma characters that cannot be generated by the normal 8b/10b encoding to send
    ack, nack, resend packets and start and stop packet across the network. 

    The Phy manager rx consists of 2 distinct parts the actual 8b/10b decoder (can be seen in wrap_8b_10b_dec.sv) and the crc error detection with a header decoder.
    this can be seen across the phy_manager_rx wrapper which holds the 8b_10b_dec_wrapper (responsible for latching the UART outptut) as well as extra logic to wrap
    the decoder with the CRC and correctly time the output.

    The Phy manager tx consists of an arbitration buffer to arbitrate between commas and data flits and to store potential commas to send across the network while the 
    tx is busy. It also has an 8b_10b_enc which encodes the data to the uarts and provides the correct comma when commas are arbitrated to. 


    TOP LEVEL: endnode
    rx:
        enc_flit_rx ~ sends 
        done_rx ~ flit recieved and done
        crc_corr_rx ~ correct crc value recieved
    tx:
        flit_tx ~ to send_flit
        get_data ~ fetch next data packet from memory

### 5-wide UART
    The phy layer consists of 5 parallel UARTs  and can be seen in the /uarts directory. UART (Universal Asynchronous Reciever Transmitter) is a standard
    protocol for asynchronous serial data transmission. UART generally sends 1 start bit with value 0 followed by a configurable length message (8-10 message bits)
    followed by any number of parity bits(0 -2) and an end bit with a value 1. Since our implementation uses 8b/10b in the Phy Manager and we are using 5 parallel 
    ports, we can gaurantee bit disparity across all 5 ports during a message transmission. This then means we can send variable length messages 
    due to the gaurantee that there will not be a start bit or stop bit across all 5 ports at the same time.
    
    TOP LEVEL: UART_BAUD   
    parameters: 
        FREQUENCY ~ synthesized frequency of system
        PORTCOUNT ~ number of ports in UART
        EXPECTED_BAUD_RATE ~ expected baud rate for system

    uart_rx_if ~ noteworthy interface signals
        uart_in ~ uart data in
        data ~ enc_flit out
        comma_sel ~ length of message used to calculate if incoming message is coma or not
        done_out ~ done output of rx 

    uart_rx_if ~ noteworty interface signals
        data ~ enc_flit in
        uart_out ~ uart output out
        comma_sel ~ outgoing length of message select used to calculate if outgoing message is komma
        done ~ packet is odne sending
