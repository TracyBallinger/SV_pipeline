#!/bin/bash 

# This will generate data about how well two cnv calls match 
# cd freecout/full
#$ -N graph
#$ -cwd 
#$ -j y 
#$ -l h_rt=2:00:00
#$ -l h_vmem=2G

unset MODULEPATH
. /etc/profile.d/modules.sh
module load igmm/apps/R/3.3.0

for dir in `ls -d */`; 
do 
ratiofile=`ls $dir/*.bam_ratio.txt`

freecdir=/exports/igmm/eddie/NextGenResources/software/FREEC/FREEC-9.6/scripts
cat $freecdir/makeGraph.R | R --slave --args 2 $ratiofile 

done  
