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

mkdir -p outputs/

find replicates/ -type f | grep ".bim$" | \
	parallel -j 2 \
		'if [ ! -f outputs/{/} ]; then \
			AlphaImpute2 \
			-maxthreads 2 \
			-bfile {.} \
			-pop_only \
			-binaryoutput \
			-out outputs/{/.}; \
		else \
			echo "File outputs/{/} already exists, skipping"; \
		fi'
