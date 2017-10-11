
# Run this via the following: 
# qsub -t 1-n -tc x -v SAMPLES=bamlist.txt run_freec_cnp.sh
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

configtemp=./freec_config_cnp.txt
OUTPUT=/exports/eddie/scratch/tballing/EyeMalform/freecbaf

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line 
bamfile=$1
id=`basename $bamfile .bam`
outdir=$OUTPUT/$id
mkdir -p $OUTPUT/$id

cnpfile=/exports/eddie/scratch/tballing/EyeMalform/freecout/$id/$id.bam_sample.cpn
gcfile=/exports/eddie/scratch/tballing/EyeMalform/freecout/$id/GC_profile.cnp

sed 's&^mateCopyNumberFile = sample.cnp&mateCopyNumberFile = '$cnpfile'&' $configtemp \
| sed 's&^GCcontentProfile = &GCcontentProfile = '$gcfile'&' \
| sed '
| sed 's&^outputDir = &outputDir = '$outdir'&' > $outdir/config.txt

(/exports/igmm/datastore/NextGenResources/software/FREEC-9.6/src/freec -conf $outdir/config.txt) &> $outdir/freec.log


