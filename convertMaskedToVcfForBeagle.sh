#!/bin/bash
#SBATCH --job-name=beagle
#SBATCH --output=beagle_%x-%j.out
#SBATCH --error=beagle_%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=4000m
#SBATCH --cpus-per-task=48
#SBATCH --time=72:00:00

source venv3.6/bin/activate
mkdir -p /scratch/20708102/outputs_beagle

find /scratch/20708102/replicates/ -type f | grep ".bim$" |
    parallel \
        './plink --bfile {.} --recode vcf --out {.} --horse && \
        gzip {.}".vcf" '

# Just testing one
./plink --bfile /scratch/20708102/replicates/SI_hair_128_10000_bpEQ_ind100_rep1 \
    --recode vcf \
    --out /scratch/20708102/replicates/SI_hair_128_10000_bpEQ_ind100_rep1 \
    --horse && \
    gzip /scratch/20708102/replicates/SI_hair_128_10000_bpEQ_ind100_rep1.vcf

# have to do this because the job finished early
# find /scratch/20708102/replicates2/ -type f | grep ".bim$" |
#     while read -r file; do
#         vcf_file="${file%.bim}.vcf.gz"
#         if [[ ! -f "$vcf_file" ]]; then
#             echo "$file"
#         fi
#     done | parallel \
#         './plink --bfile {.} --recode vcf --out {.} --horse && \
#         gzip {.}".vcf" '

# Just testing one iteration
java -jar beagle.22Jul22.46e.jar ne=50 \
    gt=/scratch/20708102/replicates/SI_hair_128_10000_bpEQ_ind100_rep1.vcf.gz \
    out=/scratch/20708102/replicates/SI_hair_128_10000_bpEQ_ind100_rep1.vcf

find /scratch/20708102/replicates/ -type f | grep ".vcf.gz$" |
    parallel --dry-run -j 48 \
        'java -jar beagle.22Jul22.46e.jar \
            gt={} ne=50 \
            out=/scratch/20708102/outputs_beagle/{/.}'
