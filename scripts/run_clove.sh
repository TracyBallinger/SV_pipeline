# Run this via: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt -v OUTDIR=outdir run_clove.sh 

#!/bin/bash
#$ -cwd
#$ -w w 
#$ -j y
#$ -S /bin/sh
#$ -N clove
#$ -pe sharedmem 2
#$ -l h_vmem=5G
#$ -l h_rt=23:30:00
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

diploid=$mantadat/$id/results/variants/diploidSV.vcf.gz 
$scriptdir/manta_to_bedpe.sh $diploid $outdir/manta_diploid.bedpe bedpe 

candidate=$mantadat/$id/results/variants/candidateSV.vcf.gz 
$scriptdir/manta_to_bedpe.sh $candidate $outdir/manta_candidate.bedpe bedpe 

$scriptdir/lumpy_to_bedpe.sh $lumpydat/$id.vcf.gz $outdir/lumpy.bedpe bedpe
#lumpybin=/exports/igmm/software/pkg/el7/apps/bcbio/share2/anaconda/pkgs/lumpy-sv-0.2.12-py27_3/share/lumpy-sv-0.2.12-3
#gzip -dc $lumpydat/$id.vcf.gz | $lumpybin/scripts/vcfToBedpe -i - -o $outdir/lumpy.bedpe

##### 
# Need to calculate coverage and coverage variance for the bamfile!!!
# Just use chr11 to be faster.
tmpdir=/home/tballing/scratch/clove/$id
mkdir -p $tmpdir
sambamba view -f bam $bamfile chr11 > $tmpdir/chr11.bam
bedtools genomecov -ibam $tmpdir/chr11.bam -g $scriptdir/../hg38.chrom.sizes -max 200 > $outdir/bedcov.hist
Rscript $scriptdir/get_mean_sd_from_covhist.R $outdir/bedcov.hist $outdir/covstats.txt
m=`cut -f1 $outdir/covstats.txt`
s=`cut -f2 $outdir/covstats.txt`

CLOVE_JAR=/exports/igmm/eddie/NextGenResources/software/clove/clove-0.15-jar-with-dependencies.jar
java -jar $CLOVE_JAR \
	-i $outdir/manta_diploid.bedpe BEDPE \
	-i $outdir/manta_candidate.bedpe BEDPE \
	-i $outdir/lumpy.bedpe BEDPE \
	-b $bamfile \
	-c $m $s \
	-o $outdir/$id.clove.vcf

