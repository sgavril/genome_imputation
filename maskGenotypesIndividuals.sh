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

# rm -rf replicates/
# mkdir -p replicates/
# for i in loo/*bim
# do
#     echo "Currently processing file: $i"
#     base=`basename $i .bim`
#     sample=$(basename -s ".bim" $i | sed 's/_[^_]*//3g')
#     echo $sample
#     for j in 10 25 50 75 100 110
#     do
#         for k in {1..5}
#         do
#             grep $sample samples.txt > "replicates/${base}_ind${j}_rep${k}.tmp"
#             grep -v $sample samples.txt > replicates/tmp.ref.txt
#             shuf -n $j replicates/tmp.ref.txt >> "replicates/${base}_ind${j}_rep${k}.tmp"
#             awk '{print "Sable", $1}' "replicates/${base}_ind${j}_rep${k}.tmp" > "replicates/${base}_ind${j}_rep${k}.txt"
#             #rm "replicates/${base}_ind${j}_rep${k}.tmp"
#             ./plink --bfile "loo/${base}" \
#                 --keep "replicates/${base}_ind${j}_rep${k}.txt" \
#                 --make-bed --horse \
#                 --out "replicates/${base}_ind${j}_rep${k}"
#         done
#     done
# done

# #rm replicates/*.log ; rm replicates/*.txt

mkdir -p replicates/
for i in loo/*bim
do
    echo "Currently processing file: $i"
    base=`basename $i .bim`
    sample=$(basename -s ".bim" $i | sed 's/_[^_]*//3g')
    echo $sample
    for j in 10 25 50 75 100 110
    do
        for k in {1..5}
        do
            grep $sample samples.txt > "replicates/${base}_ind${j}_rep${k}.tmp"
            grep -v $sample samples.txt > replicates/tmp.ref.txt
            shuf -n $j replicates/tmp.ref.txt >> "replicates/${base}_ind${j}_rep${k}.tmp"
            awk '{print "Sable", $1}' "replicates/${base}_ind${j}_rep${k}.tmp" > "replicates/${base}_ind${j}_rep${k}.txt"
            #rm "replicates/${base}_ind${j}_rep${k}.tmp"
            ./plink --bfile "loo/${base}" \
                --keep "replicates/${base}_ind${j}_rep${k}.txt" \
                --make-bed --horse \
                --out "replicates/${base}_ind${j}_rep${k}"
        done
    done
done

# Convert to vcf for beagle input
find replicates2/ -type f | grep ".bim$" |
    parallel './plink --bfile {.} --recode vcf --out {.} --horse'

find replicates/ -type f -name "*.log" -delete
find replicates/ -type f -name "*.tmp" -delete
find replicates/ -type f -name "*.txt" -delete