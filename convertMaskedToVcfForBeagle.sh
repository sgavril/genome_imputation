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

# ./plink \
#     --bfile /home/stefan.gavriliuc/projects/imputation/02_AlphaImpute2/Sable_October_2018_filt \
#     --exclude plink.dupvar \
#     --make-bed \
#     --out Sable_October_2018_filt_dedup \
#     --horse

mkdir -p loo_beagle/
for i in ../loo/*.bed
do
    #echo $i
    name=$(basename -s ".bed" $i)
    echo $name
    plink --bfile ../loo/
done

# ./plink --bfile /scratch/20708102/replicates3/SI_hair_128_10000_bpRN_ind100_rep1 \
#     --list-duplicate-vars ids-only --horse

# find /scratch/20708102/replicates2/ -type f | grep ".bim$" |
#     parallel \
#         './plink --bfile {.} --recode vcf --out {.} --horse && \
#         gzip {.}".vcf" '

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

find /scratch/20708102/replicates3/ -type f | grep ".vcf.gz$" |
    parallel -j 48 \
        'java -jar beagle.22Jul22.46e.jar \
            gt={} \
            out=/scratch/20708102/outputs_beagle/{/.}'