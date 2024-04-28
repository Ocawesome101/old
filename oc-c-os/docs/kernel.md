# C/OS kernel

The C/OS kernel is a monolithic, though modular, kernel. It supports dynamic loading and unloading of modules at runtime. If a module errors or fails to load, it will be automatically reloaded at an interval of ten seconds until it succeeds, or until 5 attempts have been made. If a module fails 5 times in a row, the system will attempt to load the last known good version of the module. If the module succeeds, it will be registered as the last known good version of a module.

### Threading

The C/OS kernel provides a cooperative scheduler based on coroutines.
