#!/bin/bash 

lumpyvcf=/home/tballing/scratch/EyeMalform/lumpy/4302_4302_R34F3.vcf.gz

mantavcf=/home/tballing/scratch/EyeMalform/manta/4302_4302_R34F3/results/variants/candidateSV.vcf.gz

bcftools query -f '%CHROM\t%POS\t%INFO/END\t%ID\t%INFO/SU\t%INFO/SVTYPE\t%INFO/CIPOS\t%INFO/CIEND\n' $lumpyvcf \
	| awk 'BEGIN{OFS="\t"}{if ($3==".") $3=$2+1; print $0}' \
	| bedtools sort > lumpy.bed

bcftools query -f '%CHROM\t%POS\t%INFO/END\t%ID\t%INFO/PAIR_COUNT\t%INFO/SVTYPE\t%INFO/CIPOS\t%INFO/CIEND\n' $mantavcf \
	| awk 'BEGIN{OFS="\t"}{if ($3==".") $3=$2+1; print $0}' \
	| bedtools sort  > manta.bed

bedtools closest -d -a lumpy.bed -b manta.bed > lumpy_manta.txt 



	
