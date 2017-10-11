# Run this via: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt -v OUTDIR=outdir combine_sv_calls_bks.sh 
# The outdir must exist already. 

#!/bin/bash
#$ -cwd
#$ -w w 
#$ -j y
#$ -S /bin/sh
#$ -N combbks 
# $ -pe sharedmem 2
#$ -l h_vmem=7G
#$ -l h_rt=00:30:00
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916

slop=0
sdir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts/combine
##################################################
# Set the output directory and temporary directory
line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line
bamfile=$1
id=`basename $bamfile .bam`
fulloutdir=`readlink -f $OUTDIR`
outdir=$fulloutdir/$id
mkdir -p $outdir

tmpdir=/home/tballing/scratch/combine_sv
mkdir -p $tmpdir
tmpdir=$tmpdir/$id
mkdir -p $tmpdir

####################################################
# Read in the data from the individual SV callers 
lumpydat=/exports/igmm/eddie/EyeMalform/X00013WK/sv/lumpy
lumpyf=$lumpydat/$id.vcf.gz 

gridssdat=/exports/igmm/eddie/EyeMalform/X00013WK/sv/gridss
gridssf=$gridssdat/$id/$id.sv.vcf 

# mantadat=/exports/igmm/eddie/EyeMalform/X00013WK/sv/manta
mantadat=/exports/igmm/eddie/EyeMalform/X00013WK/sv/manta_trio
g=`grep $id $mantadat/../sample_groups.txt | cut -f1`
mantadir=$mantadat/sample_group$g/variants
mantaf=$mantadir/diploidSV.vcf.gz
bcftools view -s $id $mantaf | bgzip > $mantadir/$id"_diploid.vcf.gz"
mantaf=$mantadir/$id"_diploid.vcf.gz"

################################################
# Combine the results from the callers. 

if [ -s $mantaf -a -s $lumpyf ] 
then  
	cd $tmpdir
	echo -e "#chrom\tstart\tend\tid\tscore\tstrand\tlumpy_inf\tmanta_inf" > myheader
	$sdir/lumpy_to_bedpe.sh $lumpyf bed > lumpy.bed
	$sdir/merge_bedbks.sh lumpy.bed > lumpym.bed
	$sdir/manta_to_bedpe.sh $mantaf bed > manta.bed 
	$sdir/merge_bedbks.sh manta.bed > mantam.bed
	$sdir/combine_bedbk_files.sh lumpym.bed mantam.bed lumpy_manta.bed
	if [ -s $gridssf ]
	then 
		$sdir/gridss_to_bedpe.sh $gridssf bed > gridss.bed 
		$sdir/merge_bedbks.sh gridss.bed > gridssm.bed
		$sdir/combine_bedbk_files.sh gridssm.bed lumpy_manta.bed lumpy_manta_gridss.bed 
		echo -e "gridss_inf" | paste myheader - > tmph
		mv tmph myheader
	fi
fi


###########################################
# Put the header on the final file  
if [ -s lumpy_manta_gridss.bed ]
then 
	bed=lumpy_manta_gridss.bed
elif [ -s lumpy_manta.bed ]
then 
	bed=lumpy_manta.bed
fi 
bedname=`basename $bed .bed`
cat myheader $bedname.bed > $outdir/$bedname.bed

###########################################
# Add in 1K Genomes data

# $sdir/combine_svbedpe_with1kg.sh $bed $bedname.1kg.bed bed
# echo -e "OneKG" | paste myheader - > tmph 
# cat tmph $bedname.1kg.bed > $outdir/$bedname.1kg.bed

