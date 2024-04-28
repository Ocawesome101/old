# OC-L4 system calls

- `ipcopen(process:string or number): table or nil, string`

  Open an IPC channel to process `process`.

- `ipcsend(process:string or number, response:table, message:string[, ...]): boolean or nil, string`

  Send an IPC message to process `process`. May set table `response` to the process's response.

- `evtpush(signal:string[, ...])`

  Push signal `signal` to the signal queue.

- `evtpull([timeout:number])`

  Pull an signal from `signal` queue, optionally with timeout `timeout`.

- `evtblock(signal:string): boolean`

  Prevent the current process from receiving signals of ID `signal`. Used primarily in drivers to prsignal being ctrl-C'd.

- `evtunblock(signal:string): boolean`

  Unblock signal of ID `signal`.

- `detach(): boolean or nil, string`

  Detach the current process from its parent, reattaching to the `init` process.

- `spawn(func:function, name:string[, handler:function[, blacklist:table[, env:table[, stdin:table[, stdout:table]]]]]): number`

  Spawn a process from the provided function, with name `name`. Returns the resultant PID.

- `spawnfile(file:string[, name:string[, handler:function[, blacklist:table[, env:table[, stdin:table[, stdout:table]]]]]]): number`

  Similar to `spawn`, except the first parameter is the path to a file.

- `current(): number`

  Get the current PID.
  
- `die()`

  Kill the current process. Shorthand for `kill(current())`.

- `kill(pid:number): boolean or nil, string`

  Attempt to kill process `pid`.
  
## IPC channels

IPC channels returned by `ipcopen` provide the following methods:

- `chan:write(response:table, message:string[, ...]): boolean or nil, string`

  Like `ipcsend`, but localized to the channel.

- `chan:close(): boolean or nil, string`

  Close the channel.

## IPC signals

Processes receive IPC in much the same way as signals, excepting that they are localized. The syntax of an IPC signal is as follows:

  `"ipc":string, from:number, response:table, message:string, ...`
  
It can be identified through the `"ipc"` signal ID. `from` is the PID from which the request came, and `response` is the table to which the receiving process should write its response, if any. `message` and all further parameters are the actual IPC message data.
