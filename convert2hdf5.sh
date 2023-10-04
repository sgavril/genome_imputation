#!/bin/bash
#SBATCH --job-name=plink_to_hdf5
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=50G
#SBATCH --time=24:00:00
#SBATCH --output=logs/%x_alphaimpute2_%j.out
#SBATCH --error=logs/%x_to_hdf5_alphaimpute2_%j.err

source env/bin/activate

python convert2hdf5.py