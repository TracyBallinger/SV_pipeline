# Run this via: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt -v OUTDIR=outdir combine_sv_calls_p2p.sh 
# The outdir must exist already. 

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
fulloutdir=`readlink -f $OUTDIR`
outdir=$fulloutdir/$id
mkdir -p $outdir

tmpdir=/home/tballing/scratch/combine_sv
mkdir -p $tmpdir
tmpdir=$tmpdir/$id
mkdir -p $tmpdir

slop=0

scriptdir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts
lumpydat=/exports/igmm/eddie/EyeMalform/X00013WK/sv/lumpy
mantadat=/exports/igmm/eddie/EyeMalform/X00013WK/sv/manta

cd $tmpdir 
diploid=$mantadat/$id/results/variants/diploidSV.vcf.gz 
$scriptdir/manta_to_bedpe.sh $diploid manta_diploid.bedpe bedpe 

candidate=$mantadat/$id/results/variants/candidateSV.vcf.gz 
$scriptdir/manta_to_bedpe.sh $candidate manta_candidate.bedpe bedpe 

$scriptdir/lumpy_to_bedpe.sh $lumpydat/$id.vcf.gz lumpy.bedpe bedpe
# lumpybin=/exports/igmm/software/pkg/el7/apps/bcbio/share2/anaconda/pkgs/lumpy-sv-0.2.12-py27_3/share/lumpy-sv-0.2.12-3
# gzip -dc $lumpydat/$id.vcf.gz | $lumpybin/scripts/vcfToBedpe -i - -o $outdir/lumpy.bedpe

##############################################
# Use bedtools pairToPair to compare bedpe files
# Here we're looking for SVs where both ends match up. 
pairToPair -type both -is -slop $slop \
	-a lumpy.bedpe \
	-b manta_diploid.bedpe | sort -u > both.bedpe

python $scriptdir/merge_pairToPair.py both.bedpe > lumpy_manta_both.bedpe	

#################################################
# Get the SVs from lumpy that don't match a manta call, and vice versa 
cut -f1-11 both.bedpe | sort -u | cat lumpy.bedpe - | sort | uniq -u > lumpy2.bedpe
cut -f12-22 both.bedpe | sort -u | cat manta_diploid.bedpe - | sort | uniq -u > manta2.bedpe

# pairToPair seems to have a bug where the score
# is often missing for the second bedpe entry of line.  
# To fix this, I run pairToPair twice, switching which file
# is first and then sorting and pasting the two results together. 
pairToPair -type either -is -slop $slop \
	-a lumpy2.bedpe -b manta2.bedpe \
	| sort -k7,7 -k18,18 | cut -f1-11 > eitherl.bedpe

pairToPair -type either -is -slop $slop \
	-b lumpy2.bedpe -a manta2.bedpe \
	| sort -k18,18 -k7,7 | cut -f1-11 | paste eitherl.bedpe - \
	| python $scriptdir/merge_pairToPair.py - > lumpy_manta_either.bedpe 

#################################################
# Make a dummy column for the paired ends that don't overlap
# between lumpy and manta.  
awk 'BEGIN{OFS="\t"}{$12=".:./.:.:.:."; print $0}' lumpy2.bedpe > tmp
awk 'BEGIN{OFS="\t"}{$12=$11; $11=".:./.:.:.:."; print $0}' manta2.bedpe | cat tmp - > lumpy_manta_notboth.bedpe 

cat lumpy_manta_both.bedpe lumpy_manta_notboth.bedpe > lumpy_manta_calls.bedpe
mv lumpy_manta_*.bedpe $outdir 

# rm lumpy.bedpe manta.bedpe 
# rm both.bedpe either1.bedpe lumpy2.bedpe manta2.bedpe tmp.mantape.*


