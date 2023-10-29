#!/usr/bin/env bash

set -euox pipefail

df -Th | tee "${1}"
ls -l "${1}"
