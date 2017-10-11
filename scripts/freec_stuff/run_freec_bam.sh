
# Run this via the following: 
# qsub -t 1-n -tc x -v SAMPLES=bamlist.txt -v OUTPUT=outdir run_freec_bam.sh
# A subdirectory called <sampleid> will be created within the OUTPUT which contains the FREEC results. 

#$ -N freec
#$ -cwd
#$ -j y 
#$ -l h_rt=03:00:00
#$ -l h_vmem=5G
#$ -pe sharedmem 4 
#   $ -o /exports/eddie/scratch/tballing/$JOB_NAME.o$JOB_ID.$TASK_ID 

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916

configtemp=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts/freec_config.txt

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line 
bamfile=$1
id=`basename $bamfile .bam`
vcffile=/exports/igmm/eddie/EyeMalform/X00013WK/2016-04-19_vcfs/$id.vcf.gz

mkdir -p $OUTPUT/$id
outdir=$OUTPUT/$id
sed 's&^mateFile = sample.bam&mateFile = '$bamfile'&' $configtemp | \
sed 's&^outputDir = &outputDir = '$outdir'&' | \
sed 's&^makePileup = myvcf&makePileup = '$vcffile'&' > $outdir/config.txt 

(/exports/igmm/eddie/NextGenResources/software/FREEC/FREEC-11.0/src/freec -conf $outdir/config.txt) &> $outdir/freec.log


