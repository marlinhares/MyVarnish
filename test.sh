#!/bin/sh
set -e

#If curl and Rancher
echo TEstando url $1 comando $2
if hash $2 2>/dev/null &&  $2 $1 2>/dev/null >/dev/null; then
  echo entrou
fi
echo final
