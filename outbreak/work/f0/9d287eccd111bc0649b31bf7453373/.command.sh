#!/bin/bash -ue
mkdir -p logs results/parsnp

    parsnp       -d /workspaces/nf-comparative-genomics/outbreak/dummy/parsnp/assemblies       -r /workspaces/nf-comparative-genomics/outbreak/dummy/parsnp/ref.fa       -o parsnp_out       -p 1       &> logs/parsnp.log

    harvesttools       -x parsnp_out/parsnp.xmfa       -M parsnp_out/parsnp.aln       &>> logs/parsnp.log

   set +e
    run_gubbins.py       -p parsnp parsnp_out/parsnp.aln       &> logs/gubbins_on_parsnp.log
set -e
    cp -r parsnp_out/* results/parsnp/
