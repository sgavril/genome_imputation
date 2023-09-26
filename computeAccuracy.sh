#!/bin/bash
#SBATCH --job-name=acc_ai2
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32g
#SBATCH --time=24:00:00
#SBATCH --output=accuracy_%j.log

source activate imputation.py36

python convert2hdf5.py