# MCLANG

An experimental programming language that compiles to a Minecraft 1.16+ datapack. Work in progress.

The compiler is written in Lua. See `src/mcl/definitions.lua` for defined functions.

All variables are stored in the scoreboard `mclvars`. The basic preprocessor allows `#include "path/to/file.mcl"` to include a variable and `#define VAR VALUE` to define a constant.
