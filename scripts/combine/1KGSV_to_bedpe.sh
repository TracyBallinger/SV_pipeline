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

vcf=/home/tballing/NextGenResources/annotation/variants/dbVar/1000Genomes_SV.GRCh38.variant_region.germline.vcf 
output=1000Genomes_SV.GRCh38.variant_region.germline.bedpe
format=bed

# Note that Lumpy seems to only detect interchromosomal structural variants, so intrachromosomal SVs aren't there.  The second chromosome is always the same as the first. 

function KGSV_to_bedpe {
	vcf=$1
	gzip -dc $vcf |\
	bcftools query -f '%CHROM\t%POS\t%INFO/CIPOS\t%ALT\t%INFO/END\t%INFO/CIEND\t%ID\t%QUAL\t.\t.\t%INFO/SVTYPE\n' - \
	| awk 'BEGIN{OFS="\t"}{
		split($3, a, ","); 
			if (length(a) >1) {s1=$2+a[1]-1; e1=$2+a[2]}
			else {s1=$2-1; e1=$2}
		split($6, b, ","); 
			if (length(b) >1) {s2=$5+b[1]-1; e2=$5+b[2]}
			else {s2=$5-1; e2=$5}
		split($4, c, "[][]"); 
            if(length(c)>1) {
                split(c[2], d, ":"); 
                s2=d[2]+b[1]-1; e2=d[2]+b[2];
				chrom2=d[1]; for (i=2; i<n; i++){chrom2=chrom2":"d[i]}}
            else chrom2=$1;
			$2=s1; $3=e1;
			$5=s2; $6=e2;
			$4="chr"chrom2;
			$1="chr"$1;
		print $0}'
}

function KGSV_to_bed {
	vcf=$1
	gzip -dc $vcf |\
	bcftools query -f '%CHROM\t%POS\t%INFO/CIPOS\t%ALT\t%INFO/END\t%INFO/CIEND\t%ID\t%QUAL\t.\t.\t%INFO/SVTYPE\n' - \
	| awk 'BEGIN{OFS="\t"}{
		split($3, a, ","); 
			if (length(a) >1) {s1=$2+a[1]-1; e1=$2+a[2]}
			else {s1=$2-1; e1=$2}
		split($6, b, ","); 
			if (length(b) >1) {s2=$5+b[1]-1; e2=$5+b[2]}
			else {s2=$5-1; e2=$5}
		split($4, c, "[][]"); 
            if(length(c)>1) {
                split(c[2], d, ":"); 
                s2=d[2]+b[1]-1; e2=d[2]+b[2];
				chrom2=d[1]; for (i=2; i<n; i++){chrom2=chrom2":"d[i]}}
            else chrom2=$1;
			chrom1=$1; id=$7; str1="."; str2="."; su=$8; 
		print chrom1"\t"s1"\t"e1"\t"id"\t"su"\t"str1"\n"chrom2"\t"s2"\t"e2"\t"id"\t"su"\t"str2}'
}

if [ "$format" == "bedpe" ]; then 
	KGSV_to_bedpe $vcf > $output
elif [ "$format" == "bed" ]; then 
	KGSV_to_bed $vcf > $output
fi


