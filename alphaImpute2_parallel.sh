#!/bin/bash
#SBATCH --job-name=ai2
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=500m
#SBATCH --cpus-per-task=64
#SBATCH --time=72:00:00

source venv3.6/bin/activate

#mkdir -p /scratch/20708102/outputs2

find /scratch/20708102/replicates2/ -type f | grep ".bim$" | \
	parallel -j 64 \
		'AlphaImpute2 \
			-maxthreads 2 \
			-bfile {.} \
			-pop_only \
			-binaryoutput \
			-out /scratch/20708102/outputs2/{/.}'