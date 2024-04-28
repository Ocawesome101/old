# C/OS

C/OS is a small, lightweight OS with a focus on stability. C/OS is intended for servers or other applications where stability is essential. It provides basic multitasking with shared I/O - that is, a component call yields the current thread, leading to perhaps slightly slower response times but with the benefit of not locking up the system as much when a file is being read.

There is no real distinction between user space and kernel space; the global table `_G` is hardened - made partially read-only, i.e. user programs may still insert their own items, but may not change existing ones - along with all sub-tables.

### The Kernel

See [kernel.md](kernel.md) for details.

## Interfaces

C/OS's default interface is a simple Lua REPL similar to PsychOS. The screen may be interfaced with either directly or through the `term` API. VT100 is not supported or implemented. Only very, very basic line editing is supported.

## Updates

C/OS has the ability to update most core components without a system restart. In the default interface, simply run `sys.upgrade()` and any available upgrades will be automatically downloaded and installed.
