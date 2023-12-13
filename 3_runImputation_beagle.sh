#!/bin/bash
#SBATCH --job-name=beagle_array
#SBATCH --output=logs/beagle_array_%A_%a.out
#SBATCH --error=logs/beagle_array_%A_%a.err
#SBATCH --nodes=1
#SBATCH --ntasks=50
#SBATCH --mem-per-cpu=600m  
#SBATCH --cpus-per-task=1
#SBATCH --time=72:00:00
#SBATCH --array=1-100

# Create the output and timing directories if they don't exist
# rm ${DIR_SCRATCH}outputs_beagle/* ; rm ${DIR_SCRATCH}time_logs_beagle/*
mkdir -p ${DIR_SCRATCH}outputs_beagle/
mkdir -p ${DIR_SCRATCH}time_logs_beagle/

# Get a list of all .vcf.gz files
#find replicates/ -type f -name "*.vcf" > data/file_list_vcfs.txt
TOTAL_FILES=$(wc -l < data/file_list_vcfs.txt)
FILES_PER_JOB=$(( (TOTAL_FILES + 99) / 100))
START=$(( (SLURM_ARRAY_TASK_ID - 1) * FILES_PER_JOB + 1 ))
END=$(( START + FILES_PER_JOB - 1 ))

# Extract the files for this array job
sed -n "$START,$END p" data/file_list_vcfs.txt > data/current_files_vcfs_$SLURM_ARRAY_TASK_ID.txt

echo "Starting GNU parallel to run Beagle..."

# Process the subset of files for this array job
parallel -j 4 --joblog ${DIR_SCRATCH}time_logs_beagle/joblog_$SLURM_ARRAY_TASK_ID.log \
    'FILE={}; \
    BASENAME=$(basename $FILE .vcf); \
    echo "DEBUG: Processing $FILE with basename ${BASENAME}"; \
    OUTPUT_FILE="${DIR_SCRATCH}outputs_beagle/${BASENAME}";  \
    TIME_LOG="${DIR_SCRATCH}time_logs_beagle/${BASENAME}.time.log"; \
    (time java -jar beagle.22Jul22.46e.jar \
        gt=$FILE \
        ne=50 \
        out=$OUTPUT_FILE) &> $TIME_LOG' :::: data/current_files_vcfs_$SLURM_ARRAY_TASK_ID.txt

rm data/current_files_vcf_$SLURM_ARRAY_TASK_ID.txt