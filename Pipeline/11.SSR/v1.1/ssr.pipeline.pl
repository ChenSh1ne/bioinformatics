#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fqlist,$out,$ref,$sample);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"fqlist:s"=>\$fqlist,
	"ref:s"=>\$ref,
	"sample"=>\$sample,
	"out:s"=>\$out,
			) or &USAGE;
&USAGE unless ($out);
mkdir $out if (!-d $out);
if ($sample) {
	$out=ABSOLUTE_DIR($out);
	mkdir "$out/work_sh" if (!-d "$out/work_sh");
	open In,$fqlist;
	open Out,">$out/soapdenovo.config";
	while (<In>) {
		chomp;
		next if ($_ eq ""||/^$/);
		my ($id,$fq1,$fq2)=split(/\s+/,$_);
		print Out "max_rd_len=150\n";
		print Out "[LIB]\n";
		print Out "avg_ins=$id\n";
		print Out "reverse_seq=0\n";
		print Out "asm_flags=3\n";
		print Out "rank=1\n";
		print Out "q1=$fq1\n";
		print Out "q2=$fq2\n";
	}
	close In;
	close Out;
	open SH,">$out/work_sh/ssr.sh";
	print SH "cd $out &&";
	print SH "SOAPdenovo-127mer all -s $out/soapdenovo.config -K 63 -R -o $out/denovo -p 20 1> $out/ass.log 2>$out/ass.err && ";
	print SH "perl $Bin/bin/misa.pl $out/denovo.scafSeq $Bin/bin/misa.ini && ";
	print SH "perl $Bin/bin/p3_in.pl $out/denovo.scafSeq.newmisa $out/denovo.scafSeq.ssrfa && ";
	print SH "cd /mnt/ilustre/users/dna/Environment/biotools/primer3/src/ && ./primer3_core < $out/denovo.scafSeq.misa.p3in > $out/denovo.scafSeq.misa.p3out &&";
	print SH "cd $out/ && perl $Bin/bin/p3_out.pl $out/denovo.scafSeq.misa.p3out > $out/denovo.scafSeq.misa.result\n";
	close SH;
}else{
	open SH,">$out/work_sh/ssr.sh";
	print SH "cd $out && ln -s $ref $out/ref.fa";
	print SH "perl $Bin/bin/misa.pl $out/ref.fa $Bin/bin/misa.ini && ";
	print SH "perl $Bin/bin/p3_in.pl $out/ref.fa.newmisa $out/ref.fa.ssrfa && ";
	print SH "cd /mnt/ilustre/users/dna/Environment/biotools/primer3/src/ && ./primer3_core < $out/ref.fa.misa.p3in > $out/ref.fa.misa.p3out &&";
	print SH "cd $out/ && perl $Bin/bin/p3_out.pl $out/ref.fa.misa.p3out > $out/ref.fa.misa.result\n";
	close SH;
}
#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
sub ABSOLUTE_DIR #$pavfile=&ABSOLUTE_DIR($pavfile);
{
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir \n$in";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

sub USAGE {#
        my $usage=<<"USAGE";
Contact:        long.huang\@majorbio.com;
Script:			$Script
Description:
	fq thanslate to fa format
	eg:
	perl $Script -i -o -k -c

Usage:
  Options:
	"fqlist:s"=>\$fqlist,
	"ref:s"=>\$ref,
	"sample"=>\$sample,
	"out:s"=>\$out,
  -h         Help

USAGE
        print $usage;
        exit;
}
