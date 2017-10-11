
args <- commandArgs(trailingOnly =TRUE) 
covhistfile=args[1]
outfile=args[2]

dat=read.table(covhistfile, header=FALSE) 
gi=dat[,1]=="chr11"
dat=dat[gi,]

m = sum(dat[,2]*dat[,3])/dat[1,4]
var=sum(dat[,2]*(dat[,3]-m))/dat[1,4]
s= sqrt(var)

write(sprintf("%f\t%f", m, s), outfile)
