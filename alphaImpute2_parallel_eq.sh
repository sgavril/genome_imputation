#!/bin/bash
#SBATCH --job-name=ai2_eq
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem-per-cpu=6g
#SBATCH --cpus-per-task=2
#SBATCH --time=72:00:00

source venv/bin/activate

find /scratch/20708102/replicates/*EQ* -type f | parallel \
	'AlphaImpute2 -maxthreads 2 -genotypes {} -pop_only -out /scratch/20708102/outputs/{/.}.txt'
