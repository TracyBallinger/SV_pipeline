
# Run this via the following: 
# qsub -v OUTPUT=outdir run_freec_plain.sh

#$ -N freec
#$ -cwd
#$ -j y 
#$ -l h_rt=24:00:00
#$ -l h_vmem=3G
#$ -pe sharedmem 4 
#   $ -o /exports/eddie/scratch/tballing/$JOB_NAME.o$JOB_ID.$TASK_ID 

unset MODULEPATH
. /etc/profile.d/modules.sh 

config=./freec_config.txt
outdir=$OUTPUT
cp $config $outdir/config.txt

(/exports/igmm/eddie/NextGenResources/software/FREEC-9.5/src/freec -conf $outdir/config.txt) &> $outdir/freec.log


