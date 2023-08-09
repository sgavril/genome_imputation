#!/bin/bash
#SBATCH --job-name=replicates
#SBATCH --partition=single
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4g
#SBATCH --time=16:00:00
#SBATCH --output=%x-%j.log
#SBATCH --error=%x-%j.err

mkdir -p /scratch/20708102/replicates/
for i in ../loo/*bim
do
    echo "Currently processing file: $i"
    base=`basename $i .bim`
    sample=$(basename -s ".bim" $i | sed 's/_[^_]*//3g')
    echo $sample
    for j in 10 25 50 75 100 110
    do
        for k in {1..5}
        do
            grep $sample samples.txt > "/scratch/20708102/replicates/${base}_ind${j}_rep${k}.tmp"
            grep -v $sample samples.txt > /scratch/20708102/replicates/tmp.ref.txt
            shuf -n $j /scratch/20708102/replicates/tmp.ref.txt >> "/scratch/20708102/replicates/${base}_ind${j}_rep${k}.tmp"
            awk '{print "Sable", $1}' "/scratch/20708102/replicates/${base}_ind${j}_rep${k}.tmp" > "/scratch/20708102/replicates/${base}_ind${j}_rep${k}.txt"
            #rm "/scratch/20708102/replicates/${base}_ind${j}_rep${k}.tmp"
            ./plink --bfile "../loo/${base}" \
                --keep "/scratch/20708102/replicates/${base}_ind${j}_rep${k}.txt" \
                --make-bed --horse \
                --out "/scratch/20708102/replicates/${base}_ind${j}_rep${k}"
        done
    done
done

#rm /scratch/20708102/replicates/*.log ; rm /scratch/20708102/replicates/*.txt
find /scratch/20708102/replicates/ -type f -name "*.log" -delete
find /scratch/20708102/replicates/ -type f -name "*.tmp" -delete
find /scratch/20708102/replicates/ -type f -name "*.txt" -delete