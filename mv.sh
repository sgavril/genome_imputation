#!/bin/bash
#SBATCH --job-name=mv
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --time=24:00:00
#SBATCH --output=logs/mv_%j.out
#SBATCH --error=logs/mv_%j.err

source venv3.6/bin/activate

rm -r outputs/
rsync -avz /scratch/23176676/outputs .

#python convert2hdf5.py --chunk_file "data/hdf5_chunks/hdf5_chunk_$(printf "%03d" ${SLURM_ARRAY_TASK_ID}).txt"
