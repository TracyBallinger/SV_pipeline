# Run this via: 
# qsub -v SAMPLES=samples.txt -v OUTDIR=outdir combine_sv_samples.sh 

#!/bin/bash
#$ -cwd
#$ -w w 
#$ -j y
#$ -S /bin/sh
#$ -N combsamp
# $ -pe sharedmem 2
#$ -l h_vmem=5G
#$ -l h_rt=00:30:00
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916

scriptdir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/scripts
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
bedpe1=$combdat/$id1/lumpy_manta_gridss*.bedpe

for ((i=1; i < ${#samples[@]}; i++));
do 
	bam2=${samples[$i]}
	id2=`basename $bam2 .bam`
	bedpe2=$combdat/$id2/lumpy_manta_gridss*.bedpe
	$sdir/combine_bedpe_files.sh $bedpe1 $bedpe2
	c2=`head -1 $bedpe1 | awk -F"\t" '{print NF}'`
	pairToPair -type both -is -slop $slop \
		-a $bedpe1 -b $bedpe2 | sort -u > both.$i.bedpe
	x=`wc -l both.$i.bedpe`
	echo "both.bedpe has $x entries"
	python $scriptdir/merge_pairToPair.py -c $c2 both.$i.bedpe > merged.$i.bedpe 
	x=`wc -l merged.$i.bedpe`
	echo "merged.bedpe has $x entries"
	myNF=`head -1 merged.$i.bedpe | awk -F"\t" '{print NF}'`
	# want to get the pairs that don't match
	cut -f1-$c2 both.$i.bedpe | sort -u | cat $bedpe1 - | sort | uniq -u > uniq1.$i.bedpe
	cat uniq1.$i.bedpe | awk 'BEGIN{OFS="\t"}{c=".:./.:.:.:."; for (i=1; i< (myNF-NF); i++) {c=c"\t.:./.:.:.:."} print $0"\t"c}' myNF=$myNF > uniq1c.$i.bedpe 
	c3=$((c2 + 1))
	cut -f$c3- both.$i.bedpe | sort -u | cat $bedpe2 - | sort | uniq -u > uniq2.$i.bedpe
	cat uniq2.$i.bedpe | awk 'BEGIN{OFS="\t"}{c=".:./.:.:.:."; for (i=1; i< (myNF-NF); i++) {c=c"\t.:./.:.:.:."} print c}' myNF=$myNF > tmpmid
	cut -f1-10 uniq2.$i.bedpe > tmpfirst
	cut -f11- uniq2.$i.bedpe | paste tmpfirst tmpmid - > uniq2c.$i.bedpe
	cat merged.$i.bedpe uniq1c.$i.bedpe uniq2c.$i.bedpe > calls.$i.bedpe
	bedpe1=calls.$i.bedpe
done 
echo "i is $i" 
mv $bedpe1 $outdir/merged_calls.bedpe

