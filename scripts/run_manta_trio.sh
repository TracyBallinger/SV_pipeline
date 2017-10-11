
# Run this via the following: 
# qsub -t 1-n -tc x run_manta_trios.sh

#$ -N manta 
#$ -cwd
#$ -j y 
#$ -l h_rt=24:00:00
#$ -l h_vmem=3G
#$ -pe sharedmem 4 
#   $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID 

TMPDIR=/exports/eddie/scratch/tballing/EyeMalform/manta_trio
OUTDIR=/exports/eddie/scratch/tballing/EyeMalform/manta_trio
unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916
module load igmm/apps/python/2.7.10

mantadir=/exports/igmm/software/pkg/el7/apps/bcbio/share2/anaconda/share/manta-1.0.0-0/bin
python=/exports/igmm/software/pkg/el7/apps/bcbio/share/bcbio-nextgen/anaconda/bin/python
reffa=/gpfs/igmmfs01/software/pkg/el7/apps/bcbio/share2/genomes/Hsapiens/hg38/seq/hg38.fa
samples=bam_groups.txt

id=sample_group$SGE_TASK_ID
mkdir -p $OUTDIR/$id
out=$OUTDIR/$id

bamfiles=(`grep ^$SGE_TASK_ID"	" $samples | cut -f3`)
echo $bamfiles
for i in ${!bamfiles[*]}; 
do 
	mystr=`echo $mystr --bam=${bamfiles[$i]}`
	echo $i
	echo $mystr
done
echo $mystr

$python $mantadir/configManta.py $mystr --referenceFasta=$reffa --runDir=$out
$python $out/runWorkflow.py -m local -j 4 --quiet

