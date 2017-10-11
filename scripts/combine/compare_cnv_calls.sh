#!/bin/bash 

module load igmm/apps/BEDTools/2.25.0
# This will generate data about how well two cnv calls match 
# cd freecout/full

function convert_to_bed {
    grep -v ^X | grep -v ^Y | sort -k1,1 -k2,2n \
    | awk '{split($10, a, ":"); split(a[2], b, "-"); \
    if (b[1] <b[2]) {s=b[1]; e=b[2]} \
    else {s=b[2]; e=b[1]}; \
    if (($4!=pval) || ($1 !=pchr)) {\
        print pchr"\t"pstart"\t"pend"\t"pval"\t"pcn"\t"pbaf"\t"pgeno;\
        pchr=$1; pstart=s; pend=e; pval=$4; pcn=$5; pbaf=$7; pgeno=$8}\
    else {pend=e}}\
    END{print pchr"\t"pstart"\t"pend"\t"pval"\t"pcn"\t"pbaf"\t"pgeno}' \
    | sed 1d
} 

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
    echo -e "${atot[0]}	${btot[0]}	${atot[1]}	${btot[1]}	$jstats	$aintcnt	$bintcnt	$avcnt	$bvcnt"
}
	
echo -e "A	B	svtype	Acnt	Bcnt	Abp	Bbp	intersection	union	jaccard	Ninter	Ainter	Binter	Auniq	Buniq"
Adirs=(H10_normal   tumour_normal   tumrline_normal   H10_normal      H10_normline	tumour_normal	tumour_normal	tumour_normline tumour_normline)
Bdirs=(H10_normline	tumour_normline tumrline_normline tumrline_normal tumrline_normline	H10_normal	tumrline_normal	H10_normline	tumrline_normline) 
for i in ${!Adirs[*]};
do
	dira=${Adirs[$i]}
	dirb=${Bdirs[$i]}
	acalls=$dira/*.gz_ratio.txt 
	bcalls=$dirb/*.gz_ratio.txt 

sed 1d $acalls | convert_to_bed - > a.bed 
sed 1d $bcalls | convert_to_bed - > b.bed 
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	all $stats"	

# Get the stats for the normal calls
sed 1d $acalls | awk '$5==2 && $7 != "AA"' | convert_to_bed - > a.bed  
sed 1d $bcalls | awk '$5==2 && $7 != "AA"' | convert_to_bed - > b.bed  
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	norm	$stats"	

# Get the stats for the abnormal calls
if [ 1 -eq 0 ]
then 
sed 1d $acalls | awk '$5!=2 || $7 != "AB"' | convert_to_bed - > a.bed   
sed 1d $bcalls | awk '$5!=2 || $7 != "AB"' | convert_to_bed - > b.bed  
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	abnormal	$stats"	
fi 

# Get the stats for the gains
sed 1d $acalls | awk '$5>2' | convert_to_bed - > a.bed 
sed 1d $bcalls | awk '$5>2' | convert_to_bed - > b.bed  
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	gain	$stats"	

# Get the stats for the losses
sed 1d $acalls | awk '$5<2' | convert_to_bed - > a.bed 
sed 1d $bcalls | awk '$5<2' | convert_to_bed - > b.bed   
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	loss	$stats"	

# Get the stats for the LOH 
#sed 1d $acalls | awk '$8 !~ /B/' | convert_to_bed - $space > a.bed 
#sed 1d $bcalls | awk '$8 !~ /B/' | convert_to_bed - $space > b.bed 
#stats=`get_bed_stats a.bed b.bed` 
#echo -e "$dira	$dirb	loh	$stats"	

# Get the stats for the CN-LOH 
sed 1d $acalls | awk '$5==2 && $7 !~ /B/ && $8 ~ /A/' | convert_to_bed - > a.bed 
sed 1d $bcalls | awk '$5==2 && $7 !~ /B/ && $8 ~ /A/' | convert_to_bed - > b.bed 
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	cnloh	$stats"	

# Get the stats for the gain+LOH 
#sed 1d $acalls | awk '$5>2 && $8 !~ /B/ && $8 ~ /A/' | convert_to_bed - $space > a.bed 
#sed 1d $bcalls | awk '$5>2 && $8 !~ /B/ && $8 ~ /A/' | convert_to_bed - $space > b.bed 
#stats=`get_bed_stats a.bed b.bed` 
#echo -e "$dira	$dirb	gainloh	$stats"	

# Get the stats for the large gains
if [ 1 -eq 0 ]
then 
sed 1d $acalls | awk '$5>2' | convert_to_bed - | awk 'BEGIN{OFS="\t"}{if (($3-$2+1) > 20000) print $0}' > a.bed 
sed 1d $bcalls | awk '$5>2' | convert_to_bed - | awk 'BEGIN{OFS="\t"}{if (($3-$2+1) > 20000) print $0}' > b.bed  
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	biggain	$stats"	
fi 

# Get the stats for the small gains
if [ 1 -eq 0 ]
then 
sed 1d $acalls | awk '$5>2' | convert_to_bed - | awk 'BEGIN{OFS="\t"}{if (($3-$2+1) <= 20000) print $0}' > a.bed 
sed 1d $bcalls | awk '$5>2' | convert_to_bed - | awk 'BEGIN{OFS="\t"}{if (($3-$2+1) <= 20000) print $0}' > b.bed  
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	smallgain	$stats"	
fi 

# Get the stats for the large losses 
if [ 1 -eq 0 ]
then 
sed 1d $acalls | awk '$5<2' | convert_to_bed - | awk 'BEGIN{OFS="\t"}{if (($3-$2+1) > 20000) print $0}' > a.bed 
sed 1d $bcalls | awk '$5<2' | convert_to_bed - | awk 'BEGIN{OFS="\t"}{if (($3-$2+1) > 20000) print $0}' > b.bed  
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	bigloss	$stats"	
fi 

# Get the stats for the small losses 
if [ 1 -eq 0 ]
then 
sed 1d $acalls | awk '$5<2' | convert_to_bed - | awk 'BEGIN{OFS="\t"}{if (($3-$2+1) <= 20000) print $0}' > a.bed 
sed 1d $bcalls | awk '$5<2' | convert_to_bed - | awk 'BEGIN{OFS="\t"}{if (($3-$2+1) <= 20000) print $0}' > b.bed  
stats=`get_bed_stats a.bed b.bed` 
echo -e "$dira	$dirb	smallloss	$stats"	
fi 

i=$[$i+1]

done 
