# Data-Link Layer

### 8b/10b Encoding

8b/10b encoding is a communications industry standard. This encoding takes 8 bit words and 
encodes them as 10 bit symbols by checking the running disparity of the number of ones and 
zeros in the lower 5 bits and the upper 3 bits. This is all for the purposes of DC balance, 
clock recovery and a small amount of error checking. Using 8b/10b encoding we will encode 
our 32 bit flits as 40 bit encoded flits, with the additional 8 bits of metadata that will 
be encoded for each flit the total size needed to be transmitted for each 32 bits of packet 
information is 50 bits. This encoding and decoding happens in between the switch and the 
phy layer. The switch only deals with decoded flits and the phy layer only sends and 
recieves encoded flits. When flits are decoded before entering the switch input buffers the
crc values of the packets are also checked for potential errors.

![General Format](images/8b10b.svg)

### Switch Architecture

#### Switch Memory Map
