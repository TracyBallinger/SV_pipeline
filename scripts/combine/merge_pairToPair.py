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
		

class bed2peline:
	# here the c2 indicates the column where the second bedpe line starts, 
	# default is 11
	def __init__(self, l, c2=11):
		fields=l.strip().split('\t')
		#sys.stderr.write("\t".join(fields[0:c2])+"\n")
		#sys.stderr.write("\t".join(fields[c2:len(fields)]) + "\n")
		self.bedpeA=bedpe("\t".join(fields[0:c2]))
		self.bedpeB=bedpe("\t".join(fields[c2:len(fields)]))

def merge_bedpes(filein, c2=11):
	for l in filein: 
		bed2pe=bed2peline(l, c2)
		bedpeA=bed2pe.bedpeA
		bedpeB=bed2pe.bedpeB
		# make dummy variables for new coordinates to start
		(chr1new, s1new, e1new) = ("chrD", 0, 100) 
		(chr2new, s2new, e2new) = ("chrD", 0, 100) 
		if ((bedpeA.chr1 == bedpeB.chr1) and 
			(bedpeA.end1 > bedpeB.start1) and 
			(bedpeA.start1 < bedpeB.end1)):  
			chr1new=bedpeA.chr1
			s1new=min(bedpeA.start1, bedpeB.start1)
			e1new=max(bedpeA.end1, bedpeB.end1)
		if ((bedpeA.chr2 == bedpeB.chr2) and 
			(bedpeA.end2 > bedpeB.start2) and 
			(bedpeA.start2 < bedpeB.end2)): 
			chr2new=bedpeA.chr2
			s2new=min(bedpeA.start2, bedpeB.start2)
			e2new=max(bedpeA.end2, bedpeB.end2)
		if ((bedpeA.chr1 == bedpeB.chr2) and 
			(bedpeA.end1 > bedpeB.start2) and 
			(bedpeA.start1 < bedpeB.end2)): 
			chr1new=bedpeA.chr1
			s1new=min(bedpeA.start1, bedpeB.start2)
			e1new=max(bedpeA.end1, bedpeB.end2)
		if ((bedpeA.chr2 == bedpeB.chr1) and 
			(bedpeA.end2 > bedpeB.start1) and 
			(bedpeA.start2 < bedpeB.end1)): 
			chr2new=bedpeA.chr2
			s2new=min(bedpeA.start2, bedpeB.start1)
			e2new=max(bedpeA.end2, bedpeB.end1)
		if (chr1new == "chrD"): # switch so that the second interval is the dummy. 
			(chr1new, s1new, e1new) = (chr2new, s2new, e2new)
			(chr2new, s2new, e2new) = ("chrD", 0, 100) 
		newID=bedpeA.ID+"+"+bedpeB.ID
		score=bedpeA.score+bedpeB.score
		outline="\t".join(map(str, (chr1new, s1new, e1new, chr2new, s2new, e2new, newID, score, ".", ".", bedpeA.info, bedpeB.info)))
		sys.stdout.write(outline+"\n")

def main(): 
	parser = argparse.ArgumentParser(description= 'reformats the output from pairToPair (bedpe files) to create merged intervals.  If both ends of the bedpe overlap, it takes the largest window of the merge.  If only one end of the bedpe overlaps in the two files, it creates 3 outputs- one for the merged end with a dummy chromosome (chrD) for the second chromosome, and one for each of the separate intervals.') 
	parser.add_argument('filein',type=argparse.FileType('r'),  help='input file (the output from a bedtools pairToPair call).')
	parser.add_argument('-c','--col2',  type=int, default=11, help='The number of columns in the first bedpe file(the -a file for pairToPair).') 
	args=parser.parse_args()
	merge_bedpes(args.filein, args.col2)


if __name__ == '__main__': 
	main()

