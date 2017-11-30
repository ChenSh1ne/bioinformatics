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
#
#######################################################################################
# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($fIn,$fOut);

GetOptions(
				"help|?" =>\&USAGE,
				"o:s"=>\$fOut,
				"i:s"=>\$fIn,
				) or &USAGE;
&USAGE unless ($fIn and $fOut);
# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------
open (IN,$fIn) or die $!;
#open (OUT,">$fOut") or die $!;
#chrΪ��ά���飬һά����Ⱦɫ�壬��ά���Ⱦɫ�������
my @chr;  
my $arry_i=0;
my $arry_j=0;
my $count = 0;
my $temp = "";
my @chr_recom_num;  #��ά�������ڴ��ÿ����¼����ĸ���

while(<IN>)
{
	chomp;
	next if (/Marker/);
	my @temp_str = split /\t/,$_;
	my $temp_chr = $temp_str[1];
	#�Ƚ�Ⱦɫ�壬��ͬ��һά��ά�����ӣ���ά���㿪ʼ
	if($temp ne $temp_chr)
	{
		if($temp eq "")
		{
			$chr[$arry_i][$arry_j] = $_;
		}
		else
		{
			$arry_i++;
			$arry_j = 0;
			$chr[$arry_i][$arry_j]= $_;
		}
	}
	#��ͬ��ά��ά������
	else
	{
		$chr[$arry_i][$arry_j]= $_;	
	}
	$temp = $temp_chr;
	$arry_j++;
}

for(my $n=0; $n<@chr;$n++)
{
	open (OUT, ">outfile.$n") || die "Can't creat XXX, $!\n" ;  #����Ⱦɫ��Ĳ�ͬ��̬�����ļ�
	#��ӡ����
	print OUT "ID\t";
	for(my $j=0; $j<@{$chr[$n]};$j++)
	{
		my @chr_num = split(/\t/,$chr[$n][$j]);
		print OUT "$chr_num[0]\t";
	}
	print OUT "\n";
	

	#˫��forѭ�������ڼ��������������@chr_recom_num������
	for(my $j=0; $j<@{$chr[$n]};$j++)
	{
		my @str2 = split(/\t/,$chr[$n][$j]);
		for(my $k=$j+1; $k<@{$chr[$n]};$k++)
		{
			my @str3 = split(/\t/,$chr[$n][$k]);
			my $num = 0;		#������ȵĸ���
			for(my $m=6; $m<@str3;$m++)
			{
				if($str2[$m] ne "--" and  $str3[$m] ne "--")
				{
					if($str2[$m] ne $str3[$m]) {$num++;}
				}
			}
			$chr_recom_num[$j][$k] = $num;
		}
	}
	#������@chr_recom_num���¶Խ��߸�ֵ
	for(my $nu=0; $nu <@chr_recom_num; $nu++)
	{
		for(my $mu=0; $mu <=$nu; $mu++)
		{
			if($nu == $mu)
			{
				$chr_recom_num[$nu][$mu] = "-"; 
			}
			else
			{
				$chr_recom_num[$nu][$mu] = $chr_recom_num[$mu][$nu] ;
			}
		}
	}
	#��ӡ����@chr_recom_num(��ŵ�������ĸ���
	for(my $nn=0; $nn <@chr_recom_num; $nn++)
	{
		if($nn < @{$chr[$n]})
		{
			my @str2 = split(/\t/,$chr[$n][$nn]);
			print OUT "$str2[0]\t";
		
			for(my $mm=0; $mm <@{$chr_recom_num[$nn]}; $mm++)
			{
				print OUT "$chr_recom_num[$nn][$mm]\t";
			}
			print OUT "\n";
		}
	}
	close(OUT);
}
close IN;
#close (OUT);
#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################

# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
################################################################################################################

sub ABSOLUTE_DIR{ #$pavfile=&ABSOLUTE_DIR($pavfile);
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
		warn "Warning just for file and dir\n";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

################################################################################################################

sub max{#&max(lists or arry);
	#���б��е����ֵ
	my $max=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$max=$max>$temp?$max:$temp;
	}
	return $max;
}

################################################################################################################

sub min{#&min(lists or arry);
	#���б��е���Сֵ
	my $min=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$min=$min<$temp?$min:$temp;
	}
	return $min;
}

################################################################################################################

sub revcom(){#&revcom($ref_seq);
	#��ȡ�ַ������еķ��򻥲����У����ַ�����ʽ���ء�ATTCCC->GGGAAT
	my $seq=shift;
	$seq=~tr/ATCGatcg/TAGCtagc/;
	$seq=reverse $seq;
	return uc $seq;			  
}

################################################################################################################

sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

################################################################################################################
sub USAGE {
	my $usage=<<"USAGE";
 ProgramName:
     Version:	$version
     Contact:	Simon Young <yangxh\@biomarker.com.cn> 
Program Date:	2012.07.02
      Modify:	
 Description:	This program is used to ......
       Usage:
		Options:
		-i <file>	input file,xxx format,forced

		-o <file>	output file,optional

		-h		help

USAGE
	print $usage;
	exit;
}
