# Introduction

The chiplet protocol consists of networking components to enable efficient
offchip communication between functional units. The networking stack consists
of three layers: the protocol layer, the data link layer, and the physical
layer. The stack is visualized below.

![Network Stack](images/network_stack.svg)

An example topology is shown below. In this configuration, the physical layer
uses UART to communicate across links. Routing tables can be configured such
that Device 4 can only send packets to Device 3 through the chain Device
4->Device 2->Device 1->Device 3. Each set of endpoint, switch, and physical
layer are called a **tile**.

![Example Topology](images/topology.svg)

### Terminology

- Endpoint: the bus-connected component which enables communication in the network
- Message: an entire packet made up of a number of words dependent on the format and length of the header
- Packet: same as message
- Flit: the smallest atomic unit sent across the network, is defined to be 32 bits
- Link: a bidirectional communication channel between nodes
- Tile: a combination of an endpoint, switch, and physical layer which allows a node to enter the network
- Node: Generally, anything that can communicate in a network, in certain contexts it may mean members of a network who are not responsible for network configuration
- Controller: The node which is responsible for network configuration

### Topology constraints

- There are a maximum of 31 devices connected in a single network
- Each device may have up to 4 messages in flight
- Node ID 0 is reserved and can mean any node in certain contexts

## Integration

A tile can be integrated into an existing design by instantiating it with your
top level, connecting the bus interface of the endpoint with your design, and
then exposing the `tile_tx` and `tile_rx` signals as top level ports. As long
as your design can talk using a bus, it can integrate easily with a tile. Note
that there is no baud-rate handshake done, so tiles should be configured to run
at the standard baud-rate of 1MHz.
