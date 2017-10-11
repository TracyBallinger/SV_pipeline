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

lumpyvcf=$1
format=$2
# output=$2

# Note that Lumpy seems to only detect interchromosomal structural variants, so intrachromosomal SVs aren't there.  The second chromosome is always the same as the first. 

function lumpy_to_bedpe {
	lumpyvcf=$1
	gzip -dc $lumpyvcf |\
	bcftools query -f '%CHROM\t%POS\t%INFO/CIPOS\t%ALT\t%INFO/END\t%INFO/CIEND\t%ID\t%QUAL\t%INFO/STRANDS\t.\t%INFO/SVTYPE:[%GT:.:%PE:%SR\t]\n' - \
	| awk 'BEGIN{OFS="\t"}{
		split($3, a, ","); s1=$2+a[1]-1; e1=$2+a[2];
		split($6, b, ","); s2=$5+b[1]-1; e2=$5+b[2];
		split($9, c, ""); str1=c[1]; str2=c[2];
		split($4, c, "[][]"); 
            if(length(c)>1) {
                n=split(c[2], d, ":"); 
                s2=d[n]+b[1]-1; e2=d[n]+b[2];
				chrom2=d[1]; for (i=2; i<n; i++){chrom2=chrom2":"d[i]}}
            else chrom2=$1;
		split($11, d, ":"); pr=d[3]; sr=d[4]; su=pr+sr; 
		s1 = (s1 < 0 ? 0 : s1);
		s2 = (s2 < 0 ? 0 : s2);
        e1 = (e1 < 0 ? 0 : e1);
        e2 = (e2 < 0 ? 0 : e2);
			$2=s1; $3=e1;
			$5=s2; $6=e2;
			$9=str1; $10=str2;
			$8=su; $4=chrom2;
			$7="LUMPY:"$7; 
		print $0}' | \
	grep -v "_2"
}


function lumpy_to_bed { 
	lumpyvcf=$1
	gzip -dc $lumpyvcf | \
	bcftools query -f '%CHROM\t%POS\t%INFO/CIPOS\t%ID\t%QUAL\t%INFO/STRANDS\t%INFO/SVTYPE:[%GT:.:%PE:%SR\t]\n' - \
	| awk 'BEGIN{OFS="\t"; FS="\t"}{
        split($3, a, ","); s1=$2+a[1]-1; e1=$2+a[2];
        split($6, c, ""); str1=c[1]; str2=c[2];
        split($7, d, ":"); pr=d[3]; sr=d[4]; su=pr+sr; 
        id="LUMPY:"$4; 
		s1 = (s1 < 0 ? 0 : s1);
        e1 = (e1 < 0 ? 0 : e1);
		print $1,s1,e1,id,su,str1,$7}'
}

if [ "$format" == "bedpe" ]; then 
	lumpy_to_bedpe $lumpyvcf 
elif [ "$format" == "bed" ]; then 
	lumpy_to_bed $lumpyvcf 
fi


