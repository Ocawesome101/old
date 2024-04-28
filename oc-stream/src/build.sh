#!/bin/bash

set -e

moonc=$(which moonp)
declare -A statii
statii=([ok]=" \e[92mOK " [fail]="\e[91mFAIL" [info]="\e[94mINFO")

log() {
  printf "\e[97m[ ${statii[$1]}\e[97m ] "
  shift
  printf "$@\e[39m\n"
}

build() {
  ${moonc} -o build/$(echo $1 | sed 's/moon/lua/') $1
}

revision=$(git rev-parse --short HEAD)
moonver=$(${moonc} -v | sed 's/[mM]oon[sS]cript version //g' | sed 's/[Mm]oonscript+ version: //g')

log info "STREAM revision: \e[93m$revision"
log info "Moonscript compiler: \e[93m$moonc"
log info "Moonscript version: \e[93m$moonver"
log info "Bash version: \e[93m$BASH_VERSION"

for f in $(tree -infF --noreport | grep -v build | grep moon | tail -n +2); do
  log info $f
  build $f
done
