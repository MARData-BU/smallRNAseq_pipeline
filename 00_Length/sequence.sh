#!/bin/bash
#SBATCH -p normal,long            	# Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 45Gb     	# Memory in MB
#SBATCH -J LlargadaUMI           	# job name
#SBATCH -o logs/Llargada.%A_%a.out	# Sdt out file name: %j SLURM_JOB_ID; %A SLURM_ARRAY_JOB_ID, %a SLURM_ARRAY_TASK_ID
#SBATCH -e logs/Llargada.%A_%a.err	# Std err file name

WD=$1
FASTQDIR=$2
folder=$3
ADAPTER=$4
FASTQ_SUFFIX=$5

echo -e "The working directory has been defined as $WD."
echo -e "The fastq directory has been defined as $FASTQDIR."
echo -e "The batch that is now being processed is $folder."
echo -e "The adapter has been defined as $ADAPTER."
echo -e "The fastq suffix has been defined as $FASTQ_SUFFIX."


mkdir -p $WD/00_Length/Fastq_Files/
mkdir -p $WD/00_Length/Fastq_Files/Results
mkdir -p $WD/00_Length/Fastq_Files/Results/${folder}

for i in $(ls $FASTQDIR/${folder}/*$FASTQ_SUFFIX | xargs -I {} basename {} | rev | cut -d "/" -f 1 | rev) # extract the basenames (file names) without the path of each file
  do
    echo $i
    zcat "$FASTQDIR/${folder}/$i" | awk '(NR%4==2)' | grep -o -P ".*$ADAPTER.{0,12}" >> "$WD/00_Length/Fastq_Files/Results/${folder}/$i.txt"
    echo $i 'Saved into file with only sequences'
done
