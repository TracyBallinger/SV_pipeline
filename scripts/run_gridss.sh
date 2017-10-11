# Run this via: 
# qsub -t 1-n -tc x -v SAMPLES=samples.txt -v OUTDIR=outdir run_gridss.sh 

#!/bin/bash

#$ -cwd 
#$ -w w 
#$ -j y 
#$ -S /bin/sh
#$ -N gridss
#$ -pe sharedmem 8 
#$ -l h_vmem=10G 
#$ -l h_rt=96:00:00
# $ -o /exports/eddie/scratch/tballing/errorlogs/$JOB_NAME.o$JOB_ID.$TASK_ID

# ulimit -n 2000
# Load the bcbio module 
unset MODULEPATH
. /etc/profile.d/modules.sh
module load igmm/apps/bcbio/20160916
module load java/jdk/1.8.0
module load R 

GRIDSS_JAR=/exports/igmm/eddie/NextGenResources/software/gridss/gridss-1.4.2-jar-with-dependencies.jar
TMPDIR=/exports/eddie/scratch/tballing/gridss
mkdir -p $TMPDIR

line=`sed -n "$SGE_TASK_ID"p $SAMPLES`
set $line
bamfile=$1
id=`basename $bamfile .bam`
tempdir=$TMPDIR/$id
mkdir -p $tempdir
outdir=$OUTDIR/$id
mkdir -p $outdir 

INPUT=$bamfile
BLACKLIST=/exports/igmm/eddie/NextGenResources/annotation/hg38/hg38.blacklist.bed
REFERENCE=/exports/igmm/software/pkg/el7/apps/bcbio/share2/genomes/Hsapiens/hg38/bwa/hg38.fa
OUTPUT=$outdir/$id.sv.vcf
ASSEMBLY=$outdir/$id.gridss.assembly.bam

if [[ ! -f "$INPUT" ]] ; then
	echo "Missing $INPUT input file."
	exit 1
fi
if ! which bwa >/dev/null 2>&1 ; then
	echo "Missing bwa. Please add to PATH"
	exit 1
fi
if [[ ! -f "$REFERENCE" ]] ; then
	echo "Missing reference genome $REFERENCE." 
	exit 1
fi
if [[ ! -f "$REFERENCE.bwt" ]] ; then
	echo "Missing bwa index for $REFERENCE. Could not find $REFERENCE.bwt. Create a bwa index (using \"bwa index $REFERENCE\") or symlink the index files to the expected file names."
	exit 1
fi
if [[ ! -f $GRIDSS_JAR ]] ; then
	echo "Missing $GRIDSS_JAR. Update the GRIDSS_JAR variable in the shell script to your location"
	exit 1
fi
if ! which java >/dev/null 2>&1 ; then
	echo "Missing java. Please add java 1.8 or later to PATH"
	exit 1
fi
JAVA_VERSION="$(java -version 2>&1 | head -1)"
if [[ ! "$JAVA_VERSION" =~ "\"1.8" ]] ; then
	echo "Detected $JAVA_VERSION. GRIDSS requires Java 1.8 or later."
	exit 1
fi

java -ea -Xmx31g \
	-Dsamjdk.create_index=true \
	-Dsamjdk.use_async_io_read_samtools=true \
	-Dsamjdk.use_async_io_write_samtools=true \
	-Dsamjdk.use_async_io_write_tribble=true \
	-Dsamjdk.compression_level=1 \
	-cp $GRIDSS_JAR gridss.CallVariants \
	WORKER_THREADS=8 \
	TMP_DIR=$tempdir \
	WORKING_DIR=$tempdir \
	REFERENCE_SEQUENCE="$REFERENCE" \
	INPUT="$INPUT" \
	OUTPUT="$OUTPUT" \
	ASSEMBLY="$ASSEMBLY" \
	BLACKLIST="$BLACKLIST" \
	2>&1 | tee -a gridss.$HOSTNAME.$$.log

