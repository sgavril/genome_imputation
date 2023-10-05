#!/bin/bash
#SBATCH --job-name=hdf5
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=50G
#SBATCH --time=24:00:00
#SBATCH --output=logs/to_hdf5_alphaimpute2_%j.out
#SBATCH --error=logs/to_hdf5_alphaimpute2_%j.err

source venv3.6/bin/activate

python convert2hdf5.py
