#!/usr/bin/env bash

set -e

[ ! -d "data" ] && (echo 'This script must be run from root folder'; exit -1 )

terraform fmt
tflint
