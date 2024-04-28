STREAM
======
The Superb Terrific Really Extremely Awesome Microkernel (STREAM) is a microkernel for the OpenComputers Minecraft mod.

DESIGN
======
STREAM's design choices are:
  
  - Everything is a URL: similar to the real-world Redox (https://redox-os.org), any reference to a file, process, or anything else is a URL. A request takes the form of `connect([protocol]://[domain], [mode: optional])`. For example, the STREAM equivalent of `open("/bin/sh.lua", "r")` is `connect("file:///bin/sh.lua")`.
    
    - Several different protocols are supported: `file://[path]` for local files; `pid://[pid]` to open an IPC connection to a process; `http[s]://[domain]` to connect to external Web sites using an Internet card; `snet://[remotepid]` to connect specifically to a remote process.

    - URLs may, at their end, contain an ampersand-delimited or semicolon-delimited query string in the form `?[querystring]`, for example `?mode=w&append=false`

  - PIDs are numbers in the form [node].[subgroup].[id]. `node` refers to the node on which the process is running; in most cases, it should be `0`, for the local machine. If `node` is not `0`, STREAM will search for another STREAM instance using the STREAMNET protocol (see below). Default `subgroup`s are: `0` for kernel processes (usually only init), `1` for drivers, and `2` onward for userspace processes.

STREAMNET
=========
The STREAMNET (STREAM Network Extended Transmission) protocol is used internally among STREAM computers to denote a computer's node identifier. Identifier `0` always specifies the local machine.

STREAMNET operates using port 42.

STREAMNET uses the following messages to communicate:

  - `snet_request_id()`: A new node is requesting its node identifier. Every node should maintain an internal map of `modem` addresses to node identifiers. This map does not need to be complete on all nodes, though at least one node should have a complete map.
  
  - `snet_node_registered(modemAddr:string, nodeID:number)`: A new node has been registered. All receiving nodes should associate `modemAddr` with `nodeID`.

  - `snet_node_unregistered(nodeID:number)`: A node has left the STREAMNET network, i.e. has been shut down or crashed.

  - `snet_connect(nodeID:number)`: Broadcast a message asking for the modem address of the node whose identifier matches the provided `nodeID`.

  - `snet_write(connectionID: number, data:string)`: The receiving node's internal read-buffer should be updated.

  - `snet_read(connectionID: number, len:number)`: A node is requesting more data than its internal read-buffer contains.

  - `snet_close(connectionID: number)`: Close the specified connection.
