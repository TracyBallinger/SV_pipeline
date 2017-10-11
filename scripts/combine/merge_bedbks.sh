#!/bin/bash 

#$ -N mergebed 
#$ -cwd
#$ -j y 
#$ -l h_rt=24:00:00
#$ -l h_vmem=1G
#$ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh
# You really just need bedtools, but bedtools is in bcbio
module load igmm/apps/bcbio/20160916
# module load igmm/apps/python/2.7.10

bedfile=$1

# Use bedtools to collapse overlapping intervals (breaks) and pick the 
# annotation from the SV breakend that has the best score
function merge_bedbks {
	bedf=$1
	w=4
	nf=`head -1 $bedf | awk 'BEGIN{FS="\t"}{print NF}'`
	for x in `seq 5 $nf`; do w=$w","$x; done 
	LC_ALL=C sort -k1,1 -k2,2n $bedf \
	| bedtools merge -c $w -o collapse -delim "|" -i - \
	| awk 'BEGIN{FS="\t"; OFS="\t"} 
	{n=split($5, a, "|"); besti=1;
	for(i=2; i<=n; i++){if (a[i] > a[besti]) besti=i}
	for(i=4; i<=NF; i++){split($i, a, "|"); $i=a[besti]}
	print $0}' 
}
	
merge_bedbks $bedfile

