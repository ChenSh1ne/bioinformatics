#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $BEGIN_TIME=time();
my $version="1.0.0";
#######################################################################################
#######д�����޸ĳ���һ��Ҫע��ʱ�䣬���Ŀ�ģ��Գ������һЩע�͡�������Ϣ########
#######################################################################################
# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($fIndir,$fMapdir,$outdir);
GetOptions(
				"help|?" =>\&USAGE,
				"i:s"=>\$fIndir,
				"o:s"=>\$outdir,
				"m:s"=>\$fMapdir,
				) or &USAGE;
&USAGE unless ($fIndir  and $fMapdir and $outdir);

`mkdir -p $outdir` unless(-d $outdir);
my ($outdirpathway)=&AbsolutePath("dir",$outdir);
my $outfile;

my @Dir=glob("$fIndir/*.loc");
my @Marker;
foreach my $key (@Dir) {

	my ($pathway)=&AbsolutePath("file",$key);
	my $key_basename=basename($pathway);
	my $key_dirname=dirname($pathway);

	$key_basename=~/(\S+)\.loc/;
	my $file=$1;
	my $fMap=$fMapdir."/".$file.".map";

	$outfile=$outdirpathway."/".$file;
	print "perl $Bin/IndividualLinkagePhaseNumber.pl -i $fIndir/$file.loc -m $fMapdir/$file.map -o $outdir/$file \n";
	`perl $Bin/IndividualLinkagePhaseNumber.pl -i $fIndir/$file.loc -m $fMapdir/$file.map -o $outdir/$file `;

}


#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################

# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}
sub AbsolutePath
{		#��ȡָ��Ŀ¼���ļ��ľ���·��
        my ($type,$input) = @_;

        my $return;

        if ($type eq 'dir')
        {
                my $pwd = `pwd`;
                chomp $pwd;
                chdir($input);
                $return = `pwd`;
                chomp $return;
                chdir($pwd);
        }
        elsif($type eq 'file')
        {
                my $pwd = `pwd`;
                chomp $pwd;

                my $dir=dirname($input);
                my $file=basename($input);
                chdir($dir);
                $return = `pwd`;
                chomp $return;
                $return .="\/".$file;
                chdir($pwd);
        }
        return $return;
}

sub USAGE {#
	my $usage=<<"USAGE";
Program:IndividualLinkagePhaseNumber_v1.pl
call:NULL
Author: wushuang <wus\@biomarker.com.cn> 
Version: $version
Date: 2011-8-31
Description:
	�����ױ���������ͻ����ͣ�ͳ���Ӵ�����Ļ����͵��ױ����ͣ�loc�ļ�Ҫ������������Ϣ
    ����Ŀ¼��loc��map�ļ�����Ҫһ��,exp:lg1.sexAver.loc lg1.sexAver.map 
	-��ȱʧ
	0: �޷��ж�
	1���Ӵ������������ױ���һ����λ������ green bar
	2���Ӵ������������ױ��ڶ�����λ������ blue bar
Usage:
  Options:
  -i <dir>   Input loc file in dir, forced
  -m <dir>   Input map file in dir, forced
  -o <dir>   Output dir
	         Output file, default name of loc 
              *.phase  ת�����������ļ�
              *.tq     ��ͼ������
              *.tq.png ͼƬ
  -h         Help

USAGE
	print $usage;
	exit;
}
