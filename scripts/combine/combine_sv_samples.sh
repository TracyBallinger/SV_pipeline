# Run this via: 
# qsub -v SAMPLES=samples.txt -v OUTDIR=outdir combine_sv_samples.sh 

#!/bin/bash
#$ -cwd
#$ -w w 
#$ -j y
#$ -S /bin/sh
#$ -N combsamp
# $ -pe sharedmem 2
#$ -l h_vmem=8G
#$ -l h_rt=00:30:00
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916

sdir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts/combine
combdat=/exports/igmm/eddie/EyeMalform/X00013WK/sv/combined_sv
slop=0

#########################################################
# Make the output directory and save the full path name. 
samples=(`cat $SAMPLES`)
outdir=$OUTDIR
outfpath=`readlink -f $outdir`
outpath=`dirname $outfpath`
outname=`basename $outdir`
outdir=$outpath/$outname
mkdir -p $outdir
cp $SAMPLES $outdir/samplelist.txt  

########################################
# Make a tmpdir for doing the work in 
tmpdir=/home/tballing/scratch/combine_sv
mkdir -p $tmpdir
tmpdir=$tmpdir/$outname
mkdir -p $tmpdir

########################################
# Do the work in the tmpdir
cd $tmpdir

bam1=${samples[0]}
id1=`basename $bam1 .bam`
bedpe1=$combdat/$id1/lumpy_manta_gridss.bedpe
bed1=$combdat/$id1/lumpy_manta_gridss.bed
bedheader=`head -1 $bed1 | cut -f1-6`
bednames=`head -1 $bed1 | cut -f7- | sed 's/\t/_'$i'\t/g'`

bedpeheader=`head -1 $bedpe1 | cut -f1-10`
bedpenames=`head -1 $bedpe1 | cut -f7- | sed 's/\t/_'$i'\t/g'`

for ((i=1; i < ${#samples[@]}; i++));
do 
	bam2=${samples[$i]}
	id2=`basename $bam2 .bam`

	bedpe2=$combdat/$id2/lumpy_manta_gridss.bedpe
	$sdir/combine_bedpe_files.sh $bedpe1 $bedpe2 calls.$i.bedpe
	bedpenames="$bedpenames `head -1 $bedpe2 | cut -f11- | sed 's/\t/_'$i'\t/g'`"
	bedpe1=calls.$i.bedpe
	
	bed2=$combdat/$id2/lumpy_manta_gridss.bed
	$sdir/combine_bedbk_files.sh $bed1 $bed2 calls.$i.bed
	bednames="$bednames `head -1 $bed2 | cut -f7- | sed 's/\t/_'$i'\t/g'`"
	bed1=calls.$i.bed

done 

###########################################
# Add in 1K Genomes data
bedpename=`basename $bedpe1 .bedpe`
echo "$sdir/combine_svbedpe_with1kg.sh $bedpe1 $bedpename.1kg.bedpe bedpe"
$sdir/combine_svbedpe_with1kg.sh $bedpe1 $bedpename.1kg.bedpe bedpe
bedname=`basename $bed1 .bed`
echo "$sdir/combine_svbedpe_with1kg.sh $bed1 $bedname.1kg.bed bed"
$sdir/combine_svbedpe_with1kg.sh $bed1 $bedname.1kg.bed bed

echo "$bedpeheader $bedpenames OneKG" | tr ' ' '\t' | cat - $bedpe1 > $outdir/merged_calls.bedpe
echo "$bedheader $bednames OneKG" | tr ' ' '\t' | cat - $bed1 > $outdir/merged_calls.bed



