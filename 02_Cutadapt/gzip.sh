#!/bin/bash
#SBATCH -p normal,long            	# Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 45Gb     	# Memory in MB
#SBATCH -J gzip           	# job name
#SBATCH -o logs/gzip.%A_%a.out	# Sdt out file name: %j SLURM_JOB_ID; %A SLURM_ARRAY_JOB_ID, %a SLURM_ARRAY_TASK_ID
#SBATCH -e logs/gzip.%A_%a.err	# Std err file name

OUTDIR=$1

gzip ls $OUTDIR/*.fastq
