# Run this via: 
# qsub -v BEDPE=file.bedpe -v OUTPUT=outfile combine_svbedpe_with1kg.sh 

#!/bin/bash
#$ -cwd
#$ -w w 
#$ -j y
#$ -S /bin/sh
#$ -N comb1kg
# $ -pe sharedmem 2
#$ -l h_vmem=10G
#$ -l h_rt=00:30:00
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916

bedpe=$1
output=$2
format=$3
slop=0

bedpe1KG=/exports/igmm/eddie/EyeMalform/X00013WK/sv/1000Genomes_SV.GRCh38.variant_region.germline.bedpe
bed1KG=/exports/igmm/eddie/EyeMalform/X00013WK/sv/1000Genomes_SV.GRCh38.variant_region.germline.bed

###########################################################
# The pairToPair -type both intersects both intervals in a
# bedpe file with both intervals in another bedpe file. 
# The output has a line from the first bedpe followed by the 
# intersecting line from the second. 
if [ "$format" == "bedpe" ]; then 
	cn=`head -1 $bedpe | awk -F"\t" '{print NF}'`
	pairToPair -type both -is -slop $slop -rdn -a $bedpe -b $bedpe1KG > tmp1kg.bedpe 
	cut -f1-$cn tmp1kg.bedpe | sort -u > have1kg.bedpe
	cat $bedpe have1kg.bedpe | sort | uniq -c \
		| awk '{print $1-1}' | paste $bedpe - > $output 
elif [ "$format" == "bed" ]; then 
	bedtools intersect -c -a $bedpe -b $bed1KG > $output
fi 
 
