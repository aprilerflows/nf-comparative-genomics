#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// 1) Stage each param as a single‐value channel
Channel.value( file(params.bactmap_csv) ).set { bactmapCsvCh }
Channel.value( file(params.bactmap_ref) ).set { bactmapRefCh }
Channel.value( file(params.parsnp_ref) ).set { parsnpRefCh }
Channel.value( file(params.parsnp_dir) ).set { parsnpDirCh }

// 2) Workflow logic
workflow {
  if( params.all || params.bactmap ) {
    Bactmap(bactmapCsvCh, bactmapRefCh)
  }
  if( params.all || params.parsnp ) {
    Parsnp(parsnpRefCh, parsnpDirCh)
  }
}

// 3) nf‑core/bactmap wrapper
process Bactmap {
  tag "bactmap"
  // activate nx & Java
  conda "${params.conda_envs}/bactmap_env.yml"

  input:
    path csv
    path ref_fa

  publishDir "results/bactmap", mode: 'copy'
  publishDir "logs",           mode: 'copy', pattern: "bactmap.log"

  script:
  """
  mkdir -p logs

  nextflow run nf-core/bactmap \
    --input      \$PWD/${csv} \
    --reference  \$PWD/${ref_fa} \
    -profile     conda \
    --trim --remove_recombination --iqtree \
    --max_memory ${params.bactmap_maxmem} \
    --outdir     results/bactmap \
    &> logs/bactmap.log
  """
}

// 4) Parsnp + HarvestTools + Gubbins
process Parsnp {
  tag "parsnp"
  // activate parsnp & gubbins
  conda "${params.conda_envs}/parsnp_env.yml"

  input:
    path ref_fa
    path assemblies

  publishDir "results/parsnp", mode: 'copy'
  publishDir "logs",           mode: 'copy', pattern: "parsnp.log,gubbins_on_parsnp.log"

  script:
  """
  mkdir -p logs

  parsnp \
    -d \$PWD/${assemblies} \
    -r \$PWD/${ref_fa} \
    -o parsnp_out \
    -p ${task.cpus} \
    &> logs/parsnp.log

  harvesttools \
    -x parsnp_out/parsnp.xmfa \
    -M parsnp_out/parsnp.aln \
    &>> logs/parsnp.log

  run_gubbins.py \
    -p parsnp \
    parsnp_out/parsnp.aln \
    &> logs/gubbins_on_parsnp.log

  mkdir -p results/parsnp
  cp -r parsnp_out/* results/parsnp/
  """
}
