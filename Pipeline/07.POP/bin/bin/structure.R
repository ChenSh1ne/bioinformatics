times<-Sys.time()

library('getopt');
options(bitmapType='cairo')

spec = matrix(c(
	'help' , 'h', 0, "logical",
	'infile','i',1,"character",
	'outfile' , 'o', 1, "character"
	), byrow=TRUE, ncol=4);
opt = getopt(spec);
# define usage function
print_usage <- function(spec=NULL){
	cat(getopt(spec, usage=TRUE));
	cat("Usage example: \n")
	cat("
Usage example: 
Options: 
	--help		NULL 		get this help
	--infile 	character 	structure file
	--outfile 	character 	the filename for output graph [forced]
	\n")
	q(status=1);
}
if(is.null(opt$infile)){print_usage(spec)}
if(is.null(opt$outfile)){print_usage(spec)}

tbl<-read.table(opt$infile,header=FALSE);
id<-tbl$V1;
col<-length(colnames(tbl))
coldata<-rainbow(20)
data<-tbl[,2:col]
pdf(paste(opt$outfile,".pdf",sep=""),width=16, height=9)
par(mar=c(max(nchar(as.character(id)))*0.7,5,2,0))
barplot(t(as.matrix(data)),names.arg=id, col=coldata[1:col-1],main="Individual #", ylab="Ancestry", border=NA,las=2)
dev.off()
png(paste(opt$outfile,".png",sep=""),width=1600, height=900)
par(mar=c(max(nchar(as.character(id)))*0.7,5,2,0))
barplot(t(as.matrix(data)),names.arg=id,col=coldata[1:col-1],main="Individual #", ylab="Ancestry", border=NA,las=2)
dev.off()
escaptime=Sys.time()-times;
print("Done!")
print(escaptime)
