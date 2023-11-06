process JABBA {
    tag "$meta.id"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskilab/jabba_cplex:latest':
        'mskilab/jabba_cplex:latest' }"

    input:
    tuple val(meta), path(cov_rds)
    tuple val(meta), path(junction)
    tuple val(meta), val(ploidy)
    tuple val(meta), path(het_pileups_wgs)
    tuple val(meta), path(cbs_seg_rds, stageAs: "cbs_seg.rds")
    tuple val(meta), path(cbs_nseg_rds, stageAs: "cbs_nseg.rds")
    tuple val(meta), path(j_supp)
    path(blacklist_junctions)
    val(geno)
    val(indel)
    val(tfield)
    val(iter)
    val(rescue_window)
    val(rescue_all)
    val(nudgebalanced)
    val(edgenudge)
    val(strict)
    val(allin)
    val(field)
    val(maxna)
    path(blacklist_coverage)
    val(purity)
    val(pp_method)
    val(cnsignif)
    val(slack)
    val(linear)
    val(tilim)
    val(epgap)
    val(name)
    val(fix_thres)
    val(lp)
    val(ism)
    val(filter_loose)
    val(gurobi)
    val(nonintegral)
    val(verbose)
    val(help)

    output:
    tuple val(meta), path("*.jabba.simple.rds")      , emit: jabba_rds, optional: true
    tuple val(meta), path("*.jabba.simple.gg.rds")   , emit: jabba_gg, optional: true
    tuple val(meta), path("*.jabba.simple.vcf")      , emit: jabba_vcf, optional: true
    tuple val(meta), path("*.jabba.raw.rds")         , emit: jabba_raw_rds, optional: true
    tuple val(meta), path("*.opt.report.rds")        , emit: opti, optional: true
    tuple val(meta), path("*.jabba.seg")             , emit: jabba_seg, optional: true
    tuple val(meta), path("*.karyograph.rds")        , emit: karyograph, optional: true
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def VERSION    = '1.1'
    """
    #!/bin/bash

    set -o allexport

    # Check if the environment has the module program installed
    if command -v module &> /dev/null
    then
        # Check if the required modules are available
        if module avail R/4.0.2 &> /dev/null && module avail gcc/9.2.0 &> /dev/null
        then
            ## load correct R and gcc versions
            module unload R
            module load R/4.0.2
            module unload gcc
            module load gcc/9.2.0
        fi
    fi

    set -x
    R_LIB_PATH="/gpfs/commons/groups/imielinski_lab/lib/R-4.0.2"
    if [ -d "\$R_LIB_PATH" ]; then
        export R_LIBS=\$R_LIB_PATH
    fi

    export R_DATATABLE_NUM_THREADS=1
    #unset R_HOME
    #R_PROFILE_USER="/dev/null"

    ## find R installation
    echo "USING LIBRARIES: \$(Rscript -e 'print(.libPaths())')"

    export jabPath=\$(Rscript -e 'cat(suppressWarnings(find.package("JaBbA")))')
    export jba=\${jabPath}/extdata/jba
    echo \$jba
    set +x

    export cmd="Rscript \$jba $cov_rds $junction \\
    --j.supp                $j_supp \\
    --blacklist.junctions	$blacklist_junctions \\
    --geno					$geno \\
    --indel					$indel \\
    --tfield				$tfield \\
    --iterate				$iter \\
    --rescue.window			$rescue_window \\
    --rescue.all			$rescue_all \\
    --nudgebalanced			$nudgebalanced \\
    --edgenudge				$edgenudge \\
    --strict				$strict \\
    --allin					$allin \\
    --field					$field \\
    --seg			        $cbs_seg_rds \\
    --maxna					$maxna \\
    --blacklist.coverage	$blacklist_coverage \\
    --nseg			        $cbs_nseg_rds \\
    --hets		            $het_pileups_wgs \\
    --ploidy				$ploidy \\
    --purity				$purity \\
    --ppmethod				$pp_method \\
    --cnsignif				$cnsignif \\
    --slack					$slack \\
    --linear				$linear \\
    --tilim					$tilim \\
    --epgap					$epgap \\
    --name                  $name \\
    --cores                 $task.cpus \\
    --mem                   $task.memory \\
    --fix.thres				$fix_thres \\
    --lp					$lp \\
    --ism					$ism \\
    --filter_loose			$filter_loose \\
    --gurobi				$gurobi \\
    --nonintegral			$nonintegral \\
    --verbose				$verbose \\
    --help					$help \\
    "

    { echo "Running:" && echo "\$(echo \$cmd)" && echo && eval \$cmd; }
    cmdsig=\$?
    if [ "\$cmdsig" = 0 ]; then
        echo "Finish!"
    else
        echo "Broke!"
        exit \$cmdsig
    fi

    exit 0

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        JaBbA: ${VERSION}
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.1' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """
    touch jabba.simple.rds
    touch jabba.simple.gg.rds
    touch jabba.simple.vcf
    touch jabba.raw.rds
    touch opt.report.rds
    touch jabba.seg
    touch karyograph.rds

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        JaBbA: ${VERSION}
    END_VERSIONS
    """
}
