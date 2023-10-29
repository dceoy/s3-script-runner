#!/usr/bin/env bash

set -euox pipefail

df -Th | tee /mnt/s3/df_Th.txt
ls -la /mnt/s3
