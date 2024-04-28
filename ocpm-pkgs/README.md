# ocpm-pkgs
Packages for OCPM

An OCPM repository must have a `packages.list` in the same format as mine (returns a table when called with `dofile`), and packages (rather obviously).

An OCPM package must have an `install.lua` script and an `uninstall.lua` script at a minimum (for instance, `install.lua` can pull packages from pastebin or elsewhere), and it must be zipped with the default OC Linux `arc` program.

An example OCPM package is:

`example`

`example/install.lua`

`example/uninstall.lua`

`example/usr/bin/example.lua`

One would then run `arc p ./example` from the parent directory of `example`.
