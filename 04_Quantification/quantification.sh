#!/bin/bash
#SBATCH -p short           	 # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 90Gb   	 # Memory in MB
#SBATCH -J Featurecounts           	 # job name
#SBATCH -o logs/Featurecounts.%j.out    # File to which standard out will be written
#SBATCH -e logs/Featurecounts.%j.err    # File to which standard err will be written

WD=$1
folder=$2
REFGENE=$3
ANNOTGENE=$4
PROJECT=$5
UMI=$6

# Prepare variables
#------------------

cd $WD/03_Alignment

module load Subread/2.0.3
echo "Subread module loaded."

if [ $UMI == TRUE ]
    then

    mkdir -p $WD/04_Quantification/FeatureCounts/${folder}
    mkdir -p $WD/04_Quantification/UMI_Counts/${folder}

    INDIR=$WD/03_Alignment/BAM_Files/${folder}
    featurecountsDIR=$WD/04_Quantification/FeatureCounts/${folder}
    umicountsDIR=$WD/04_Quantification/UMI_Counts/${folder}

    # Prapare input files
    BAMFILES=($(ls -1 $INDIR/*.bam | grep Undetermined -v ))
    i=$(($SLURM_ARRAY_TASK_ID - 1)) ## bash arrays are 0-based
    INFILE=${BAMFILES[i]}

    name=`basename $INFILE` 

    echo "Sample $name is being analyzed."

    ######################################################################################################
    ##################################### COUNTS ########################################################
    featureCounts -T $SLURM_CPUS_PER_TASK -t miRNA -g miRNA_id -a $ANNOTGENE -G $REFGENE -M --fraction --fracOverlapFeature 0.85 -o ${featurecountsDIR}/${name}.txt -R BAM $INFILE

    ######################################################################################################
    ##################################### INDEX ########################################################
    module purge
    module load SAMtools/1.12-GCC-10.2.0
    echo "SAMtools module loaded."

    samtools sort ${featurecountsDIR}/${name}.featureCounts.bam -o ${featurecountsDIR}/${name}_sorted.bam;
    samtools index ${featurecountsDIR}/${name}_sorted.bam;

    ######################################################################################################
    ##################################### UMI COUNT ########################################################
    module purge
    module load  Python/3.8.6-GCCcore-10.2.0
    echo "Python module loaded."

    # Count UMIs per gene per cell (unique method)
    umi_tools count --per-gene --gene-tag=XT --method=unique -I ${featurecountsDIR}/${name}_sorted.bam -S ${umicountsDIR}/${name}.tsv # the tsv files will be merged with R afterwards

    # Default method (directional) is more strict (detects more duplicates) but it uses graphs
    # RAM requirements grow exponentially and some samples get stucked never finishing to sove the graph

    else 

    INPUT=`ls $BAMDIR/*.bam | paste -sd " " -`
    echo $INPUT

    ######################################################################################################
    ##################################### COUNTS ########################################################

    featureCounts -T $SLURM_CPUS_PER_TASK -t miRNA -g miRNA_id -a $ANNOTGENE -G $REFGENE -M --fraction --fracOverlapFeature 0.85 -o ${OUTDIR}/CountsTable.txt $INPUT

    # Copy files for multiqc
    cp $OUTDIR/CountsTable.txt.summary $PROJECT/QC/${folder}/QC_trimmed/
    echo "Counts table copied for MultiQC."

    cd $PROJECT/QC/${folder}/QC_trimmed/

    module purge
    module load  Python/3.8.6-GCCcore-10.2.0
    echo "Python module loaded."

    multiqc -f .
    echo "MultiQC run."

fi
