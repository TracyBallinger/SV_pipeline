
# Run this via the following: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt run_manta.sh

#$ -N manta 
#$ -cwd
#$ -j y 
#$ -l h_rt=24:00:00
#$ -l h_vmem=3G
#$ -pe sharedmem 4 
#   $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID 

TMPDIR=/exports/eddie/scratch/tballing/EyeMalform/manta
OUTDIR=/exports/eddie/scratch/tballing/EyeMalform/manta

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916
module load igmm/apps/python/2.7.10

mantadir=/exports/igmm/software/pkg/el7/apps/bcbio/share2/anaconda/share/manta-1.0.0-0/bin
python=/exports/igmm/software/pkg/el7/apps/bcbio/share/bcbio-nextgen/anaconda/bin/python
reffa=/gpfs/igmmfs01/software/pkg/el7/apps/bcbio/share2/genomes/Hsapiens/hg38/seq/hg38.fa

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line 
bamfile=$1
id=`basename $bamfile .bam`

mkdir -p $OUTDIR/$id
out=$OUTDIR/$id

$python $mantadir/configManta.py --bam=$bamfile --referenceFasta=$reffa --runDir=$out
$python $out/runWorkflow.py -m local -j 4 --quiet

