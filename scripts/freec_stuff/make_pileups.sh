
# Run this via the following: 
# qsub -t 1-n -tc 5 -v SAMPLES=bam.list make_pileups.sh 
# The -tc options says how many jobs to run at a time 
# The bam.list should just be a list of bams to make pileups from (full path name from cwd) 

#$ -N pileup 
#$ -cwd
#$ -j y 
#$ -l h_rt=48:00:00
#$ -l h_vmem=4G 
#$ -o /exports/eddie/scratch/tballing/$JOB_NAME.o$JOB_ID

unset MODULEPATH 
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916

reffa=/exports/igmm/software/pkg/el7/apps/bcbio/share2/genomes/Hsapiens/hg38/seq/hg38.fa

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line
bam=$1
sampleid=`basename $bam .bam`

snppos=/exports/igmm/software/pkg/el7/apps/bcbio/share2/genomes/Hsapiens/hg38/variation/dbsnp-147.1based.pos.txt
OUT=/exports/eddie/scratch/tballing/EyeMalform/freecbaf

samtools mpileup -f $reffa --positions $snppos $bam > $OUT/$sampleid.mini_pileup 

