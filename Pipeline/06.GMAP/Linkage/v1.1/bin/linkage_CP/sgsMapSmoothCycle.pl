#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use Cwd qw(abs_path);
my $BEGIN_TIME=time();
my $version="1.0.0";
my @Original_ARGV=@ARGV;
#######################################################################################
# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($fIn,$fKey,$error_ratio,$dOut,$mode,$cycle_t,$log,$diff_ratio,$fix,$str,$noise_ratio);
GetOptions(
				"help|?" =>\&USAGE,
				"i:s"=>\$fIn,
				"k:s"=>\$fKey,
				"d:s"=>\$dOut,

				"e:s"=>\$error_ratio,
				"diff_ratio:s"=>\$diff_ratio,
				"mode:s"=>\$mode,
				"fix:s"=>\$fix,
				"str:s"=>\$str,
				"n:s"=>\$cycle_t,
				"r:f"=>\$noise_ratio,  #modify by qix for drawmap2015-10-27
				
				) or &USAGE;
&USAGE unless ($fIn and $fKey);
#-------------------------------------------------------------------
#Global parameter settings
#-------------------------------------------------------------------
$dOut||="./";
mkdir $dOut unless (-d $dOut) ;
$dOut = Cwd::abs_path($dOut);

$noise_ratio||=0.05; #modify by qix for drawmap2015-10-27
$error_ratio||=0.06;
$mode = 0 unless (defined $mode) ;
$cycle_t ||= 5;
$diff_ratio||=0.85;
open ($log,">","$dOut/$fKey.log") or die $!;
&printLogHead($log);
#-------------------------------------------------------------------
# Global value
#-------------------------------------------------------------------
my $file_type = (`grep '{..}' -P $fIn`) ? 'loc_lp': 'genotype_loc';

#-------------------------------------------------------------------
# mapping process 
#-------------------------------------------------------------------
if ($mode == 0) {
	if ($file_type eq 'loc_lp') { ## �����ļ�Ϊ����������Ϣ��loc�ļ�

		## calculate pwd 
		{
			print "perl $Bin/calculatePWDviaQsub.pl -i $fIn -d $dOut/pwd -k $fKey \n";
			print $log "perl $Bin/calculatePWDviaQsub.pl -i $fIn -d $dOut/pwd -k $fKey \n";
			`perl $Bin/calculatePWDviaQsub.pl -i $fIn -d $dOut/pwd -k $fKey`;

			die "pwd file not generated" unless (-f "$dOut/pwd/$fKey.pwd") ;
		}

		## construct map using sgsMap
		{
			mkdir "$dOut/map" unless (-d "$dOut/map") ;
			my $job="$Bin/sgsMap -loc $fIn -pwd $dOut/pwd/$fKey.pwd -k $dOut/map/$fKey";
			if (defined $fix) {
				$job.=" -fix $fix";
			}
			if (defined $str) {
				$job.=" -strts $str"
			}
			print $job,"\n";
			print $log $job,"\n";
			`$job`;
			
			die "map file not generated" unless (-f "$dOut/map/$fKey.sexAver.map") ;
		}

		## correct error genotypes and imput missing observations
		{
			print "perl $Bin/smooth.pl -m $dOut/map/$fKey.sexAver.map -l $fIn -k $fKey -d $dOut/smooth -cycle_threshold 3 -sus $error_ratio -diff_ratio $diff_ratio\n";
			print $log "perl $Bin/smooth.pl -m $dOut/map/$fKey.sexAver.map -l $fIn -k $fKey -d $dOut/smooth -cycle_threshold 3 -sus $error_ratio -diff_ratio $diff_ratio\n";
			`perl $Bin/smooth.pl -m $dOut/map/$fKey.sexAver.map -l $fIn -k $fKey -d $dOut/smooth -cycle_threshold 3 -sus $error_ratio -diff_ratio $diff_ratio `;

		}
		
		{
			##########draw maps,if it has zero marker,print can`t draw informaion.
			#rmdir "$dOut/visualization" if (-d "$dOut/visualization") ;
			#mkdir "$dOut/visualization" unless (-d "$dOut/visualization") ; 
			`mkdir $dOut/visualization` unless (-d "$dOut/visualization");
			`mkdir $dOut/visualization/haploSource` unless (-d "$dOut/visualization/haploSource") ;
			`mkdir $dOut/visualization/heatMap` unless(-d "$dOut/visualization/heatMap");
			
			`perl $Bin/drawFlow/drawHeatmap.pl -i $dOut/map/$fKey.sexAver.map -p $dOut/pwd/$fKey.pwd -k $fKey.sexAver -d $dOut/visualization/heatMap `;
			print "perl $Bin/drawFlow/drawHeatmap.pl -i $dOut/map/$fKey.sexAver.map -p $dOut/pwd/$fKey.pwd -k $fKey.sexAver -d $dOut/visualization/heatMap \n";
			print $log "perl $Bin/drawFlow/drawHeatmap.pl -i $dOut/map/$fKey.sexAver.map -p $dOut/pwd/$fKey.pwd -k $fKey.sexAver -d $dOut/visualization/heatMap \n";

			`perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $fIn -m $dOut/map/$fKey.sexAver.map -o $dOut/visualization/haploSource/$fKey.sexAver `;
			print  "perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $fIn -m $dOut/map/$fKey.sexAver.map -o $dOut/visualization/haploSource/$fKey.sexAver \n";
			print $log "perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $fIn -m $dOut/map/$fKey.sexAver.map -o $dOut/visualization/haploSource/$fKey.sexAver \n";
			`perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.sexAver.phase -od $dOut/visualization/haploSource/ -r $noise_ratio `;
			print  "perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.sexAver.phase -od $dOut/visualization/haploSource/ -r $noise_ratio \n";
			print $log "perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.sexAver.phase -od $dOut/visualization/haploSource/ -r $noise_ratio \n";

			#heatmap check for female.map and male.map then draw heatmap and haploSource 
			my @CHECK = ("$dOut/map/$fKey.female.map","$dOut/map/$fKey.male.map");
			my $synteny=0; #only when three kinds of map have markers, can draw synteny map.
			for (my $i=0;$i<@CHECK;$i++) {
				open (HMCHECK,$CHECK[$i]) or die $!; 
				print "Check map file for heatmap :$CHECK[$i] .\n";
				print $log "Check map file for heatmap :$CHECK[$i] .\n";
				my @marker=();
				while (<HMCHECK>) {
					s/\r//g;
					chomp;
					next if (/^$/ || /^group/ || /^;/) ;
					next unless (/^(\S+)\s+\S+/) ;
					push @marker,$1;
				}
				if (scalar(@marker)==0) {
					print "Can`t draw heatmap due to 0 marker in file : $CHECK[$i].\n";
					print $log "Can`t draw heatmap due to 0 marker in file : $CHECK[$i].\n";
					$synteny ++ ;
				}else{
					my $sex = ($i==0) ? "female" : "male" ;
					`perl $Bin/drawFlow/drawHeatmap.pl -i $CHECK[$i] -p $dOut/pwd/$fKey.pwd -k $fKey.$sex -d $dOut/visualization/heatMap `;
					print "perl $Bin/drawFlow/drawHeatmap.pl -i $CHECK[$i] -p $dOut/pwd/$fKey.pwd -k $fKey.$sex -d $dOut/visualization/heatMap \n";
					print  $log "perl $Bin/drawFlow/drawHeatmap.pl -i $CHECK[$i] -p $dOut/pwd/$fKey.pwd -k $fKey.$sex -d $dOut/visualization/heatMap \n";
					`perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $fIn -m $CHECK[$i] -o $dOut/visualization/haploSource/$fKey.$sex `;
					print  "perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $fIn -m $CHECK[$i] -o $dOut/visualization/haploSource/$fKey.$sex \n";
					print $log "perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $fIn -m $CHECK[$i] -o $dOut/visualization/haploSource/$fKey.$sex \n";
					`perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.$sex.phase -od $dOut/visualization/haploSource/ -r $noise_ratio `;
					print  "perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.$sex.phase -od $dOut/visualization/haploSource/ -r $noise_ratio \n";
					print $log "perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.$sex.phase -od $dOut/visualization/haploSource/ -r $noise_ratio \n";
				}
			}
			#only when three kinds of map have markers,draw synteny map.
			if ($synteny == 0) {
				`mkdir $dOut/visualization/synteny` unless(-d  "$dOut/visualization/synteny");
				`perl $Bin/drawFlow/drawGT3Map.pl -i1 $CHECK[0] -i2 $dOut/map/$fKey.sexAver.map -i3 $CHECK[1] -o $fKey -g $fIn -d $dOut/visualization/synteny/ -s run `;
				#print SH "perl $Bin/drawGT3Map.pl -i1 $indir/$lg.female.map -i2 $indir/$lg.sexAver.map -i3 $indir/$lg.male.map -o $lg -d $outdir/$lg/Result/synteny -g $fgenotype -s run && \n"	
				print "perl $Bin/drawFlow/drawGT3Map.pl -i1 $CHECK[0] -i2 $dOut/map/$fKey.sexAver.map -i3 $CHECK[1] -o $fKey -g $fIn -d $dOut/visualization/synteny/ -s run \n";
				print $log "perl $Bin/drawFlow/drawGT3Map.pl -i1 $CHECK[0] -i2 $dOut/map/$fKey.sexAver.map -i3 $CHECK[1] -o $fKey -g $fIn -d $dOut/visualization/synteny/ -s run \n";
			}else{
			print "Can`t draw synteny map,due to 0 maker in male or female map file.\n";
			print $log "Can`t draw synteny map,due to 0 maker in male or female map file.\n";
			}
		}

	}else{ ## �����ļ�û����������Ϣ
		## calculate pwd
		{
			print "perl $Bin/calculatePWDviaQsub.pl -i $fIn -d $dOut/pwd -k $fKey \n";
			print $log "perl $Bin/calculatePWDviaQsub.pl -i $fIn -d $dOut/pwd -k $fKey \n";
			`perl $Bin/calculatePWDviaQsub.pl -i $fIn -d $dOut/pwd -k $fKey -step 1`;
			die "pwd file not generated" unless (-f "$dOut/pwd/$fKey.pwd") ;
		}

		## determine linkage phase 
		{
			print "perl $Bin/linkagePhase.pl -p $dOut/pwd/$fKey.pwd -g $fIn -k $fKey -d $dOut/phase \n";
			print $log "perl $Bin/linkagePhase.pl -p $dOut/pwd/$fKey.pwd -g $fIn -k $fKey -d $dOut/phase \n";
			`perl $Bin/linkagePhase.pl -p $dOut/pwd/$fKey.pwd -g $fIn -k $fKey -d $dOut/phase`;

			die "determine linkage phase failed" unless (-f "$dOut/phase/$fKey.loc") ;
		}

		## modified pwd info according to linkage phase, eliminate confliction of pairwise data 
		{
			print "perl $Bin/extractPwdViaLP.pl -i $dOut/pwd/$fKey.pwd.detail -l $dOut/phase/$fKey.loc -k $fKey.modified -d $dOut/pwd \n";
			print $log "perl $Bin/extractPwdViaLP.pl -i $dOut/pwd/$fKey.pwd.detail -l $dOut/phase/$fKey.loc -k $fKey.modified -d $dOut/pwd \n";
			`perl $Bin/extractPwdViaLP.pl -i $dOut/pwd/$fKey.pwd.detail -l $dOut/phase/$fKey.loc -k $fKey.modified -d $dOut/pwd`;
			
			die "unify pairwise data failed" unless (-f "$dOut/pwd/$fKey.modified.pwd") ;
		}

		## Order Marker in a linkage group using sgsMap
		{
			mkdir "$dOut/map" unless (-d "$dOut/map") ;

			my $job="$Bin/sgsMap -loc $dOut/phase/$fKey.loc -pwd $dOut/pwd/$fKey.modified.pwd -k $dOut/map/$fKey";
			if (defined $fix) {
				$job.=" -fix $fix";
			}
			if (defined $str) {
				$job.=" -strts $str"
			}
			print $job,"\n";
			print $log $job,"\n";
			`$job`;
			
			die "map file not generated" unless (-f "$dOut/map/$fKey.sexAver.map") ;
		}

		## correct error genotypes and imput missing observations
		{
			print "perl $Bin/smooth.pl -m $dOut/map/$fKey.sexAver.map -l $dOut/phase/$fKey.loc -k $fKey -d $dOut/smooth -cycle_threshold 3  -sus $error_ratio\n";
			print $log "perl $Bin/smooth.pl -m $dOut/map/$fKey.sexAver.map -l $dOut/phase/$fKey.loc -k $fKey -d $dOut/smooth -cycle_threshold 3  -sus $error_ratio\n";
			`perl $Bin/smooth.pl -m $dOut/map/$fKey.sexAver.map -l $dOut/phase/$fKey.loc -k $fKey -d $dOut/smooth -cycle_threshold 3  -sus $error_ratio`;

			## remove linkage phase info from corrected loc 
			print "perl $Bin/loc2genotype.pl -i $dOut/smooth \n";
			print $log "perl $Bin/loc2genotype.pl -i $dOut/smooth \n";
			`perl $Bin/loc2genotype.pl -i $dOut/smooth `;
		}
		{
			##draw heatmap
			mkdir "$dOut/visualization" unless (-d "$dOut/visualization") ; 
			mkdir "$dOut/visualization/haploSource" unless (-d "$dOut/visualization/haploSource") ;
			mkdir "$dOut/visualization/heatMap" unless(-d "$dOut/visualization/heatMap");
			`perl $Bin/drawFlow/drawHeatmap.pl -i $dOut/map/$fKey.sexAver.map -p $dOut/pwd/$fKey.modified.pwd -k $fKey.sexAver -d $dOut/visualization/heatMap `;
			print "perl $Bin/drawFlow/drawHeatmap.pl -i $dOut/map/$fKey.sexAver.map -p $dOut/pwd/$fKey.modified.pwd -k $fKey.sexAver -d $dOut/visualization/heatMap \n";
			print $log "perl $Bin/drawFlow/drawHeatmap.pl -i $dOut/map/$fKey.sexAver.map -p $dOut/pwd/$fKey.modified.pwd -k $fKey.sexAver -d $dOut/visualization/heatMap \n";
			
			`perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $dOut/phase/$fKey.loc -m $dOut/map/$fKey.sexAver.map -o $dOut/visualization/haploSource/$fKey.sexAver `;
			print  "perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $dOut/phase/$fKey.loc -m $dOut/map/$fKey.sexAver.map -o $dOut/visualization/haploSource/$fKey.sexAver \n";
			print $log "perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $dOut/phase/$fKey.loc -m $dOut/map/$fKey.sexAver.map -o $dOut/visualization/haploSource/$fKey.sexAver \n";
			`perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.sexAver.phase -od $dOut/visualization/haploSource/ -r $noise_ratio `;
			print  "perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.sexAver.phase -od $dOut/visualization/haploSource/ -r $noise_ratio \n";
			print $log "perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.sexAver.phase -od $dOut/visualization/haploSource/ -r $noise_ratio \n";

			#heatmap check for female.map and male.map then draw heatmap
			my @CHECK = ("$dOut/map/$fKey.female.map","$dOut/map/$fKey.male.map");
			my $synteny=0; #only when three kinds of map have markers, can draw synteny map.
			for (my $i=0;$i<@CHECK;$i++) {
				open (HMCHECK,$CHECK[$i]) or die $!; 
				print "Check map file for heatmap :$CHECK[$i] .\n";
				print $log "Check map file for heatmap :$CHECK[$i] .\n";
				my @marker=();
				while (<HMCHECK>) {
					s/\r//g;
					chomp;
					next if (/^$/ || /^group/ || /^;/) ;
					next unless (/^(\S+)\s+\S+/) ;
					push @marker,$1;
				}
				if (scalar(@marker)==0) {
					print "Can`t draw heatmap due to 0 marker in file : $CHECK[$i].\n";
					print $log "Can`t draw heatmap due to 0 marker in file : $CHECK[$i].\n";
					$synteny ++ ;
				}else{
					my $sex = ($i==0) ? "female" : "male" ;
					
					`perl $Bin/drawFlow/drawHeatmap.pl -i $CHECK[$i] -p $dOut/pwd/$fKey.modified.pwd -k $fKey.$sex -d $dOut/visualization/heatMap `;
					print "perl $Bin/drawFlow/drawHeatmap.pl -i $CHECK[$i] -p $dOut/pwd/$fKey.modified.pwd -k $fKey.$sex -d $dOut/visualization/heatMap \n";
					print  $log "perl $Bin/drawFlow/drawHeatmap.pl -i $CHECK[$i] -p $dOut/pwd/$fKey.modified.pwd -k $fKey.$sex -d $dOut/visualization/heatMap \n";
					
					`perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $dOut/phase/$fKey.loc -m $CHECK[$i] -o $dOut/visualization/haploSource/$fKey.$sex `;
					print  "perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $dOut/phase/$fKey.loc -m $CHECK[$i] -o $dOut/visualization/haploSource/$fKey.$sex \n";
					print $log "perl $Bin/drawFlow/IndividualLinkagePhaseNumber.pl -i $dOut/phase/$fKey.loc -m $CHECK[$i] -o $dOut/visualization/haploSource/$fKey.$sex \n";
					`perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.$sex.phase -od $dOut/visualization/haploSource/ -r $noise_ratio `;
					print  "perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.$sex.phase -od $dOut/visualization/haploSource/ -r $noise_ratio \n";
					print $log "perl $Bin/drawFlow/statHaploSourceNoise.pl -i $dOut/visualization/haploSource/$fKey.$sex.phase -od $dOut/visualization/haploSource/ -r $noise_ratio \n";

				}
			}
			#only when three kinds of map have markers,draw synteny map.
			if ($synteny == 0) {
				`mkdir $dOut/visualization/synteny` unless(-d  "$dOut/visualization/synteny");
				`perl $Bin/drawFlow/drawGT3Map.pl -i1 $CHECK[0] -i2 $dOut/map/$fKey.sexAver.map -i3 $CHECK[1] -o $fKey -g $dOut/phase/$fKey.loc -d $dOut/visualization/synteny/ -s run `;
				#print SH "perl $Bin/drawGT3Map.pl -i1 $indir/$lg.female.map -i2 $indir/$lg.sexAver.map -i3 $indir/$lg.male.map -o $lg -d $outdir/$lg/Result/synteny -g $fgenotype -s run && \n"	
				print "perl $Bin/drawFlow/drawGT3Map.pl -i1 $CHECK[0] -i2 $dOut/map/$fKey.sexAver.map -i3 $CHECK[1] -o $fKey -g $dOut/phase/$fKey.loc -d $dOut/visualization/synteny/ -s run \n";
				print $log "perl $Bin/drawFlow/drawGT3Map.pl -i1 $CHECK[0] -i2 $dOut/map/$fKey.sexAver.map -i3 $CHECK[1] -o $fKey -g $dOut/phase/$fKey.loc -d $dOut/visualization/synteny/ -s run \n";
			}else{
			print "Can`t draw synteny map,due to 0 maker in male or female map file.\n";
			print $log "Can`t draw synteny map,due to 0 maker in male or female map file.\n";
			}
		}

	}
}elsif($mode == 1){
	my $cycle = 0;
	### start cycle 
	my $current_cycle_dir = "$dOut/cycle_$cycle";
	mkdir $current_cycle_dir unless (-d $current_cycle_dir) ;  ## output directory 
	print ">cycle $cycle\n";
	print $log ">cycle $cycle\n";

	print "perl $0 -i $fIn -k $fKey -d $current_cycle_dir -e $error_ratio -diff_ratio $diff_ratio -mode 0\n";      #modify by qix 
	print $log "perl $0 -i $fIn -k $fKey -d $current_cycle_dir -e $error_ratio -diff_ratio $diff_ratio -mode 0\n";
	` perl $0 -i $fIn -k $fKey -d $current_cycle_dir -e $error_ratio -diff_ratio $diff_ratio -mode 0 `;

	### multiple cycle 
	while (++$cycle < $cycle_t) {
		my $last_cycle = $cycle - 1;
		
		die "multiple mapping process error, at cycle $last_cycle, $dOut/cycle_$last_cycle/smooth/$fKey.correct.loc.log: No such file" unless (-f "$dOut/cycle_$last_cycle/smooth/$fKey.correct.loc.log") ;
		my $n_genotypes_changed = `wc -l $dOut/cycle_$last_cycle/smooth/$fKey.correct.loc.log`;
		($n_genotypes_changed) = $n_genotypes_changed =~/^(\d+)/;
		last if ($n_genotypes_changed == 0) ;  ### iteration stop condition: No further improvement

		### next cycle 
		$current_cycle_dir = "$dOut/cycle_$cycle";
		mkdir $current_cycle_dir unless (-d $current_cycle_dir) ;  ## output directory

		print ">cycle $cycle\n";
		print $log ">cycle $cycle\n";
		
		if ($file_type eq 'loc_lp') {
			my $job="perl $0 -i $dOut/cycle_$last_cycle/smooth/$fKey.correct.loc -k $fKey -d $current_cycle_dir -e $error_ratio -mode 0 -diff_ratio $diff_ratio \n";#modify by qix
			if (defined $fix) {
				$job.=" -fix $fix";
			}
			if (defined $str) {
				$job.=" -str $str"
			}
			print $job,"\n";
			print $log $job,"\n";
			`$job`;
		}else{
			my $job= "perl $0 -i $dOut/cycle_$last_cycle/smooth/$fKey.correct.genotype -k $fKey -d $current_cycle_dir -e $error_ratio -mode 0 -diff_ratio $diff_ratio \n";#modify by qix
			if (defined $fix) {
				$job.=" -fix $fix";
			}
			if (defined $str) {
				$job.=" -str $str"
			}
			print $job,"\n";
			print $log $job,"\n";
			`$job`;
		
		}	
	}

	### link map, pwd and loc 
	$cycle--;
	rmdir "$dOut/result" if (-d "$dOut/result") ;
	mkdir "$dOut/result" unless (-d "$dOut/result") ;

	## map
	`ln -s $dOut/cycle_$cycle/map/$fKey.female.map $dOut/result`;
	`ln -s $dOut/cycle_$cycle/map/$fKey.male.map $dOut/result`;
	`ln -s $dOut/cycle_$cycle/map/$fKey.sexAver.map $dOut/result`;

	## loc
	`ln -s $dOut/cycle_$cycle/smooth/$fKey.correct.loc $dOut/result/$fKey.female.loc`;
	`ln -s $dOut/cycle_$cycle/smooth/$fKey.correct.loc $dOut/result/$fKey.male.loc`;
	`ln -s $dOut/cycle_$cycle/smooth/$fKey.correct.loc $dOut/result/$fKey.sexAver.loc`;
	
	## pwd
	if ($file_type eq 'loc_lp') {
		`ln -s $dOut/cycle_$cycle/pwd/$fKey.pwd $dOut/result/$fKey.sexAver.pwd`;
		`ln -s $dOut/cycle_$cycle/pwd/$fKey.pwd $dOut/result/$fKey.male.pwd`;
		`ln -s $dOut/cycle_$cycle/pwd/$fKey.pwd $dOut/result/$fKey.female.pwd`;
	}else{
		`ln -s $dOut/cycle_$cycle/pwd/$fKey.modified.pwd $dOut/result/$fKey.sexAver.pwd`;
		`ln -s $dOut/cycle_$cycle/pwd/$fKey.modified.pwd $dOut/result/$fKey.male.pwd`;
		`ln -s $dOut/cycle_$cycle/pwd/$fKey.modified.pwd $dOut/result/$fKey.female.pwd`;
	}
	#open ($log,">","$dOut/$fKey.log") or die $!;
	open (STAMAP,">","$dOut/result/MAP.STAT.xls" ) or die $!;                                                     #add by qix 2015.10.15,stat cycle infor
	print STAMAP "#Cycle\tsex\tnloc\tnind\tsum\tmiss\tmiss(%)\tgap_5\tgap_5(%)\tdis\taver.dis\tmaxgap\tgappos\tgapmarker\n";
	for (my $newcycle=0 ; $newcycle<=$cycle;$newcycle++) {                                                       
		print "perl $Bin/stat_cycle_info.pl -c $newcycle  -in $dOut/cycle_$newcycle/map/ -loc $dOut/cycle_$newcycle/smooth/$fKey.correct.loc -o $dOut/result/\n";        
		print $log "perl $Bin/stat_cycle_info.pl -c $newcycle  -in $dOut/cycle_$newcycle/map/ -loc $dOut/cycle_$newcycle/smooth/$fKey.correct.loc -o $dOut/result/\n"; 
		` perl $Bin/stat_cycle_info.pl -c $newcycle -in $dOut/cycle_$newcycle/map/ -loc $dOut/cycle_$newcycle/smooth/$fKey.correct.loc -o $dOut/result`;             
	}
	close STAMAP;
}else{
	die "un-recognized programs mode";
}


#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
print $log "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
close ($log) ;
# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------

sub printLogHead {#
	my $fh=shift;
	my $user=`whoami`;chomp $user;
	my $program="$Bin/$Script";
	my $time=GetTime();
	my $currentPath=`pwd`;chomp $currentPath;
	my $job="perl $program"."\t".join("\t",@Original_ARGV)."\n";
	print $fh ";==========================================\n";
	print $fh join("\n",(";user: $user",";workDir : $currentPath",";job: $job")),"\n";
	print $fh ";==========================================\n\n";
}

sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub USAGE {#
	my $usage=<<"USAGE";
Program: $0
Version: $version
Contact: Ma chouxian <macx\@biomarker.com.cn> 
Discription:
		-e parameter is very important to muti-cycle correction of genotype matrix.
		
		If too high, false negative increases, while too low, a high proportion of  markers are recognized as suspicious 
		
		ones, these markers are treated as being in a false positon rather than containing error genotypes , Thus these markers\' will not 
		
		be imputed or corrected. The overall effect is minimal.

Usage:
  Options:
  -i	<file>	Locus genotype files, loc or genotype format, forced
  -k	<str>	Key of output file,forced
  -d	<str>	Directory where output file produced,optional,default [./]
  -fix	<file>	fix order optional
  -str	<file>	str order optional
  -e	<float>	Average error ratio of genotype matrix,optional,default [0.06]
  
  -mode	<int>	Programs mode, 0 for single run of program, 1 for running mapping process multiple times, optional, default [0]  
  -n	<int>	Maximum number of cycles when -mode is 1, optional, default [5]  
  -diff_ratio default[0.85]
 
  -h		Help

USAGE
	print $usage;
	exit;
}
