#!/bin/bash 

# Run this via the following: 
# qsub -t SU compare_lumpy_calls.sh
# SU is the cutoff for the read coverage for a break 

#$ -N cmplumpy 
#$ -cwd
#$ -j y 
#$ -l h_rt=24:00:00
#$ -l h_vmem=1G
#$ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

unset MODULEPATH
. /etc/profile.d/modules.sh
# You really just need bedtools, but bedtools is in bcbio
module load igmm/apps/bcbio/20160916
# module load igmm/apps/python/2.7.10

function get_bed_stats {
    abed=$1
    bbed=$2
    atot=(`awk 'BEGIN{tot=0; cnt=0}{tot +=($3-$2+1); cnt++}END{print cnt"\t"tot}' $abed`)
    btot=(`awk 'BEGIN{tot=0; cnt=0}{tot +=($3-$2+1); cnt++}END{print cnt"\t"tot}' $bbed`)
    jstats=`bedtools jaccard -a $abed -b $bbed | sed 1d`
    aintcnt=`bedtools intersect -u -a $abed -b $bbed | wc -l`
    bintcnt=`bedtools intersect -u -a $bbed -b $abed | wc -l`
    avcnt=`bedtools intersect -v -a $abed -b $bbed | wc -l`
    bvcnt=`bedtools intersect -v -a $bbed -b $abed | wc -l`
    echo -e "${atot[0]} ${btot[0]}  ${atot[1]}  ${btot[1]}  $jstats $aintcnt    $bintcnt    $avcnt  $bvcnt"
}

function lumpy_to_bed {
	acalls=$1
	bcftools query -f '%CHROM\t%POS\t%INFO/END\t%ID\t%INFO/SU\t%INFO/SVTYPE\t%INFO/CIPOS\t%INFO/CIEND\n' $acalls \
	| awk 'BEGIN{OFS="\t"}{if ($3==".") $3=$2+1; print $0}' \
	| bedtools sort 
}
	

samplelist=sampleids.txt
sampleids=(`cat $samplelist`)
datadir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/lumpy
SU=$SGE_TASK_ID
outputfile=lumpy_compare.$SU.stats

for i in ${!sampleids[*]}; 
do 
	aid=${sampleids[$i]}
	acalls=$datadir/$aid.vcf
	for (( j=$[$i+1]; j<${#sampleids[@]}; j++ ));
	do
		bid=${sampleids[$j]}
		bcalls=$datadir/$bid.vcf
		for t in BND DEL DUP INV; 
		do 
			lumpy_to_bed $acalls | awk '$5>SU' SU=$SU | grep $t > a.bed 
			lumpy_to_bed $bcalls | awk '$5>SU' SU=$SU | grep $t > b.bed 
			stats=`get_bed_stats a.bed b.bed`
			echo -e "$aid	$bid	$t	$stats" >> $outputfile
		done
	done 
done

	
