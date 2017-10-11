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

gridssvcf=$1
format=$2

function gridss_to_bedpe {
	vcf=$1
	cat $vcf \
	| bcftools query -f '%ID\t%CHROM\t%POS\t%INFO/CIPOS\t%ALT\t%INFO/END\t%INFO/CIEND\t%INFO/EVENT\t%QUAL\t.\t.\t%INFO/SVTYPE:[%GT:%FILTER:%ASRP:%ASSR]\n' - \
	| awk '$1 ~ /o$/' | cut -f2- \
	| awk 'BEGIN{OFS="\t"; FS="\t"}{
		split($3, a, ","); s1=$2+a[1]-1; e1=$2+a[2]; 
		split($6, b, ","); s2=$5+b[1]-1; e2=$5+b[2];
		split($4, c, "[][]"); 
			if(length(c)>1) {
				n=split(c[2], d, ":"); 
				s2=d[n]-1+b[1]; e2=d[n]+b[2];
				chrom2=d[1]; for(i=2; i<n; i++){chrom2=chrom2":"d[i]}}
			else chrom2=$1;
		split($11, e, ":"); pr=e[3]; sr=e[4]; su=pr+sr; 
		s1 = (s1 < 0 ? 0 : s1);
		s2 = (s2 < 0 ? 0 : s2);
		e1 = (e1 < 0 ? 0 : e1);
		e2 = (e2 < 0 ? 0 : e2);
		$2=s1; $3=e1;
		$5=s2; $6=e2;
		$4=chrom2;
		$8=su; 
		print $0}'
}


function gridss_to_bed {
	vcf=$1
	cat $vcf \
	| bcftools query -f '%CHROM\t%POS\t%ID\t%INFO/SVTYPE\t[%GT:%FILTER:%REFPAIR,%BUM:%REF,%BSC]\n' - \
	| awk 'BEGIN{OFS="\t"; FS="\t"}{
		split($5, e, ":");
		split(e[3], f, ","); 
			if (length(f) >1){refpr=f[1]; altpr=f[2]}
			else {refpr=0; altpr=0}; 
        split(e[4], g, ",");
            if (length(g)>1) {refsr=g[1]; altsr=g[2]}
            else {refsr=0; altsr=0};
        score=altpr+altsr; 
        print $1"\t"$2-1"\t"$2"\t"$3"\t"score"\t.\t"$4":"$5}' \
    | sort -u
}

if [ "$format" == "bedpe" ]; then 
	gridss_to_bedpe $gridssvcf 
elif [ "$format" == "bed" ]; then 
	gridss_to_bed $gridssvcf 
fi 
