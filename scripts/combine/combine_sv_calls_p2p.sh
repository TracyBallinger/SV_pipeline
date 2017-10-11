# Run this via: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt -v OUTDIR=outdir combine_sv_calls_p2p.sh 
# The outdir must exist already. 

#!/bin/bash
#$ -cwd
#$ -w w 
#$ -j y
#$ -S /bin/sh
#$ -N pair2pair
# $ -pe sharedmem 2
#$ -l h_vmem=7G
#$ -l h_rt=00:30:00
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916

slop=0
sdir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts/combine

#################################################
# set the output directory and tmp directory 
# for intermediate files. 
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
g=`grep $id sample_groups.txt | cut -f1`
mantadir=$mantadat/sample_group$g/variants
mantaf=$mantadir/diploidSV.vcf.gz
bcftools view -s $id $mantaf | bgzip > $mantadir/$id"_diploid.vcf.gz"
mantaf=$mantadir/$id"_diploid.vcf.gz"

####################################################
# Merge the results together 
if [ -s $mantaf -a -s $lumpyf ] 
then  
	cd $tmpdir
	echo -e "#chrom1\tstart1\tend1\tchrom2\tstart2\tend2\tid\tscore\tstr1\tstr2\tlumpy_inf\tmanta_inf" > myheader
	$sdir/lumpy_to_bedpe.sh $lumpyf lumpy.bedpe bedpe
	$sdir/manta_to_bedpe.sh $mantaf manta.bedpe bedpe
	$sdir/combine_bedpe_files.sh lumpy.bedpe manta.bedpe lumpy_manta.bedpe
	if [ -s $gridssf ] 
	then 
		$sdir/gridss_to_bedpe.sh $gridssf gridss.bedpe bedpe
		$sdir/combine_bedpe_files.sh gridss.bedpe lumpy_manta.bedpe lumpy_manta_gridss.bedpe 
		echo -e "gridss_inf" | paste myheader - > tmph 
		mv tmph myheader 
	fi
fi
###########################################
# Add the header to the final results 
# and copy to output directory  
if [ -s lumpy_manta_gridss.bedpe ]
then 
	bedpe=lumpy_manta_gridss.bedpe
elif [ -s lumpy_manta.bedpe ]
then 
	bedpe=lumpy_manta.bedpe
fi 
bedpename=`basename $bedpe .bedpe`
cat myheader $bedpename.bedpe > $outdir/$bedpename.bedpe
 
###########################################
# Add in 1K Genomes data
# $sdir/combine_svbedpe_with1kg.sh $bedpe $bedpename.1kg.bedpe bedpe
# echo -e "OneKG" | paste myheader - > tmph 
# cat tmph $bedpename.1kg.bedpe > $outdir/$bedpename.1kg.bedpe 

