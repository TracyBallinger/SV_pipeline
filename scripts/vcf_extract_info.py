import argparse 
import sys

# written by Tracy Ballinger (tracy.ballinger@igmm.ed.ac.uk) 
# This is an alternative to bcftools query -f because that program doesn't do everything I want. 

def vcf_extrac_info(vcffile): 
	for l in vcffile: 
		

def main(): 
	parser=argparse.ArgumentParser(description = 'reformats a vcf file, similar to bcftools query -f command.') 
	parser.add_argument('vcf', type=argparse.FileType('r'), help='vcf input file') 
	args=parser.parse_args()
	vcf_extract_info(args.vcf)

if __name__ == '__main__': 
	main()
