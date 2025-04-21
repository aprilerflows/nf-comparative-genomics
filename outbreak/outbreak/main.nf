#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
 * 1) Parameter sanity checks
 */
if( !params.all && !params.bactmap && !params.parsnp ) {
    log.error "Please specify at least one of: --bactmap, --parsnp, or --all"
    System.exit(1)
}

if( (params.bactmap || params.all) && 
    ( !params.bactmap_csv || !params.bactmap_ref ) ) {
    log.error "--bactmap (or --all) requires both --bactmap_csv and --bactmap_ref"
    System.exit(1)
}

if( (params.parsnp  || params.all) && 
    ( !params.parsnp_ref || !params.parsnp_dir ) ) {
    log.error "--parsnp (or --all) requires both --parsnp_ref and --parsnp_dir"
    System.exit(1)
}

/*
 * 2) Create Channels from your input paths
 */
Channel
    .fromPath( params.bactmap_csv, checkIfExists: true )
    .set { bactmapCsvCh }

Channel
    .fromPath( params.bactmap_ref, checkIfExists: true )
    .set { bactmapRefCh }

Channel
    .fromPath( params.parsnp_ref, checkIfExists: true )
    .set { parsnpRefCh }

Channel
    .fromPath( params.parsnp_dir, checkIfExists: true )
    .set { parsnpDirCh }


/*
 * 3) Workflow: conditionally invoke each step
 */
workflow {
    if( params.all || params.bactmap ) {
        Bactmap(bactmapCsvCh, bactmapRefCh)
    }
    if( params.all || params.parsnp ) {
        Parsnp(parsnpRefCh, parsnpDirCh)
    }
}


/*
 * 4) Processes
 */
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
      -profile     ${params.bactmap_profile} \
      --trim --remove_recombination --iqtree \
      --max_memory ${params.bactmap_maxmem} \
      --outdir     results/bactmap \
      &> logs/bactmap.log
    """
}


process Parsnp {
    tag "parsnp"
    container params.parsnp_docker_image

    input:
      path ref_fa
      path assemblies

    publishDir "results/parsnp", mode: 'copy'
    publishDir "logs",           mode: 'copy', pattern: "parsnp.log,gubbins_on_parsnp.log"

    script:
    """
    mkdir -p logs

    # 1) multi-genome alignment
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

    # 4) stage results
    mkdir -p results/parsnp
    cp -r parsnp_out/* results/parsnp/
    """
}

