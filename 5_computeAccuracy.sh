#!/bin/bash
#SBATCH --job-name=acc_ai2
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32g
#SBATCH --time=24:00:00
#SBATCH --output=logs/%x_accuracy_ai2_%j.log
#SBATCH --error=logs/%x_accuracy_ai2_%j.err

source activate imputation.py36

python util_convert2hdf5.py