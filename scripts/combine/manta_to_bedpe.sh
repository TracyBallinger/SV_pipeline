#!/bin/bash 

# SU is the cutoff for the read coverage for a break 

#$ -N  
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

mantavcf=$1
format=$2
#output=$3

#############################################
# For manta, some SV are listed twice, once for each breakend
# Some SV in manta only have one breakend, and 
# are only listed once.  

function manta_to_bedpe {
	mantavcf=$1
	gzip -dc $mantavcf | \
	grep MATEID |  sort -k3,3 | paste - - | cut -f1-10,18 | \
	awk 'BEGIN{OFS="\t"}{
		match($11, /CIPOS=[-0-9,]+/); cipos=substr($11, RSTART+6, RLENGTH-6); 
		$8=$8";CIEND="cipos; print $0}' \
	| cut -f1-10 > tmp.mantape.$TASK_ID
	
	gzip -dc $mantavcf | grep -v MATEID | cat - tmp.mantape.$TASK_ID | \
	bcftools query -f '%CHROM\t%POS\t%INFO/CIPOS\t%ALT\t%INFO/END\t%INFO/CIEND\t%ID\t%QUAL\t.\t.\t%INFO/SVTYPE:[%GT:%FT:%PR:%SR\t]\n' - \
	| awk 'BEGIN{OFS="\t"}{
		split($3, a, ","); s1=$2+a[1]-1; e1=$2+a[2]; 
		split($6, b, ","); s2=$5+b[1]-1; e2=$5+b[2];
		split($4, c, "[][]"); 
			if(length(c)>1) {
				n=split(c[2], d, ":"); 
				s2=d[n]-1+b[1]; e2=d[n]+b[2];
				chrom2=d[1]; for(i=2; i<n; i++){chrom2=chrom2":"d[i]}}
			else chrom2=$1;
		split($11, e, ":"); 
			split(e[4], f, ","); 
			if (length(f)>1) {refpr=f[1]; altpr=f[2]}
			else {refpr=0; altpr=0}; 
			split(e[5], g, ","); 
			if (length(g)>1) {refsr=g[1]; altsr=g[2]}
			else {refsr=0; altsr=0};
		s1 = (s1 < 0 ? 0 : s1);
		s2 = (s2 < 0 ? 0 : s2);
		e1 = (e1 < 0 ? 0 : e1);
		e2 = (e2 < 0 ? 0 : e2);
		$2=s1; $3=e1;
		$5=s2; $6=e2;
		$4=chrom2;
		$8=altpr + altsr; 
		print $0}'
}


function manta_to_bed {
	mantavcf=$1
	gzip -dc $mantavcf | \
	bcftools query -f '%CHROM\t%POS\t%INFO/CIPOS\t%ID\t%INFO/SVTYPE:[%GT:%FT:%PR:%SR\t]\n' - \
	| awk 'BEGIN{OFS="\t"}{
        split($3, a, ","); s1=$2+a[1]-1; e1=$2+a[2]; 
		split($5, e, ":"); 
        split(e[4], f, ","); 
			if (length(f)>1) {refpr=f[1]; altpr=f[2]}
            else {refpr=0; altpr=0}; 
        split(e[5], g, ","); 
			if (length(g)>1) {refsr=g[1]; altsr=g[2]}
            else {refsr=0; altsr=0};  
        chrom1=$1;
		score=altpr+altsr; 
		s1 = (s1 < 0 ? 0 : s1);
		e1 = (e1 < 0 ? 0 : e1);
		id=$4;
		print chrom1"\t"s1"\t"e1"\t"id"\t"score"\t.\t"$5}' \
	| sort -u
}

if [ "$format" == "bedpe" ]; then 
	manta_to_bedpe $mantavcf 
elif [ "$format" == "bed" ]; then 
	manta_to_bed $mantavcf
fi 
