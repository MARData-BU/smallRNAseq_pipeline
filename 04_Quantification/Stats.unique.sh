#!/bin/bash
#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 29Gb     # Memory in MB
#SBATCH -J quant.stats           # job name
#SBATCH -o logs/quant.stats.%j.out    # File to which standard out will be written
#SBATCH -e logs/quant.stats.%j.err    # File to which standard err will be written

FASTQDIR=$1
WD=$2
folder=$3
PROJECT=$4
# Prepare variables
#------------------

mkdir -p $WD/04_Quantification/Stats/${folder}
mkdir -p $PROJECT/QC/${folder}/QC_trimmed/
mkdir -p $PROJECT/QC/${folder}/QC_trimmed/MultiQC_data

featurecountsDIR=$WD/04_Quantification/FeatureCounts/${folder}
umicountsDIR=$WD/04_Quantification/UMI_Counts/${folder}
OUTDIR=$WD/04_Quantification/Stats/${folder}

cd $OUTDIR

for line in $(ls $umicountsDIR/*.tsv ); do  name=`basename -s .tsv $line` ; featurecounts=`awk -F '\t' '$1 ~ /hsa/ {sum += $7} END {print sum}' $featurecountsDIR/${name}.txt`; umicounts=`cat $line | awk '{sum+=$2} END{print sum}' `; printf $name"\t"$featurecounts"\t"$umicounts"\n";  done > $OUTDIR/Stats.txt
echo "Stats.txt file generated."


# Copy files for multiqc
#cp $featurecountsDIR/*.txt.summary $PROJECT/QC/${folder}/QC_trimmed/
ln -s $featurecountsDIR/*.txt.summary $PROJECT/QC/${folder}/QC_trimmed/MultiQC_data # create symbolic link 
echo "Files for multiQC copied."

cd $PROJECT/QC/${folder}/QC_trimmed/
module purge
module load  Python/3.8.6-GCCcore-10.2.0
echo "Python module loaded."

multiqc -f .
echo "MultiQC run."
