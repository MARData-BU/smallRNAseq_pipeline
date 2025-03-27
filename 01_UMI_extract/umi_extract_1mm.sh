#!/bin/bash
#SBATCH -p normal,long            	# Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 45Gb     	# Memory in MB
#SBATCH -J UMI_extract           	# job name
#SBATCH -o logs/UMI_extract.%A_%a.out	# Sdt out file name: %j SLURM_JOB_ID; %A SLURM_ARRAY_JOB_ID, %a SLURM_ARRAY_TASK_ID
#SBATCH -e logs/UMI_extract.%A_%a.err	# Std err file name

module purge
module load Python/3.8.6-GCCcore-10.2.0
echo "Python module loaded."
#------------------------
# Prapare folders

FASTQDIR=$1
folder=$2
WD=$3
ADAPTER=$4
FASTQ_SUFFIX=$5

echo -e "The working directory has been defined as $WD."
echo -e "The fastq directory has been defined as $FASTQDIR."
echo -e "The batch that is now being processed is $folder."
echo -e "The adapter has been defined as $ADAPTER."
echo -e "The fastq suffix has been defined as $FASTQ_SUFFIX."

OUTDIR=$WD/01_UMI_extract/Fastq_Files/${folder}

echo "Folders prepared."
#--------------------
# Prapare input files
FASTQFILES=($(ls -1 $FASTQDIR/${folder}/*$FASTQ_SUFFIX))
i=$(($SLURM_ARRAY_TASK_ID - 1)) ## bash arrays are 0-based
INFILE=${FASTQFILES[i]}

name=`basename -s $FASTQ_SUFFIX $INFILE`

echo "Computing sample $name"

#------------------------
# INFO
# https://uofuhealth.utah.edu/huntsman/shared-resources/gba/htg/library-prep/small-rna.php
#The Read 1 sequence of a library constructed with the Qiagen QIAseq miRNA Library Kit may include the following sequences: miRNA sequence, a 19 base Qiagen adapter sequence, a 12 base unique molecular index (UMI), a 34 base Illumina adapter sequence, and a 6 base p7 index. Adapter sequences need to be trimmed prior to alignment.

#    ** TAGCTTATCAGACTGATGTTGA (example of miRNA sequence)
#    ** AACTGTAGGCACCATCAAT (19 base Qiagen adapter)
#    ** NNNNNNNNNNNN (12 base random sequence representing the UMI)
#    ** AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC (Illumina adapter sequence)
#    ** ATCACG (example of i7 index sequence)

#------------------------
# STEPS

# Pattern that allows 1 substitution in adapter 1 (QIAGEN)
# Then requires 12bp as UMI
# Then discards anything beyond
umi_tools extract --stdin $INFILE \
                    --bc-pattern=".*(?P<discard_1>$ADAPTER){s<=1}(?P<umi_1>.{12})(?P<discard_2>.*$)" \
                    --extract-method=regex \
		    --log ${OUTDIR}/${name}.log \
		    --stdout ${OUTDIR}/${name}.fastq
echo "Umi-tools performed."

module purge
module load FastQC/0.11.7-Java-1.8.0_162

echo "FastQC module loaded."
#------------------------

fastqc --outdir $OUTDIR --threads $SLURM_CPUS_PER_TASK ${OUTDIR}/${name}.fastq

