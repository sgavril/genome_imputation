#!/bin/bash
#SBATCH --job-name=beagle
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16gb
#SBATCH --time=168:00:00
#SBATCH --output=beagle_%j.log

source activate imputation

# Create plink dupvar file
plink --bfile /scratch/16639650/loo/$name --list-duplicate-vars ids-only --horse

# Format the reference genotypes into a table from GATKs' VariantsToTable function
# First remove dupes and also recode to 0/1/2 encoding 
plink --bfile ../02_AlphaImpute2/Sable_October_2018_filt --recode A --exclude plink.dupvar --make-bed --out Sable_October_2018_filt_dedup --horse
# Recode to vcf not necessary, just convert to raw
plink --bfile Sable_October_2018_filt_dedup --recode A --out Sable_October_2018_filt --horse
#gatk VariantsToTable -V Sable_October_2018_filt.vcf -F ID -GF GT -O Sable_October_2018_filt.tab

# Convert masked to vcf 
for i in /scratch/16639650/loo/*.bed
do
	echo $i
	name=$(basename -s ".bed" $i)
	echo $name
	plink --bfile /scratch/16639650/loo/$name --list-duplicate-vars ids-only --horse
	# Remove duplicate SNPs for each iteration + convert to 0/1/2 encoding
	plink --bfile /scratch/16639650/loo/$name --recode A --exclude plink.dupvar --out /scratch/16639650/loo_beagle/$name"_dedup" --horse --make-bed
	plink --bfile /scratch/16639650/loo_beagle/$name"_dedup" --recode vcf --out /scratch/16639650/loo_beagle/$name"_dedup" --horse
done

#ls /scratch/16639650/loo/*.bed | parallel 'plink --bfile {.} --list-duplicate-vars ids-only --horse --out {.}'
#	plink --bfile {.} --recode A --exclude {.}".dupvar" --out "/scratch/16639650/loo_beagle/"{/.}"_dedup" --horse --make-bed ;
#	plink --bfile "/scratch/16639650/loo_beagle/"{/.}_dedup" --recode vcf --out "/scratch/16639650/loo_beagle"{/.}"_dedup" --horse' 

ls /scratch/16639650/loo/*.bed | parallel 'plink --bfile {.} --recode A --exclude {.}".dupvar" --out {.}"_dedup" --horse --make-bed'
ls /scratch/16639650/loo_beagle/*dedup.bed | parallel 'plink --bfile {.} --recode vcf --out {.} --horse --make-bed'
#ls /scratch/16639650/outputs_beagle/SI_hair_128_1000_bpEQ*.vcf | parallel \
#    'plink --vcf {} --recode A --double-id --horse --memory 8000 \
#    --out {.} '


# With the option to exclude individuals, there is no need to create
# 	input files for each iteration.
# Also note to self: the output directory should already exist, otherwise
# 	Beagle will fail.

masked=(/scratch/16639650/loo_beagle/*dedup.vcf)
echo ${masked[0]} ; echo ${#masked[@]}

basenames=()
for file in ${masked[@]}
do
    filename=${file##*/} 
    basenames+=( ${filename%_dedup*} )
done

rm -rf /scratch/16639650/beagle_tmp/*

for j in 10 25 50 75 100 110
do
    for k in {1..5}
    do
      # Get sample name for grepping
	    #sample=$(basename -s "_dedup.vcf" ${masked[SLURM_ARRAY_TASK_ID]} | sed 's/_[^_]*//3g')
      #grep -v $sample samples.txt > /scratch/16639650/beagle_tmp/${basenames[$SLURM_ARRAY_TASK_ID]}".tmp"
      #  num_ind_to_exclude=$((111-$j))
	    #shuf -n $num_ind_to_exclude /scratch/16639650/beagle_tmp/${basenames[$SLURM_ARRAY_TASK_ID]}".tmp" >> \
		  #  /scratch/16639650/beagle_tmp/${basenames[$SLURM_ARRAY_TASK_ID]}"_ind"$j"_rep"$k"_remove.txt"
      
      #java -jar beagle.22Jul22.46e.jar ne=50 seed=$k nthreads=2 \
		  #  gt=${masked[$SLURM_ARRAY_TASK_ID]} \
		  #  out=/scratch/16639650/outputs_beagle/${basenames[$SLURM_ARRAY_TASK_ID]}"_ind"$j"_rep"$k
	
	     # Uncompress for downstream analysis
	     #gunzip /scratch/16639650/outputs_beagle/${basenames[$SLURM_ARRAY_TASK_ID]}"_ind"$j"_rep"$k".vcf.gz"
        
      # Use plink to get 0/1/2 encoding
      plink --vcf /scratch/16639650/outputs_beagle/${basenames[$SLURM_ARRAY_TASK_ID]}"_ind"$j"_rep"$k".vcf" --recode A --double-id --horse --out /scratch/16639650/outputs_beagle/${basenames[$SLURM_ARRAY_TASK_ID]}"_ind"$j"_rep"$k

        # Use GATK to create a genotype table (sample x marker)
	#gatk VariantsToTable -V /scratch/16639650/outputs_beagle/${basenames[$SLURM_ARRAY_TASK_ID]}"_ind"$j"_rep"$k".raw" -F ID -GF GT -O /scratch/16639650/outputs_beagle/${basenames[$SLURM_ARRAY_TASK_ID]}"_ind"$j"_rep"$k".tab"

        # Imputed tables are phased and have the pipe symbol | ; change to match reference table using sed
	#sed -i 's;|;/;g' /scratch/16639650/outputs_beagle/${basenames[$SLURM_ARRAY_TASK_ID]}"_ind"$j"_rep"$k".tab"
    done
done

ls /scratch/16639650/outputs_beagle/SI_hair_128_1000_bpEQ*.vcf | parallel \
    'plink --vcf {} --recode A --double-id --horse --memory 8000 \
    --out {.} '
    

for i in /scratch/16639650/loo_beagle/*_dedup.vcf
do
    for j in 10 25 50 75 100 110
    do
        for k in {1..5}
        do
            echo $i
	    #basename here
	    base=`basename $i .vcf`
	    grep -v $i samples.txt > tmp.txt
	    num_ind_to_exclude=$((111-$j))
	    shuf -n $num_ind_to_exclude tmp.txt > remove.txt
	    #cat remove.txt
	    java -jar beagle.22Jul22.46e.jar gt=$i out=/scratch/16639650/outputs_beagle/$base"_ind"$j"_rep"$k

            # Uncompress for downstream analysis
	   gunzip /scratch/16639650/outputs_beagle/$base"_ind"$j"_rep"$k".vcf.gz"

	   # Use GATK to create a genotype table (sample x marker)
	   gatk VariantsToTable -V /scratch/16639650/outputs_beagle/$base"_ind"$j"_rep"$k".vcf" -F ID -GF GT -O /scratch/16639650/outputs_beagle/$base"_ind"$j"_rep"$k".tab"

	   # Imputed tables are phased and have the pipe symbol | ; change to match reference table using sed
	   sed -i 's;|;/;g' /scratch/16639650/outputs_beagle/$base"_ind"$j"_rep"$k".tab"
	done
    done
done

# Compute accuracies
# Output accuracy
for i in /scratch/16639650/outputs_beagle/*.tab
do
    sample=$(echo $i | sed 's/_[^_]*//4g' | sed 's;tmp/;;')
    echo $i
    echo $sample
    Rscript computeConcordance.R ref.tab $i $sample
done

