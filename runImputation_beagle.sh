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
rm /scratch/23176676/outputs_beagle/* ; rm /scratch/23176676/time_logs_beagle/*
mkdir -p /scratch/23176676/outputs_beagle/
mkdir -p /scratch/23176676/time_logs_beagle/

# Get a list of all .vcf.gz files
#find replicates/ -type f -name "*.vcf" > data/file_list_vcfs.txt
TOTAL_FILES=$(wc -l < data/file_list_vcfs.txt)
FILES_PER_JOB=$((TOTAL_FILES / 100))
START=$(( (SLURM_ARRAY_TASK_ID - 1) * FILES_PER_JOB + 1 ))
END=$(( START + FILES_PER_JOB - 1 ))

# Calculate start and end indices for this array job
TOTAL_FILES=${#FILES[@]}
FILES_PER_JOB=$((TOTAL_FILES / 100))
START=$(( (SLURM_ARRAY_TASK_ID - 1) * FILES_PER_JOB ))
END=$(( START + FILES_PER_JOB - 1 ))

# Extract the files for this array job
sed -n "$START,$END p" data/file_list_vcfs.txt > data/current_files_vcfs_$SLURM_ARRAY_TASK_ID.txt

echo "Starting GNU parallel to run Beagle..."

# Process the subset of files for this array job
parallel -j 50 --dry-run --joblog /scratch/23176676/time_logs_beagle/joblog_$SLURM_ARRAY_TASK_ID.log \
    'FILE={}; \
    BASENAME=$(basename $FILE .vcf); \
    echo "DEBUG: Processing $FILE with basename ${BASENAME}"; \
    OUTPUT_FILE="/scratch/23176676/outputs_beagle/${BASENAME}";  \
    TIME_LOG="/scratch/23176676/time_logs_beagle/${BASENAME}.time.log"; \
    (time java -jar beagle.22Jul22.46e.jar \
        gt=${FILE%.*} \
        ne=50 \
        out= $OUTPUTFILE) &> $TIME_LOG' :::: data/current_files_vcfs_$SLURM_ARRAY_TASK_ID.txt

rm data/current_files_vcf_$SLURM_ARRAY_TASK_ID.txt