
# Maintainer: Your Name <youremail@domain.com>
pkgname=vled
pkgver=0.7.0
pkgrel=1
epoch=
pkgdesc="A text editor with syntax highlighting support written entirely in standard Lua 5.3"
arch=('any')
url=""
license=('GPL')
groups=()
depends=(lua)
makedepends=()
checkdepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=("https://github.com/ocawesome101/standard-lua-vled/raw/master/vled.tar")
noextract=()
md5sums=(34818b892d7284e9d72a5be71bab13fd)
validpgpkeys=()

package() {
  mkdir -p "$pkgdir/usr/bin"
  mkdir -p "$pkgdir/usr/lib/lua/5.3"
  cp vled.lua "$pkgdir/usr/bin/vled"
  cp editor.lua "$pkgdir/usr/lib/lua/5.3/editor.lua"
  cp readline.lua "$pkgdir/usr/lib/lua/5.3/readline.lua"
  cp -r vled "$pkgdir/usr/lib/lua/5.3/"
}
