# Run this via: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt -v OUTDIR=outdir run_canvas.sh 

#$ -N canvas
#$ -cwd
#$ -j y 
#$ -l h_rt=24:00:00
#$ -l h_vmem=16G
#$ -pe sharedmem 4 
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/Canvas/1.25

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line 
bamfile=$1
id=`basename $bamfile .bam`
tempdir=$TMPDIR/$id
mkdir -p $tempdir
outdir=$OUTDIR/$id
mkdir -p $outdir
vcfdir=/exports/igmm/eddie/EyeMalform/X00013WK/2016-04-19_vcfs

canvasres=/home/tballing/NextGenResources/resources/human/hg38/Canvas

echo "Canvas Germline-WGS \
	--bam=$bamfile \
	--output=$outdir \
	--reference=$canvasres/WholeGenomeFasta/genome.fa \
	--genome-folder=$canvasres/WholeGenomeFasta \
	--filter-bed=$canvasres/filter13.bed \
	--sample-b-allele-vcf=$vcfdir/$id.vcf.gz \
	--sample-name=$id
"
Canvas Germline-WGS \
	--bam=$bamfile \
	--output=$outdir \
	--reference=$canvasres/WholeGenomeFasta/genome.fa \
	--genome-folder=$canvasres/WholeGenomeFasta \
	--filter-bed=$canvasres/filter13.bed \
	--sample-b-allele-vcf=$vcfdir/$id.vcf.gz \
	--sample-name=$id

