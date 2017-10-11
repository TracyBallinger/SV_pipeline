# Run this via: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt -v OUTDIR=outdir combine_sv_calls.sh 

#!/bin/bash
#$ -cwd
#$ -w w 
#$ -j y
#$ -S /bin/sh
#$ -N pair2pair
# $ -pe sharedmem 2
#$ -l h_vmem=5G
#$ -l h_rt=00:30:00
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916

bedf1=$1
bedf2=$2
outfile=$3
sdir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts/combine

##############################################
# Use bedtools to compare bed files

bedtools intersect -wo \
	-a $bedf1 \
	-b $bedf2 > both.bed

c1=`head -1 $bedf1 | awk -F"\t" '{print NF}'`
c2=`head -1 $bedf2 | awk -F"\t" '{print NF}'`
n2=$((c1 + 2))
n3=$((c1 + 3))
n4=$((c1 + 4))
n5=$((c1 + 5))
n7=$((c1 + 7))
nlast=$((c1 + $c2))
cut -f7-$c1 both.bed > tmpinfo1
cut -f$n7-$nlast both.bed > tmpinfo2
cat both.bed \
	| awk 'BEGIN{OFS="\t"; FS="\t"}{
	s1=$2; e1=$3; s2=$n2; e2=$n3;
	s=(s1 < s2 ? s1 : s2);
	e=(e1 > e2 ? e1 : e2);
	score=$5+$n5;
	print $1,s,e,$4"+"$n4,score,"."}' \
	n2=$n2 n3=$n3 n5=$n5 n4=$n4\
	| paste - tmpinfo1 tmpinfo2 > bthcomb.bed 

$sdir/merge_bedbks.sh bthcomb.bed > bothcomb.bed

#################################################
# get the breaks that don't overlap 
cut -f1-$c1 both.bed | sort -u | cat $bedf1 - | sort | uniq -u > uniq1.bed
cut -f$((c1 + 1 ))-$nlast both.bed | sort -u | cat $bedf2 - | sort | uniq -u > uniq2.bed

#################################################
# Make a dummy column for the breaks that don't overlap
myNF=`head -1 bothcomb.bed | awk -F"\t" '{print NF}'`

cat uniq1.bed \
	| awk 'BEGIN{OFS="\t"; FS="\t"}
	{c=".:./.:.:.:."; for (i=1; i<(myNF-NF); i++){c=c"\t.:./.:.:.:."}
	print $0"\t"c}' myNF=$myNF > bed1uniq.bed

cat uniq2.bed | awk 'BEGIN{OFS="\t"; FS="\t"}
	{c=".:./.:.:.:."; for (i=1; i<(myNF-NF); i++){c=c"\t.:./.:.:.:."}
	print c}' myNF=$myNF > tmpmid
cut -f1-6 uniq2.bed > tmpfirst
cut -f7- uniq2.bed | paste tmpfirst tmpmid - > bed2uniq.bed

cat bothcomb.bed bed1uniq.bed bed2uniq.bed > $outfile


