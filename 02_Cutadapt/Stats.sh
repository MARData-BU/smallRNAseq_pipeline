#!/bin/bash
#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 29Gb     # Memory in MB
#SBATCH -J cut.stats           # job name
#SBATCH -o logs/cut.stats.%j.out    # File to which standard out will be written
#SBATCH -e logs/cut.stats.%j.err    # File to which standard err will be written

WD=$1
folder=$2
PROJECT=$3

# Prepare variables
#------------------

mkdir -p $WD/02_Cutadapt/Stats/${folder}

INDIR=$WD/02_Cutadapt/Trimmed_Files/${folder}
OUTDIR=$WD/02_Cutadapt/Stats/${folder}
mkdir $OUTDIR/scripts
cd $OUTDIR
echo "Directories created."

# Histogram values
for line in $(ls $INDIR/*.gz)
	do
	name=`basename -s .gz $line`
	zcat $line | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' | sort > $OUTDIR/${name}_lengths.txt
done

echo "Histogram values printed in txt files."

# R script for plots

# Histogram plots
#for line in $(ls $INDIR/*.fastq.gz)
#	do
# 	Treads=$(zcat $line | grep -c @)
#	echo "====================================="
#	echo $line. Total reads = $Treads
#	echo "====================================="

#	find $line -not -name \*raw\* -printf "zcat %p | awk '{if(NR%%4==2) print length(\$1)}' | $(pwd) -maxBinCount=59 stdin \n" | sh
#	printf "\n"
#done > $OUTDIR/Histograms_length.txt

for line in $INDIR/*.fastq.gz; do
    Treads=$(zcat "$line" | grep -c "@")
    echo "====================================="
    echo "$line. Total reads = $Treads"
    echo "====================================="
    
    echo
done > "$OUTDIR/Histograms_length.txt"

echo "Total reads per sample printed and saved in $OUTDIR/Histograms_length.txt."

# Copy files for multiqc

mkdir -p $PROJECT/QC/${folder}/QC_trimmed/
mkdir -p $PROJECT/QC/${folder}/QC_trimmed/MultiQC_data

#cp $INDIR/*.zip $PROJECT/QC/${folder}/QC_trimmed/
ln -s $INDIR/*zip $PROJECT/QC/${folder}/QC_trimmed/MultiQC_data # create a symbolic link 

echo "Files for MultiQC copied."

cd $PROJECT/QC/${folder}/QC_trimmed/

module load  Python/3.8.6-GCCcore-10.2.0
multiqc -f .

echo "MultiQC run."
