#!/bin/bash 

#$ -N clovebedpe 
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

clovevcf=$1
output=$2
format=$3

function clove_to_bedpe {
	vcf=$1
	vcfname=`basename $vcf .vcf.gz`
	# the clove vcf header has an error in it!  
	gzip -dc $vcf | grep ^"#" | sed 's/START>/START/' > tmph
	gzip -dc $vcf | grep -v ^"#" \
	| awk -F"\t" 'BEGIN{OFS="\t"}{
		n=split($8, a, ";"); info="";  
		for(i=1; i<=n; i++) if (a[i] ~ /=/) info=info";"a[i]; 
		$8=substr(info, 2); 
	print $0}' \
	| cat tmph - > $vcfname.fix.vcf 
	bcftools query -f '%CHROM\t%POS\t%INFO/CHR2\t%INFO/END\t%ID\t%QUAL\t%INFO/SVTYPE\t%FILTER\t%INFO/SUPPORT\t%INFO/ADP\n' $vcfname.fix.vcf \
	| awk 'BEGIN{OFS="\t"}{
		s1=$2-1; e1=$2; 
		s2=$4-1; e2=$4;
		print $1"\t"s1"\t"e1"\t"$3"\t"s2"\t"e2"\t"$5"\t"$6"\t.\t.\t"$7":"$10":"$8":"$9}'
}

function clove_to_bed {
	vcf=$1
	gzip -dc $vcf | \
	bcftools query -f '%CHROM\t%POS\t%INFO/CHR2\t%INFO/END\t%ID\t%QUAL\t%INFO/SVTYPE\t%FILTER\t%INFO/SUPPORT\n' - \
	| awk 'BEGIN{OFS="\t"}{
		s1=$2-1; e1=$2; 
		s2=$4-1; e2=$4;
		print $1"\t"s1"\t"e1"\t"$5"|"$7":.:"$8":"$9"\t"$6"\t.\n"$3"\t"s2"\t"e2"\t"$5"|"$7":.:"$8":"$9"\t"$6"\t.\t"$7}'
}


if [ "$format" == "bedpe" ]; then 
	clove_to_bedpe $clovevcf > $output
elif [ "$format" == "bed" ]; then 
	clove_to_bed $clovevcf > $output
fi 
