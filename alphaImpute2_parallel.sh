#!/bin/bash
#SBATCH --job-name=ai2
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=4000m
#SBATCH --cpus-per-task=48
#SBATCH --time=72:00:00

source venv3.6/bin/activate

mkdir -p /scratch/20708102/outputs

find /scratch/20708102/replicates/ -type f | grep ".bim$" | \
	parallel -j 48 \
		'if [ ! -f /scratch/20708102/outputs2/{/} ]; then \
			AlphaImpute2 \
			-maxthreads 2 \
			-bfile {.} \
			-pop_only \
			-binaryoutput \
			-out /scratch/20708102/outputs2/{/.}; \
		else \
			echo "File /scratch/20708102/outputs2/{/.} already exists, skipping"; \
		fi'
