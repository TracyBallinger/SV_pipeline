import argparse 
import sys

# Written by Tracy Ballinger, tracy.ballinger@igmm.ed.ac.uk 
# last edit: 
class bedpe: 
	def __init__(self, l): 
		fields=l.strip().split()
		self.chr1=fields[0]
		self.start1=int(fields[1])
		self.end1=int(fields[2])
		self.chr2=fields[3]
		self.start2=int(fields[4])
		self.end2=int(fields[5])
		self.ID=fields[6]
		self.score=float(fields[7])
		self.str1=fields[8] 
		self.str2=fields[9] 
		self.info="\t".join(fields[10:len(fields)])

def get_infodat(filein, genotype=False, ): 
	for l in filein:
		bedpeA=bedpe(l)
		newinfo=()
		for f in bedpeA.info.split():
			d=get_sv_type(f)
			newinfo.append(sv)
	return "\t".join(newinfo)

def get_svtype(info): 
	dat=info.split(":")
	return dat[0]

def get_filter(info):
	return info.split(":")[2]

def get_genotype(info):
	return info.split(":")[1]

def get_altreads(info):
	prcnts=info.split(":")[3].split(",")
	if len(prcnts)==2:
		pralt=prcnts[1]
		prref=prcnts[0]
	else: 
		pralt=0
		if (prcnts[0] != "."): pralt=prcnts[0]
		prref=-1
	srcnts=str(info.split(":")[4]).split(",")
	if len(srcnts)==2:
		sralt=srcnts[1]
		srref=srcnts[0]
	else: 
		sralt=0
		if (srcnts[0] != "."): sralt=srcnts[0]
		srref=-1
	return [int(pralt) + int(sralt), int(srref) + int(prref)]


def main(): 
	parser = argparse.ArgumentParser(description= 'reformats the output from pairToPair (bedpe files) to create merged intervals.  If both ends of the bedpe overlap, it takes the largest window of the merge.  If only one end of the bedpe overlaps in the two files, it creates 3 outputs- one for the merged end with a dummy chromosome (chrD) for the second chromosome, and one for each of the separate intervals.') 
	parser.add_argument('filein',type=argparse.FileType('r'),  help='input file (the output from a bedtools pairToPair call).')
	parser.add_argument('-t','--svtype',  action='store_true',help='get the SV type from each data column') 
	parser.add_argument('-g','--genotype',  action='store_true',help='get the genotypes from each data column') 
	parser.add_argument('-f','--filter',  action='store_true',help='get the filter status from each data column') 
	parser.add_argument('-a','--altreads',  action='store_true',help='get the number of reads supporting the alt (SV), which is the number of split reads plus the number of discordant reads spanning the break.') 
	parser.add_argument('-r','--refreads',  action='store_true',help='get the number of reads supporting the reference sequence (no SV)')
	args=parser.parse_args()
	
	for l in args.filein:
		#sys.stderr.write(l)
		bedpeA=bedpe(l)
		newinfo=[]
		for f in bedpeA.info.split():		
			if args.svtype:
				d=get_svtype(f)
			elif args.genotype: 
				d=get_genotype(f)
			elif args.filter: 
				d=get_filter(f)
			elif args.altreads: 
				d=get_altreads(f)
				d=d[0]
			elif args.refreads: 
				d=get_altreads(f)
				d=d[1]
			newinfo.append(d)
		#sys.stderr.write("newinfo is %s\n" % str(newinfo)) 
		sys.stdout.write("\t".join(map(str, newinfo))+"\n")
	
if __name__ == '__main__': 
	main()

