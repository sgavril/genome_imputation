#!/bin/bash
#SBATCH --job-name=vcf
#SBATCH --partition=single
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4g
#SBATCH --time=16:00:00
#SBATCH --output=%x-%j.log
#SBATCH --error=%x-%j.err

# ./plink --bfile /scratch/20708102/replicates3/SI_hair_128_10000_bpRN_ind100_rep1 \
#     --list-duplicate-vars ids-only --horse

# find /scratch/20708102/replicates2/ -type f | grep ".bim$" |
#     parallel \
#         './plink --bfile {.} --recode vcf --out {.} --horse && \
#         gzip {.}".vcf" '

# have to do this because the job finished early
find /scratch/20708102/replicates2/ -type f | grep ".bim$" |
    while read -r file; do
        vcf_file="${file%.bim}.vcf.gz"
        if [[ ! -f "$vcf_file" ]]; then
            echo "$file"
        fi
    done | parallel \
        './plink --bfile {.} --recode vcf --out {.} --horse && \
        gzip {.}".vcf" '

# find /scratch/20708102/replicates2/ -type f | grep ".vcf.gz$" |
#     parallel  'java -jar beagle.22Jul22.46e.jar gt={} out={basename {} .vcf.gz}'