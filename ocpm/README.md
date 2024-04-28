# ocpm
A package manager for OC Linux. Similar to Apt.

`ocpm.lua` is the script itself. It half works.

`cache` should be `/var/cache`.

Should be run inside OC Linux!

### Adding sources
To add a source to OC Linux, you can either directly put a link in your `/etc/ocpm/sources.list` file, or you can run `ocpm addrepo <url>`. `url` can be one of the following:

- a GitHub repo: `git:user/repo/branch/` or `https://raw.githubusercontent.com/user/repo/branch/`. In the root of said branch must be a `packages.list` file. See [this](https://github.com/ocawesome101/ocpm-packages) for an example of a `packages.list` file.

- a Web site: `https://repo.example.com/stable/`. Note that Web sites must have `packages.list` in the same directory that `index.html` would be - in this case, `/opt/www/example/stable/packages.list` in the server filesystem. Alternatively, you can just use the link to the file (`https://example.com/raw/packages.list`) but without `packages.list` at the end (`https://example.com/raw/`). The file MUST be named `packages.list`!

I may make a package list generator at some point in the future, probably written in either Python or Lua.

NOTE: The `packages.list` format has not yet been finalized and is liable to change without notice.
