#!/bin/bash
#SBATCH --job-name=ai2
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem-per-cpu=1g
#SBATCH --cpus-per-task=4
#SBATCH --time=72:00:00

source venv/bin/activate

mkdir -p /scratch/20708102/outputs2

find /scratch/20708102/replicates2/ -type f | grep ".bim$" | \
	parallel \
		'AlphaImpute2 \
			-maxthreads 4 \
			-bfile {.} \
			-pop_only \
			-binaryoutput \
			-out /scratch/20708102/outputs2/{/.}'