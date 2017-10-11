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
module load igmm/apps/bcbio/20160916

bedpe1=$1
bedpe2=$2
outfile=$3
slop=0

scriptdir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts/combine

##############################################
# Use bedtools pairToPair to compare bedpe files
# Here we're looking for SVs where both ends match up. 
pairToPair -type both -is -slop $slop -rdn \
	-a $bedpe1 -b $bedpe2 | sort -u > both.bedpe

c2=`head -1 $bedpe1 | awk -F"\t" '{print NF}'`
python $scriptdir/merge_pairToPair.py -c $c2 both.bedpe > merged.bedpe	
myNF=`head -1 merged.bedpe | awk -F"\t" '{print NF}'`

#################################################
# Get the SVs from bedpe1 that don't match a call from bedpe2, and vice versa 
cut -f1-$c2 both.bedpe | sort -u | cat $bedpe1 - | sort | uniq -u > uniq1.bedpe
c3=$((c2 + 1))
cut -f$c3- both.bedpe | sort -u | cat $bedpe2 - | sort | uniq -u > uniq2.bedpe

#################################################
# Make a dummy column for the paired ends that don't overlap
myNF=`head -1 merged.bedpe | awk -F"\t" '{print NF}'`
cat uniq1.bedpe | awk 'BEGIN{OFS="\t"}
	{c=".:./.:.:.:."; for (i=1; i< (myNF-NF); i++) {c=c"\t.:./.:.:.:."} 
	print $0"\t"c}' myNF=$myNF > uniq1c.bedpe
cat uniq2.bedpe | awk 'BEGIN{OFS="\t"}
	{c=".:./.:.:.:."; for (i=1; i< (myNF-NF); i++) {c=c"\t.:./.:.:.:."} 
	print c}' myNF=$myNF > tmpmid
cut -f1-10 uniq2.bedpe > tmpfirst
cut -f11- uniq2.bedpe | paste tmpfirst tmpmid - > uniq2c.bedpe

################################################
# Join the matching and mismatching calls.
cat merged.bedpe uniq1c.bedpe uniq2c.bedpe > $outfile

