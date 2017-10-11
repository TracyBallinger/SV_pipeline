
# Run this via the following: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt run_lumpy.sh

#$ -N lumpy 
#$ -cwd
#$ -j y 
#$ -l h_rt=24:00:00
#$ -l h_vmem=3G
#$ -pe sharedmem 2 
#$ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID 

unset MODULEPATH
. /etc/profile.d/modules.sh 
module load igmm/apps/bcbio/20160916
module load igmm/apps/python/2.7.10

lumpydir=/exports/igmm/software/pkg/el7/apps/bcbio/share2/anaconda/pkgs/lumpy-sv-0.2.12-py27_3/share/lumpy-sv-0.2.12-3
TMPDIR=/exports/eddie/scratch/tballing/EyeMalform/lumpy
OUTDIR=/exports/eddie/scratch/tballing/EyeMalform/lumpy

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line 
bamfile=$1
id=`basename $bamfile .bam`
samtools view -b -F 1294 $bamfile > $TMPDIR/$id.disc.unsort.bam
samtools view -h $bamfile \
	| $lumpydir/scripts/extractSplitReads_BwaMem -i stdin \
	| samtools view -Sb - \
	> $TMPDIR/$id.split.unsort.bam 

# Sort the alignments
discbam=$OUTDIR/$id.disc.bam
splitbam=$OUTDIR/$id.split.bam
samtools sort -@ 2 -o $discbam $TMPDIR/$id.disc.unsort.bam 
samtools sort -@ 2 -o $splitbam $TMPDIR/$id.split.unsort.bam 

histofile=$OUTDIR/$id.histo
#lumpyexpress -B $bamfile -S $splitbam -D $discbam -o $OUTDIR/$id.vcf
readlen=101
x=`samtools view -s 34.01 $bamfile | $lumpydir/scripts/pairend_distro.py -r $readlen -X 4 -N 1000 -o $histofile`
mean=`echo $x | awk '{print $1}' | sed 's/mean://'`
stdev=`echo $x | awk '{print $2}' | sed 's/stdev://'`

echo "mean: $mean, stdev: $stdev"
echo -e "lumpy \
	-mw 4 \
	-tt 0 \
	-pe id:$id,bam_file:$discbam,histo_file:$histofile,mean:$mean,stdev:$stdev,read_length:$readlen,min_non_overlap:$readlen,discordant_z:5,back_distance:10,weight:1,min_mapping_threshold:20 \
	-sr id:$id,bam_file:$splitbam,back_distance:10,weight:1,min_mapping_threshold:20 \
	> $OUTDIR/$id.vcf
"
lumpy \
	-mw 4 \
	-tt 0 \
	-pe id:$id,bam_file:$discbam,histo_file:$histofile,mean:$mean,stdev:$stdev,read_length:$readlen,min_non_overlap:$readlen,discordant_z:5,back_distance:10,weight:1,min_mapping_threshold:20 \
	-sr id:$id,bam_file:$splitbam,back_distance:10,weight:1,min_mapping_threshold:20 \
	> $OUTDIR/$id.vcf


