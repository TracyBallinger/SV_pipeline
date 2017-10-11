
# Run this via the following: 
# qsub -t 1-n -tc x -v SAMPLES=bamlist.txt -v OUTPUT=outdir run_freec.sh
# A subdirectory called <sampleid> will be created within the OUTPUT which contains the FREEC results. 

#$ -N freec
#$ -cwd
#$ -j y 
#$ -l h_rt=24:00:00
#$ -l h_vmem=3G
#$ -pe sharedmem 4 
#   $ -o /exports/eddie/scratch/tballing/$JOB_NAME.o$JOB_ID.$TASK_ID 

unset MODULEPATH
. /etc/profile.d/modules.sh 

reffa=/exports/igmm/software/pkg/el7/apps/bcbio/share2/genomes/Hsapiens/hg38/seq/hg38.fa

configtemp=./freec_config_pileup.txt

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line 
bamfile=$1
id=`basename $bamfile .pileup.gz`

mkdir -p $OUTPUT/$id
outdir=$OUTPUT/$id
sed 's&^mateFile = sample.bam&mateFile = '$bamfile'&' $configtemp | \
sed 's&^outputDir = &outputDir = '$outdir'&' > $outdir/config.txt 

(/exports/igmm/eddie/NextGenResources/software/FREEC/FREEC-9.7b/src/freec -conf $outdir/config.txt) &> $outdir/freec.log


