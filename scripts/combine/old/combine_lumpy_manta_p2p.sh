#!/bin/bash
#$ -cwd
#$ -w w 
#$ -j y
#$ -S /bin/sh
#$ -N lumpmant 
# $ -pe sharedmem 2
#$ -l h_vmem=5G
#$ -l h_rt=00:30:00
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load java/jdk/1.8.0
module load igmm/apps/bcbio/20160916

lumpyf=$1
mantaf=$2
outfile=$3
slop=0

scriptdir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts
$scriptdir/manta_to_bedpe.sh $mantaf manta.bedpe bedpe 
$scriptdir/lumpy_to_bedpe.sh $lumpyf lumpy.bedpe bedpe

##############################################
# Use bedtools pairToPair to compare bedpe files
# Here we're looking for SVs where both ends match up. 
pairToPair -type both -is -slop $slop \
	-a lumpy.bedpe \
	-b manta.bedpe | sort -u > both.bedpe

python $scriptdir/merge_pairToPair.py both.bedpe > lumpy_manta_both.bedpe	

#################################################
# Get the SVs from lumpy that don't match a manta call, and vice versa 
cut -f1-11 both.bedpe | sort -u | cat lumpy.bedpe - | sort | uniq -u > lumpy2.bedpe
cut -f12-22 both.bedpe | sort -u | cat manta.bedpe - | sort | uniq -u > manta2.bedpe

#################################################
# Make a dummy column for the paired ends that don't overlap
# between lumpy and manta.  
awk 'BEGIN{OFS="\t"}{$12=".:./.:.:.:."; print $0}' lumpy2.bedpe > tmp
awk 'BEGIN{OFS="\t"}{$12=$11; $11=".:./.:.:.:."; print $0}' manta2.bedpe | cat tmp - > lumpy_manta_notboth.bedpe 

cat lumpy_manta_both.bedpe lumpy_manta_notboth.bedpe > $outfile 

# rm lumpy.bedpe manta.bedpe 
# rm both.bedpe lumpy2.bedpe manta2.bedpe tmp.mantape.*


