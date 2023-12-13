#!/bin/bash
#SBATCH --job-name=ai2_array
#SBATCH --output=logs/ai2_array_%j.out
#SBATCH --error=logs/ai2_array_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=50
#SBATCH --mem-per-cpu=600m
#SBATCH --cpus-per-task=1
#SBATCH --time=72:00:00
#SBATCH --array=1-100

REPLICATES_DIR=$(jq -r '.REPLICATES_DIR' config.json)

source venv3.6/bin/activate

rm ${DIR_SCRATCH}outputs/* ; rm ${DIR_SCRATCH}time_logs/*
mkdir -p ${DIR_SCRATCH}outputs/
mkdir -p ${DIR_SCRATCH}time_logs/

# Calculate the number of files to process in this array job
#find replicates/ -type f -name "*.bim" > data/file_list.txt
TOTAL_FILES=$(wc -l < data/file_list.txt)
FILES_PER_JOB=$(( (TOTAL_FILES + 99) / 100))
START=$(( (SLURM_ARRAY_TASK_ID - 1) * FILES_PER_JOB + 1 ))
END=$(( START + FILES_PER_JOB - 1 ))

# Extract the files for this array job
sed -n "$START,$END p" data/file_list.txt > data/current_files_$SLURM_ARRAY_TASK_ID.txt

echo "Starting GNU parallel to run AlphaImpute2..."

# Use GNU parallel to run multiple iterations simultaneously
parallel -j 50 --joblog ${DIR_SCRATCH}time_logs/joblog_$SLURM_ARRAY_TASK_ID.log \
    'FILE={}; \
     BASENAME=$(basename $FILE .bim); \
     echo "DEBUG: Processing file $FILE with basename ${BASENAME}"; \
     OUTPUT_FILE="${DIR_SCRATCH}outputs/${BASENAME}"; \
     TIME_LOG="${DIR_SCRATCH}time_logs/${BASENAME}.time.log"; \
     (time AlphaImpute2 \
         -maxthreads 1 \
         -bfile ${FILE%.*} \
         -pop_only \
         -binaryoutput \
         -out $OUTPUT_FILE) &> $TIME_LOG' :::: data/current_files_$SLURM_ARRAY_TASK_ID.txt

# Cleanup
rm data/current_files_$SLURM_ARRAY_TASK_ID.txt
