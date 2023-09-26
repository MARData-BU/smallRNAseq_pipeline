#!/bin/bash
#SBATCH -p long            	# Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 45Gb     	# Memory in MB
#SBATCH -J gzip           	# job name
#SBATCH -o logs/gzip.%A_%a.out	# Sdt out file name: %j SLURM_JOB_ID; %A SLURM_ARRAY_JOB_ID, %a SLURM_ARRAY_TASK_ID
#SBATCH -e logs/gzip.%A_%a.err	# Std err file name

folder=$1
WD=$2
echo -e "Batch has been defined as $folder.\n"
echo -e "Analysis directory has been defined as $WD.\n"

OUTDIR=$WD/01_ExtractUMI/Fastq_Files/${folder}
echo -e "Output directory will be $OUTDIR.\n"

echo "Compressing files..."
gzip $OUTDIR/*.fastq
echo "Fastq files compressed to fastq.gz files."
