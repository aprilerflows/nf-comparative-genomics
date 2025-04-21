#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//
// 1) Stage each input as a single‐value channel
//
Channel
    .value( file(params.bactmap_csv) )
    .set   { bactmapCsvCh }

Channel
    .value( file(params.bactmap_ref) )
    .set   { bactmapRefCh }

Channel
    .value( file(params.parsnp_ref) )
    .set   { parsnpRefCh }

Channel
    .value( file(params.parsnp_dir) )
    .set   { parsnpDirCh }


//
// 2) Workflow: conditionally run each step
//
workflow {
    if( params.all || params.bactmap ) {
        Bactmap(bactmapCsvCh, bactmapRefCh)
    }
    if( params.all || params.parsnp ) {
        Parsnp(parsnpRefCh, parsnpDirCh)
    }
}


//
// 3) nf‑core/bactmap wrapper
//
process Bactmap {
    tag "bactmap"
    container params.bactmap_docker_image

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
      -profile     docker \
      --trim --remove_recombination --iqtree \
      --max_memory ${params.bactmap_maxmem} \
      --outdir     results/bactmap \
      &> logs/bactmap.log
    """
}


//
// 4) Parsnp + HarvestTools + Gubbins
//
process Parsnp {
    tag "parsnp"
    container params.parsnp_docker_image

    input:
      path ref_fa
      path assemblies   // <-- now the *directory* itself

    publishDir "results/parsnp", mode: 'copy'
    publishDir "logs",           mode: 'copy', pattern: "parsnp.log,gubbins_on_parsnp.log"

    script:
    """
    mkdir -p logs

    # 1) multi‑genome alignment
    parsnp \
      -d \$PWD/${assemblies} \
      -r \$PWD/${ref_fa} \
      -o parsnp_out \
      -p ${task.cpus} \
      &> logs/parsnp.log

    # 2) convert for Gubbins
    harvesttools \
      -x parsnp_out/parsnp.xmfa \
      -M parsnp_out/parsnp.aln \
      &>> logs/parsnp.log

    # 3) recombination filtering
    run_gubbins.py \
      -p parsnp \
      parsnp_out/parsnp.aln \
      &> logs/gubbins_on_parsnp.log

    # 4) copy outputs
    mkdir -p results/parsnp
    cp -r parsnp_out/* results/parsnp/
    """
}
