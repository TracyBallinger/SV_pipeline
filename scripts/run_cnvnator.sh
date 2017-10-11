
# Run this via the following: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt run_cnvnator.sh

#$ -N cnvnator 
#$ -cwd
#$ -j y 
#$ -l h_rt=24:00:00
#$ -l h_vmem=5G
#$ -pe sharedmem 2 
#   $ -o /exports/eddie/scratch/tballing/$JOB_NAME.o$JOB_ID.$TASK_ID 

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load root/6.06.02
module load igmm/apps/bcbio/20160916

cnvnatordir=/home/tballing/NextGenResources/software/CNVnator/CNVnator_v0.3.2/src
TMPDIR=/exports/eddie/scratch/tballing/EyeMalform/cnvnator
OUTDIR=/exports/eddie/scratch/tballing/EyeMalform/cnvnator

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line 
bamfile=$1
id=`basename $bamfile .bam`
tempdir=$TMPDIR/$id
mkdir -p $tempdir

$cnvnatordir/cnvnator -root $tempdir/out.root -tree $bamfile 

# Generating a histogram
fastadir=/exports/igmm/eddie/NextGenResources/reference/hg38/chroms
binsize=100
#$cnvnatordir/cnvnator -root $tempdir/out.root -his $binsize -d $fastadir
#$cnvnatordir/cnvnator -root $tempdir/out.root -stat $binsize
#$cnvnatordir/cnvnator -root $tempdir/out.root -partition $binsize 
#$cnvnatordir/cnvnator -root $tempdir/out.root -call $binsize > $tempdir/cnv.calls
awk '{print $2}END{print "exit"}' $tempdir/cnv.calls | $cnvnatordir/cnvnator -root $tempdir/out.root -genotype 100 








