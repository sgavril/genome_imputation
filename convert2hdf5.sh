#!/bin/bash
#SBATCH --job-name=hdf5
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=12G
#SBATCH --time=24:00:00
#SBATCH --output=logs/to_hdf5_alphaimpute2_%j.out
#SBATCH --error=logs/to_hdf5_alphaimpute2_%j.err
#SBATCH --array=1-100

source venv3.6/bin/activate

python convert2hdf5.py --chunk_file "data/hdf5_chunks/hdf5_chunk_$(printf "%03d" ${SLURM_ARRAY_TASK_ID}).txt"
