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
module load java/jdk/1.8.0
module load igmm/apps/bcbio/20160916
module load R 

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line
bamfile=$1
id=`basename $bamfile .bam`
mkdir -p $OUTDIR
outdir=$OUTDIR/$id
mkdir -p $outdir

scriptdir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts
lumpydat=/exports/igmm/eddie/EyeMalform/X00013WK/sv/lumpy
mantadat=/exports/igmm/eddie/EyeMalform/X00013WK/sv/manta

cd $outdir
diploid=$mantadat/$id/results/variants/diploidSV.vcf.gz 
$scriptdir/manta_to_bedpe.sh $diploid manta_diploid.bed bed 

#candidate=$mantadat/$id/results/variants/candidateSV.vcf.gz 
#$scriptdir/manta_to_bedpe.sh $candidate manta_candidate.bed bed 

# lumpybin=/exports/igmm/software/pkg/el7/apps/bcbio/share2/anaconda/pkgs/lumpy-sv-0.2.12-py27_3/share/lumpy-sv-0.2.12-3
# gzip -dc $lumpydat/$id.vcf.gz | $lumpybin/scripts/vcfToBedpe -i - -o $outdir/lumpy.bedpe
$scriptdir/lumpy_to_bedpe.sh $lumpydat/$id.vcf.gz lumpy.bed bed

##############################################
# Use bedtools to compare bedpe files

bedtools intersect -wo \
	-a lumpy.bed \
	-b manta_diploid.bed > both.bed

cat both.bed | tr '|' '\t' \
	| awk 'BEGIN{OFS="\t"; FS="\t"}{
	s1=$2; e1=$3; s2=$9; e2=$10; 
	s= (s1 < s2 ? s1 : s2);
	e=(e1 > e2 ? e1 : e2);
	score=$6+13;
	print $1,s,e,$4"+"$11,$13,".",$5,$12}' > bothcomb.bed 

cut -f1-6 both.bed | sort -u | cat lumpy.bed - | sort | uniq -u \
	| tr '|' '\t' \
	| awk 'BEGIN{OFS="\t"; FS="\t"}
	{print $1,$2,$3,$4,$6,$7,$5,".:./.:.:.:."}' > lumpyuniq.bed

cut -f7-13 both.bed | sort -u | cat manta_diploid.bed - | sort | uniq -u \
	| tr '|' '\t' \
	| awk 'BEGIN{OFS="\t"; FS="\t"}
	{print $1,$2,$3,$4,$6,$7,".:./.:.:.:.",$5}' > mantauniq.bed


cat bothcomb.bed lumpyuniq.bed mantauniq.bed > lumpy_manta_bkpts.bed

