#!/bin/bash
#SBATCH --job-name=replicates
#SBATCH --partition=single
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4g
#SBATCH --time=4:00:00
#SBATCH --output=logs/%x-%j.log
#SBATCH --error=logs/%x-%j.err

REPLICATES_DIR=$(jq -r '.REPLICATES_DIR' config.json)
LOO_DIR=$(jq -r '.LOO_DIR' config.json)

# rm ${REPLICATES_DIR}/*.log ; rm ${REPLICATES_DIR}/*.txt

mkdir -p ${REPLICATES_DIR}/
for i in ${LOO_DIR}/*bim
do
    echo "Currently processing file: $i"
    base=`basename $i .bim`
    sample=$(basename -s ".bim" $i | sed 's/_[^_]*//3g')
    echo $sample
    for j in 10 25 50 75 100 110
    do
        for k in {1..5}
        do
            grep $sample data/samples.txt > "${REPLICATES_DIR}/${base}_ind${j}_rep${k}.tmp"
            grep -v $sample data/samples.txt > ${REPLICATES_DIR}/tmp.ref.txt
            shuf -n $j ${REPLICATES_DIR}/tmp.ref.txt >> "${REPLICATES_DIR}/${base}_ind${j}_rep${k}.tmp"
            awk '{print "Sable", $1}' "${REPLICATES_DIR}/${base}_ind${j}_rep${k}.tmp" > "${REPLICATES_DIR}/${base}_ind${j}_rep${k}.txt"
            #rm "${REPLICATES_DIR}/${base}_ind${j}_rep${k}.tmp"
            ./plink --bfile "${LOO_DIR}/${base}" \
                --keep "${REPLICATES_DIR}/${base}_ind${j}_rep${k}.txt" \
                --make-bed --horse \
                --out "${REPLICATES_DIR}/${base}_ind${j}_rep${k}"
        done
    done
done

# Convert to vcf for beagle input
find ${REPLICATES_DIR}/ -type f -name "*.bim" | \ 
    parallel -j 4 './plink --bfile {.} --recode vcf --out {.} --horse'

find ${REPLICATES_DIR}/ -type f -name "*.log" -delete
find ${REPLICATES_DIR}/ -type f -name "*.tmp" -delete
find ${REPLICATES_DIR}/ -type f -name "*.txt" -delete