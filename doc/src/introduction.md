# Introduction

The chiplet protocol consists of networking components to enable efficient
offchip communication between functional units. The networking stack consists
of three layers: the protocol layer, the data link layer, and the physical
layer. The stack is visualized below.

![Network Stack](images/network_stack.svg)

An example topology is shown below. In this configuration, the physical layer
uses UART to communicate across links. This configuration uses bidirectional
packet communication, however, this is not a requirement. Routing tables can be
configured such that Device 2 can only send packets to Device 0 through the
chain Device 2->Device 3->Device 1->Device 0.

![Example Topology](images/topology.svg)

### Terminology

- Endpoint: the bus-connected component which enables communication in the network
- Message: an entire packet made up of a number of words dependent on the format and length of the header
- Packet: same as message
- Flit: the smallest atomic unit sent across the network, is defined to be 32 bits
- Link: a bidirectional communication channel between nodes

### Topology constraints

- There are a maximum of 32 devices connected in a single network
- Each device may have up to 4 messages in flight
