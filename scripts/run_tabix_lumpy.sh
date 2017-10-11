
# Run this via the following: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt run_lumpy.sh

#$ -N tabix 
#$ -cwd
#$ -j y 
#$ -l h_rt=00:30:00
#$ -l h_vmem=1G
#$ -pe sharedmem 2 
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID 

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916

for f in lumpy/*.vcf.gz;
do
	echo $f 
	bgzip -dc $f | grep ^"#" > myheader
	bgzip -dc $f | grep -v ^"#" | sort -k 1,1 -k2,2n | cat myheader - | bgzip > new/$f 
	tabix new/$f 
done 
 
