#!/bin/bash
#SBATCH -p normal                      	# Partition to submit to
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 11Gb               	# Memory in MB
#SBATCH -J STAR               		# job name
#SBATCH -o logs/STAR.%A_%a.out    		# Sdt out file name: %j SLURM_JOB_ID; %A SLURM_ARRAY_JOB_ID, %a SLURM_ARRAY_TASK_ID
#SBATCH -e logs/STAR.%A_%a.err    		# Sdt err file name: %j SLURM_JOB_ID; %A SLURM_ARRAY_JOB_ID, %a SLURM_ARRAY_TASK_ID

#------------------------
# Prapare folders

WD=$1
THISFASTQFILE=$2
OUTDIR=$3
GNMIDX=$4

#--------------------
# Prapare input files

name=`basename -s .gz $THISFASTQFILE`
echo "$THISFASTQFILE is being analyzed."

######################################################################################################
#####################################ALIGNMENT########################################################

module purge
module load STAR/2.7.8a-GCC-10.2.0
echo "STAR module loaded."

STAR --runThreadN $SLURM_CPUS_PER_TASK --genomeDir $GNMIDX --readFilesIn $THISFASTQFILE --readFilesCommand zcat --outFileNamePrefix $OUTDIR/$name --outSAMattributes All --outSAMtype BAM SortedByCoordinate --outFilterMismatchNoverLmax 0.05 --outFilterMatchNmin 15 --outFilterScoreMinOverLread 0 --outFilterMatchNminOverLread 0 --alignIntronMax 1 --limitBAMsortRAM 1870962788

####################################################################################################
##################################### INDEX ######################################################

module purge
module load SAMtools/1.12-GCC-10.2.0
echo "SAMtools module loaded."

samtools index ${OUTDIR}/${name}Aligned.sortedByCoord.out.bam ${OUTDIR}/${name}Aligned.sortedByCoord.out.bai
echo "Bai file generated."
