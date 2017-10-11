#!/bin/bash 

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

samplelist=testids.txt
sampleids=(`cat $samplelist`)
datadir=/exports/igmm/eddie/EyeMalform/X00013WK/sv/lumpy

for i in ${!sampleids[*]}; 
do 
	aid=${sampleids[$i]}
	acalls=$datadir/$aid.vcf
	for (( j=$[$i+1]; j<${#sampleids[@]}; j++ ));
	do
		bid=${sampleids[$j]}
		bcalls=$datadir/$bid.vcf
		bcftools query -f '%CHROM\t%POS\t%INFO/END\t%ID\t%INFO/SU\t%INFO/SVTYPE\t%INFO/CIPOS\t%INFO/CIEND\n' $acalls \
		| awk 'BEGIN{OFS="\t"}{if ($3==".") $3=$2+1; print $0}' \
		| bedtools sort > a.bed
	
		bcftools query -f '%CHROM\t%POS\t%INFO/END\t%ID\t%INFO/SU\t%INFO/SVTYPE\t%INFO/CIPOS\t%INFO/CIEND\n' $bcalls \
		| awk 'BEGIN{OFS="\t"}{if ($3==".") $3=$2+1; print $0}' \
		| bedtools sort > b.bed

		stats=`get_bed_stats a.bed b.bed`
		echo -e "$aid	$bid	$acalls  $bcalls   $stats"
	done 
done

	
