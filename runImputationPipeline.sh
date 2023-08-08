#!/bin/bash
#SBATCH --job-name=mask
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem-per-cpu=16g
#SBATCH --time=4:00:00
#SBATCH --output=preProcess_%j.log

source venv3.6/bin/activate

RAW_INPUT="data/raw/Sable_October_2018"
FILTERED_OUTPUT="data/filtered/Sable_October_2018_filt"
ALPHAIMPUTE2_OUTPUT="data/filtered/Sable_October_2018_AlphaImpute2"
CHROM_FILE="chrom.sort.sizes.txt"
loo_directory="loo/"

###############################################################################
# Quality control
###############################################################################
./plink --file $RAW_INPUT --horse --list-duplicate-vars ids-only --out $FILTERED_OUTPUT
./plink --bfile $FILTERED_OUTPUT --exclude plink.dupvar --out $FILTERED_OUTPUT

./plink --file $FILTERED_OUTPUT --horse --geno 0.1 --make-bed --recode --out $FILTERED_OUTPUT

./plink --file $FILTERED_OUTPUT --horse --mind 0.1 --make-bed --recode --out $FILTERED_OUTPUT

./plink --file $FILTERED_OUTPUT --horse --maf 0.01 --make-bed --recode --out $FILTERED_OUTPUT

# Report frequencies for bpMAF SNP selection method
plink --file $FILTERED_OUTPUT --freq --out Sable_October_2018_filt --horse


###############################################################################
# Mask genotypes
###############################################################################
# This generates files listing SNPs to keep for each method
deactivate
conda activate imputation.py36
maskDownTo=(1000 2500 5000 10000 15000 20000)
for i in ${maskDownTo[@]}
do
    for j in bpRN bpEQ bpMAF lduMAF
    do
        # Output snps to mask to file
        Rscript maskSNP.R $FILTERED_OUTPUT".map" $i $CHROM_FILE $j
    done
done
conda deactivate

mv snpsToMask_*tsv data/snpsToMaskDownTo

# Create plink cluster file
plink --file $FILTERED_OUTPUT --cluster --horse --out $FILTERED_OUTPUT

# Perform masking, should have 2664 files
# From 111 individuals * 4 SNP selection methods * 6 SNP densities
# Put all files in a leave-one-out directory
mkdir -p "$loo_directory"
# Iterate over every sample
for i in $(awk '{print $2}' $FILTERED_OUTPUT".cluster2")
do
    echo "Currently processing sample: $i"
    # Change the cluster value to 1 for the sample to be masked
    sed "s/$i\t0/$i\t1/" $FILTERED_OUTPUT".cluster2" > tmp.txt

    # Mask to each desired level
    for j in ${maskDownTo[@]}
    do
        # Iterate over every SNP selection method
        for k in bpRN bpEQ bpMAF lduMAF
            do	
            echo $i ; echo $j ; echo $k
            ./plink --file $FILTERED_OUTPUT \
                    --horse --make-bed \
                    --zero-cluster "snpsToMask_"$j"_"$k".tsv" \
                    --within tmp.txt \
                    --out "$loo_directory"$i"_"$j"_"$k
	    done
    done
done