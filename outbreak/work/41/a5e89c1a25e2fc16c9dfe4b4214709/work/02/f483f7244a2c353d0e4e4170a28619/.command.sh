#!/bin/bash -euo pipefail
mkdir index
bwa index  -p index/ref ref.fa 
echo $(bwa 2>&1) | sed 's/^.*Version: //; s/Contact:.*$//' > bwa.version.txt
