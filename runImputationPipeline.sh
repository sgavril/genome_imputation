#!/bin/bash
#SBATCH --job-name=mask
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem-per-cpu=16g
#SBATCH --time=4:00:00
#SBATCH --output=preProcess_%j.log

source activate imputation.py36

RAW_INPUT="data/raw/Sable_October_2018"
FILTERED_OUTPUT="data/filtered/Sable_October_2018_filt"
ALPHAIMPUTE2_OUTPUT="data/filtered/Sable_October_2018_AlphaImpute2"
CHROM_FILE="chrom.sort.sizes.txt"

###############################################################################
# Quality control
###############################################################################
plink --file $RAW_INPUT --horse --geno 0.1 --make-bed --recode --out $FILTERED_OUTPUT

plink --file $FILTERED_OUTPUT --horse --mind 0.1 --make-bed --recode --out $FILTERED_OUTPUT

plink --file $FILTERED_OUTPUT --horse --maf 0.01 --make-bed --recode --out $FILTERED_OUTPUT

# For AlphaImpute2: get 0/1/2 encoding
# Note: plink --output-missing-genotype 9 does not seem to work
# So I change this using sed
plink --file $FILTERED_OUTPUT --recode A --horse \
    --out $ALPHAIMPUTE2_OUTPUT
# Then remove unnecessasry columns and header
cut -d" " -f2,7- $ALPHAIMPUTE2_OUTPUT".raw" | sed '1'd | sed 's/NA/9/g' \
    > $ALPHAIMPUTE2_OUTPUT".txt"

# Report frequencies for bpMAF SNP selection method
plink --file $FILTERED_OUTPUT --freq --out $FILTERED_OUTPUT --horse

# For lduMAF SNP selection, iterate over every chromosome
# Takes about 20 hrs
#for i in {1..32}
#do
#    echo $i
#    plink --file $FILTERED_OUTPUT --recode12 --transpose --horse \
#        --out $FILTERED_OUTPUT"_chr_"$i
#    LDMAP_github/ldmap $FILTERED_OUTPUT"_chr_"$i".tped" interemediate.txt \
#        LDMAP_github/job "chr_"$i".ldmap" "chr_"$i".log" 0.05 0.001
#done

###############################################################################
# Mask genotypes
###############################################################################
# This generates files listing SNPs to keep for each method
maskDownTo=(1000 2500 5000 10000 15000 20000)
for i in ${maskDownTo[@]}
do
    for j in bpRN bpEQ bpMAF lduMAF
    do
        # Output snps to mask to file
        Rscript maskSNP.R $FILTERED_OUTPUT".map" $i $CHROM_FILE $j
    done
done

mv snpsToMask_*tsv data/snpsToMaskDownTo

# Create plink cluster file
plink --file $FILTERED_OUTPUT --cluster --horse --out $FILTERED_OUTPUT

# Perform masking, should have 2664 files
# From 111 individuals * 4 SNP selection methods * 6 SNP densities
# Put all files in a leave-one-out directory
#rm -rf loo ; mkdir loo
# loo_directory="/scratch/${SLURM_JOB_ID}/loo/"
loo_directory = "loo/"
mkdir "$loo_directory"
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
	    
	    plink --file $FILTERED_OUTPUT \
                --horse --make-bed \
                --zero-cluster "snpsToMask_"$j"_"$k".tsv" \
                --within tmp.txt \
                --out "$loo_directory"$i"_"$j"_"$k
            
        # # Convert to 0/1/2 encoding
        # plink --bfile "$loo_directory"$i"_"$j"_"$k --recode A --horse \
        #     --out "$loo_directory"$i"_"$j"_"$k
	    
        # # Remove unnecessary columns and header, turn unknowns into 9
        # cut -d " " -f2,7- "$loo_directory"$i"_"$j"_"$k".raw" | sed '1d' | sed 's/NA/9/g' > "$loo_directory"$i"_"$j"_"$k".txt"
	 done
    done
done

# AlphaImpute2 -bfile SI_hair_128_10000_bpRN_ind100_rep1 -maxthreads 2 -pop_only -binaryoutput -out test_ai2
AlphaImpute2 -bfile SI_hair_128_10000_bpRN \
    -maxthreads 2 \
    -pop_only \
    -binaryoutput \
    -out test_ai_preloo