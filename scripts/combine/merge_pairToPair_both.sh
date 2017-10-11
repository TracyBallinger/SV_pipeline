#!/bin/bash 

# SU is the cutoff for the read coverage for a break 

#$ -N  
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

pairboth=$1
output=$2

###########################################################
# The pairToPair -type both intersects both intervals in a
# bedpe file with both intervals in another bedpe file. 
# The output has a line from the first bedpe followed by the 
# intersecting line from the second. 
# Here we are assuming that the first line is the first 11 
# fields and the second line begins at field 12. 

function merge_bothbedpe {
	bothbedpe=$1
	cat $bothbedpe | \
	awk 'BEGIN{OFS="\t"}
		{s1=($2 < $13) ? $2 : $13;
		s2=($3 < $14) ? $3 : $14; 
		e1=($5 > $16) ? $5 : $16; 
		e2=($6 > $17) ? $6 : $17;
		score=($8+$19);
	print $1"\t"s1"\t"s2"\t"$4"\t"e1"\t"e2"\t"$7"+"$18"\t"score"\t.\t.\t"$11"\t"$22}'  
}

merge_bothbedpe $pairboth > $output

