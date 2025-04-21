#!/bin/bash -ue
mkdir -p logs results/bactmap

nextflow run nf-core/bactmap       --input      /workspaces/nf-comparative-genomics/outbreak/dummy/bactmap/samples.csv       --reference  /workspaces/nf-comparative-genomics/outbreak/dummy/bactmap/ref.fa       -profile     conda       --trim --remove_recombination --iqtree       --max_memory 15.GB       --outdir     results/bactmap       &> logs/bactmap.log
