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

The switch module consists of input buffers that store incoming flits from the
physical layer. There is one buffer for each node connected to a particular
switch and one buffer for packets being sent by the endpoint at the same node
as the switch. Each buffer has a single virtual channel connected to it. The
virtual channel is an alternate route through the network that will prevent the
network from deadlocking a packet will go into a virtual channel instead of the
normal buffer when the normal buffer is full or the packet has crossed the
dateline. 

Once the head flit of each packet is stored in the input buffer or the virtual
channel buffer, it is sent to be arbitrated entry to the route compute stage.
Packets can be claimed by the switch register bank once it enters the route
compute stage. If this happens, it will not pass to the next pipeline stage. If
the packet is not a configuration packet then the route compute module will
search through the lookup table based on the requestor and the destination of
the packet and send the output port that the packet should go through to the
virtual channel allocator. The virtual channel allocator will decide whether
a packet is crossing a dateline, and if it is, will assign it the appropriate
virtual channel. The switch allocator then takes the virtual channel and
destination information from the previous stages and tries to allocate a spot
in the crossbar for the packet to be sent through. If it is unable to allocate
a spot, the packet must retry its entry into the pipeline.

TODO: talk about each pipeline stage and details


![Switch Architecture](images/switch_2_rtl.svg)



TODO: talk about memory map

#### Configuration 

When configuring a chiplet network the controller must first get its own node and 
routing table from its core. It can then send a node and routing table to each other 
node in the network which allows a node to send and recieve packets. Once a node is 
configured it will recieve a config done packet that will signal to that node's core 
that it can send packets.

#### Switch Memory Map

| Address            |     Name      |  Description                                                                                                                                       |
| :------------------| :-----------: | :------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0x00               |  Route LUT 0  |  A `{src, dest, out}` triplet that can be used to determine the route of a packet. A `src` or `dest` of 0 matches all packets.                     |
| ...                |  Route LUT n  | See above                                                                                                                                          |
| 0x10               |  Route LUT 16 | See above                                                                                                                                          |
| 0x11               |    Dateline   | A 15 wide bitfield that determines whether a certain egress port crosses a dateline. A 1 in bit `i` means that egress port `i` crosses a dateline. |
| 0x12               |    Node ID    | Sets a tiles node ID which is used when sending and receiving packets.                                                                             |
| 0x13               |  Config Done  | This register is set to 1 when configuration of a strongly connected component is completed.                                                       |

### Speculative Switch Allocation

The 3-stage pipelined switch supports speculative switch allocation. This
optimization forwards the inputs of the virtual channel allocator to the switch
allocator, and will allocate both virtual channel slots in the crossbar if they
are both unallocated. Once the packet reaches the switch allocation stage, it
will clean up the speculative work by deallocated the unused virtual channel.
This allows a certain class of packets to be sent across the switch in 2 cycles
instead of 3.

### Virtual Channels

Virtual channels are used to ensure deadlock avoidance in the network. If there
are packets being sent in a cyclic pattern, and no packet can make progress,
then a deadlock has occurred in the network. Virtual channels break that
deadlock by virtualizing a single physical link into multiple channels that
packets can flow through. This requires the network to be set up to break any
cyclic connections in the network through the use of a **dateline** which is
a link connection which move packets in virtual channel 0 to virtual channel 1.
By introducing this virtual channel, it breaks the cycle in the network, and
therefore deadlocks cannot occur in a properly configured network. The switch
has a single register which tracks which egress ports cross a dateline so that
the VC field of the metadata can be set appropriately during the virtual
channel allocation stage of the pipeline.

### Switch Testing

There are two testbenches for the switch: one for correctness (deadlock
avoidance, routing closure, etc), and one for measuring the performance of the
switch architecture. The correctness testbench can be run using `make
versim_switch_src_correctness` from the top level directory. The performance
benchmark can be run using `make versim_switch_src_measure` from the top level
directory. The benchmarking testbench will produce the files
"switchX_perf_$time.txt" in the `tmp/build` directory which can be used with
the `switch/scripts/parse_switch_stats.py` script to produce more readable
statistics of the run.

### References

The switch architecture was heavily inspired by the [router architecture notes
from Stanford's
EE482B](http://cva.stanford.edu/classes/ee382c/ee482b/scribes01/lect10/lect10.pdf)
and the [router microarchitecture slides from Georgia Tech's ECE
8823A](https://bpb-us-e1.wpmucdn.com/sites.gatech.edu/dist/8/175/files/2016/10/L10-RouterMicroarchitecture.pdf?bid=175).
