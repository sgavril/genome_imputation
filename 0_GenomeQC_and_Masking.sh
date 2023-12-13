#!/bin/bash
#SBATCH --job-name=mask
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem-per-cpu=16g
#SBATCH --time=4:00:00
#SBATCH --output=preProcess_%j.log

source venv3.6/bin/activate

###############################################################################
# This script does preprocessing for the imputation workflow. Specifically, it
#   1) Runs some basic QC using PLINK on the input genotypes
#   2) Runs an Rscript that masks SNPs on the filtered input genotypes
###############################################################################
INPUT_GENOTYPES_RAW=$(jq -r '.INPUT_GENOTYPES_RAW' config.json)
OUTPUT_GENOTYPES_FILTERED=$(jq -r '.OUTPUT_GENOTYPES_FILTERED' config.json)
FILE_CHROM_SIZES=$(jq -r '.FILE_CHROM_SIZES' config.json)
DIR_LOO=$(jq -r '.DIR_LOO' config.json)
DIR_SCRATCH=$(jq -r '.DIR_SCRATCH' config.json)

REPLICATES_DIR="${DIR_SCRATCH}replicates/"
OUTPUTS_DIR="${DIR_SCRATCH}outputs/"
###############################################################################
# Quality control
###############################################################################
./plink --file $INPUT_GENOTYPES_RAW --horse --list-duplicate-vars suppress-first
./plink --file $INPUT_GENOTYPES_RAW --exclude plink.dupvar --make-bed --horse --out $OUTPUT_GENOTYPES_FILTERED

./plink --bfile $OUTPUT_GENOTYPES_FILTERED --horse --geno 0.1 --make-bed --recode --out $OUTPUT_GENOTYPES_FILTERED

./plink --bfile $OUTPUT_GENOTYPES_FILTERED --horse --mind 0.1 --make-bed --recode --out $OUTPUT_GENOTYPES_FILTERED

./plink --bfile $OUTPUT_GENOTYPES_FILTERED --horse --maf 0.01 --make-bed --recode --out $OUTPUT_GENOTYPES_FILTERED

# Report frequencies for bpMAF SNP selection method
./plink --bfile $OUTPUT_GENOTYPES_FILTERED --freq --out $OUTPUT_GENOTYPES_FILTERED --horse

# Create plink cluster file
./plink --file $OUTPUT_GENOTYPES_FILTERED --cluster --horse --out $OUTPUT_GENOTYPES_FILTERED

deactivate
###############################################################################
# Mask genotypes
###############################################################################
# This generates files listing SNPs to keep for each method
source activate imputation.py36
maskDownTo=(1000 2500 5000 10000 15000 20000)
for i in ${maskDownTo[@]}
do
    for j in bpRN bpEQ bpMAF lduMAF
    do
        # Output snps to mask to file
        Rscript util_maskSNP.R $OUTPUT_GENOTYPES_FILTERED".map" $i $FILE_CHROM_SIZES $j
    done
done
source deactivate

mv snpsToMask_*tsv data/snpsToMaskDownTo

# Perform masking, should have 2664 files
# From 111 individuals * 4 SNP selection methods * 6 SNP densities
# Put all files in a leave-one-out directory
mkdir -p "${DIR_LOO}"
# Iterate over every sample
for i in $(awk '{print $2}' $OUTPUT_GENOTYPES_FILTERED".cluster2")
do
    echo "Currently processing sample: $i"
    # Change the cluster value to 1 for the sample to be masked
    sed "s/$i\t0/$i\t1/" $OUTPUT_GENOTYPES_FILTERED".cluster2" > tmp.txt

    # Mask to each desired level
    for j in ${maskDownTo[@]}
    do
        # Iterate over every SNP selection method
        for k in bpRN bpEQ bpMAF lduMAF
            do	
            echo $i ; echo $j ; echo $k
            ./plink --file $OUTPUT_GENOTYPES_FILTERED \
                    --horse --make-bed \
                    --zero-cluster "data/snpsToMaskDownTo/snpsToMask_"$j"_"$k".tsv" \
                    --within tmp.txt \
                    --out "${DIR_LOO}"$i"_"$j"_"$k
	    done
    done
done
