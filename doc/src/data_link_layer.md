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

  The switch module consists of input buffers that store incoming flits from the phy layer. 
There is one buffer for each node connected to a particular switch and one buffer for packets
being sent by the endpoint at the same node as the switch. Each buffer has one virtual channel
connected to it. The virtual channel is an alternate route through the network that will
prevent the network from deadlocking a packet will go into a virtual channel instead of the 
normal buffer when the normal buffer is full or the packet has crossed the dateline. 

 Once the head flit of each packet is stored in the input buffer or the virtual channel. The head 
flit is sent to the route compute and the switch's register bank. If the packet is a switch
configuration packet and its destination is the node that it is currently at then the register
bank can configure either the dateline or the routing look up table. If the packet is not a 
configuration packet then the route compute module will search through the lookup table based
on the requestor and the destination of the packet and send the output port that the packet
should go through to the switch allocator. The switch allocator module then takes the information
from the route compute module and check if the buffer is ready to send the packet to the crossbar 
switch and the switch allocator will enable the correct outport of the corssbar switch so the 
packet can go from the input buffer to the crossbar switch to the phy layer. Another component 
of the switch is the virtual channel allocator that sends and recieves virtual channel information
to other switchs in the network so they know when to send a packet to a virtual channel instead 
of the normal buffer. 

![General Format](images/switch.svg)


#### Switch Memory Map

![General Format](images/switch_map.svg)
