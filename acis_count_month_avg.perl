#!/usr/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	acis_dose_month_avg.perl: create month averaged plots				#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	last update: Feb 14, 2013							#
#											#
#########################################################################################

$comp_test = $ARGV[0];
chomp $comp_test;

######################################################
#
#----- setting directories
#
if($comp_test =~ /test/i){
        $dir_list = '/data/mta/Script/ACIS/Count_rate/house_keeping/dir_list_test';
}else{
        $dir_list = '/data/mta/Script/ACIS/Count_rate/house_keeping/dir_list';
}

open(FH, $dir_list);
while(<FH>){
    chomp $_;
    @atemp = split(/\s+/, $_);
    ${$atemp[0]} = $atemp[1];
}
close(FH);
######################################################

#
#--- find today's date
#
#
#--- find today's date
#
if($comp_test =~ /test/i){
	$tday = 13;
	$tmon = 2;
	$tyear = 2013;
	$uyear = 2013;
	$umon  = $tmon;
}else{
	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

	$uyear += 1900;
	$umon++;
}
open(OUT,">$house_keeping/month_avg_data");

if($comp_test =~ /test/i){
	$tbegin = 2012;
}else{
	$tbegin = 2000;
}
OUTER:
for($year = $tbegin; $year <= $uyear; $year++){
	foreach $mon (JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC){
#
#--- change month name from digits to letters
#
		dig_month_lett();

		if($uyear == $year && $dmon > $umon){
				last OUTER;
		}

		$date = $year + ($dmon -1)/12.0 + 0.04;

		$dir = "$mon"."$year";
		printf OUT  "%4.3f", $date;

#
#--- read each ccd data
#
		for($ic = 0; $ic < 10; $ic++) {

			$ccd   = 'ccd'."$ic";
			open(FH,"$web_dir/$dir/$ccd");

			$sum   = 0;
			$sum2  = 0;
			$count = 0;
		
			while(<FH>){
				chomp $_;
				@atemp     = split(/\t/,$_);
				$atemp[1] /= 300;
				$sum      += $atemp[1];
				$sum2     += $atemp[1] * $atemp[1];
				$count++;
			}
#
#--- compute averages and standard deviations		
#
			$avg = 0;
			$sig = 0;
			unless($count <= 0){
				$avg = $sum/$count;
				$var = $sum2/$count - $avg*$avg;
				$sig = sqrt($var);
			}
			printf OUT  "\t%4.3f+/-%4.3f", $avg, $sig;
		}
		print OUT  "\n";
	}
}
close(OUT);

open(FH, "$house_keeping/month_avg_data");

#
#---initialize
#

@time   = ();
for($ix = 0; $ix < 10; $ix++) {
	@{ccd.$ix} = ();
}

$count = 0;
while(<FH>){
	chomp $_;
	@atemp = split(/\t/,$_);
	$count++;
	push(@time, $atemp[0]);

	for($ix = 1; $ix < 11; $ix++) {
		$cx = $ix - 1;
		push(@{ccd.$cx},$atemp[$ix]);
	}
}
		
$xmin = $time[1] - 0.04;
$xmax = $time[$count - 1];
$ymin = 0;

#
#---- plot imaging CCDs
#

plot_img();

#
#---- plot spec CCDs
#

plot_spec();

#
#---- plot back side CCDs
#

plot_bi();

#############################################################################
### plot_img: plotting imaging CCDs                                       ###
#############################################################################

sub plot_img {
	@temp  = @{ccd.0};
	@temp  = sort{$a<=>$b} @temp;
	$ymax  = $temp[$count-1];
	
	@temp  = @{ccd.1};
	@temp  = sort{$a<=>$b} @temp;
	$ymax1 = $temp[$count-1];

	if($ymax1 > $ymax) {
		$ymax = $ymax1;
	}
	
	@temp  = @{ccd.2};
	@temp  = sort{$a<=>$b} @temp;
	$ymax1 = $temp[$count-1];

	if($ymax1 > $ymax) {
		$ymax = $ymax1;
	}
	
	@temp  = @{ccd.3};
	@temp  = sort{$a<=>$b} @temp;
	$ymax1 = $temp[$count-1];

	if($ymax1 > $ymax) {
		$ymax = $ymax1;
	}
	
	$ymax *= 1.2;
	
	pgbegin(0, "/cps",1,1);
	pgsubp(1,1);
	pgsch(2);
	pgslw(4);

	$output_file = "$web_dir/month_avg_img.ps";
	$xdiff       = 0.25*($xmax - $xmin);
	$xdiff2      = 0.05*($xmax - $xmin);
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	
	foreach $ix (0, 1, 2, 3) {
		@y_val = @{ccd.$ix};
		$point = -1 * $ix - 3;
		$color = $ix + 1;
	
		$xpos  = $xmin + $xdiff * $ix + $xdiff2;
		pgsci($color);
		pgpt(1, $xpos, $ymax * 0.92, $point);
		$ccd   = 'ccd'."$ix";
		pgptxt($xpos + $xdiff2, $ymax * 0.92, 0, 0, $ccd);
	
		pgmove($time[0], $y_val[0]);
		pgpt(1, $time[0], $y_val[0], $point);
		for($im = 0; $im < $count; $im++) {
			unless($y_val[$im] eq '*****' || $y_val[$im] eq ''){
				pgdraw($time[$im], $y_val[$im]);
				pgpt(1, $time[$im], $y_val[$im], $point);
			}
		}
		pgsci(1);
	}
	pglabel("Time (DOM)","counts/sec", "ACIS count rate: Imaging CCDs ");
	pgclos;

	$name = "$web_dir/month_avg_img.gif";

	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $op_dir/pnmflip -r270 |$op_dir/ppmtogif > $name");
	system("rm pgplot.ps");
}

#############################################################################
### plot_spec: plotting spec CCDs                                         ###
#############################################################################

sub plot_spec {
	@temp  = @{ccd.4};
	@temp  = sort{$a<=>$b} @temp;
	$ymax  = $temp[$count-1];
	
	@temp  = @{ccd.6};
	@temp  = sort{$a<=>$b} @temp;
	$ymax1 = $temp[$count-1];

	if($ymax1 > $ymax) {
		$ymax = $ymax1;
	}
	
	@temp  = @{ccd.8};
	@temp  = sort{$a<=>$b} @temp;
	$ymax1 = $temp[$count-1];

	if($ymax1 > $ymax) {
		$ymax = $ymax1;
	}
	
	@temp  = @{ccd.9};
	@temp  = sort{$a<=>$b} @temp;
	$ymax1 = $temp[$count-1];

	if($ymax1 > $ymax) {
		$ymax = $ymax1;
	}
	
	$ymax *= 1.2;
	
	pgbegin(0, "/cps",1,1);
	pgsubp(1,1);
	pgsch(2);
	pgslw(4);
	$output_file = "$web_dir/month_avg_spc.ps";
	$xdiff       = 0.25 * ($xmax - $xmin);
	$xdiff2      = 0.05 * ($xmax - $xmin);
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	
	$ic = 0;
	foreach $ix (4, 6, 8, 9) {
		@y_val = @{ccd.$ix};
		$point = -1 * $ic - 3;
		$color = $ix - 2;
	
		$xpos  = $xmin + $xdiff * $ic + $xdiff2;
		$ic++;
		pgsci($color);
		pgpt(1, $xpos, $ymax * 0.92, $point);
		$ccd   = 'ccd'."$ix";
		pgptxt($xpos + $xdiff2, $ymax * 0.92, 0, 0, $ccd);
	
		pgmove($time[0], $y_val[0]);
		pgpt(1, $time[0], $y_val[0], $point);
		for($im = 0; $im < $count; $im++) {
			unless($y_val[$im] eq '*****' || $y_val[$im] eq ''){
				pgdraw($time[$im], $y_val[$im]);
				pgpt(1,$time[$im], $y_val[$im], $point);
			}
		}
		pgsci(1);
	}
	pglabel("Time (Year)","counts/sec", "ACIS count rate: Front Side Spectroscopic CCDs ");
	pgclos;

	$name = "$web_dir/month_avg_spec.gif";

	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $op_dir/pnmflip -r270 |$op_dir/ppmtogif > $name");
	system("rm pgplot.ps");

}

#############################################################################
### plot_bi: plotting Back side CCDs                                      ###
#############################################################################

sub plot_bi {
	@temp  = @{ccd.5};
	@temp  = sort{$a<=>$b} @temp;
	$ymax  = $temp[$count-1];
	
	@temp  = @{ccd.7};
	@temp  = sort{$a<=>$b} @temp;
	$ymax1 = $temp[$count-1];

	if($ymax1 > $ymax) {
		$ymax = $ymax1;
	}
	
	$ymax *= 1.2;
	
	pgbegin(0, "/cps",1,1);
	pgsubp(1,1);
	pgsch(2);
	pgslw(4);
	$output_file = "$web_dir/month_avg_bi.ps";
	$xdiff       = 0.25*($xmax - $xmin);
	$xdiff2      = 0.05*($xmax - $xmin);
	
	pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);
	
	$ic = 0;
	foreach $ix (5, 7) {
		@y_val = @{ccd.$ix};
		$point = -1 * $ic + 3;
		$pcolor = $ix - 3;
	
		$xpos = $xmin + $xdiff * $ic + $xdiff2;
		$ic++;
		pgsci($pcolor);
		pgpt(1, $xpos, $ymax * 0.92, $point);
		$ccd = 'ccd'."$ix";
		pgptxt($xpos + $xdiff2, $ymax * 0.92, 0, 0, $ccd);
	
		pgmove($time[0], $y_val[0]);
		pgpt(1, $time[0], $y_val[0], $point);

		for($im = 0; $im < $count; $im++) {
#			unless($y_val[$im] eq '*****' || $y_val[$im] eq ''){
			if($time[$im]  > $xmin || $time[$im] < $xmax){
				pgdraw($time[$im], $y_val[$im]);
				pgpt(1,$time[$im], $y_val[$im], $point);
			}
		}
		pgsci(1);
	}
	pglabel("Time (Year)","counts/sec", "ACIS count rate: Back Side Spectroscopic CCDs ");
	pgclos;

	$name = "$web_dir/month_avg_bi.gif";

	system("echo ''|$op_dir/gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $op_dir/pnmflip -r270 |$op_dir/ppmtogif > $name");
	system("rm pgplot.ps");

}


#######################################################
### dig_month_lett: month name from digits to letters #
#######################################################

sub dig_month_lett {
	if($mon =~ /^JAN/i) {
		$dmon = 1;
	}elsif($mon =~ /^FEB/i){
		$dmon = 2;
	}elsif($mon =~ /^MAR/i){
		$dmon = 3;
	}elsif($mon =~ /^APR/i){
		$dmon = 4;
	}elsif($mon =~ /^MAY/i){
		$dmon = 5;
	}elsif($mon =~ /^JUN/i){
		$dmon = 6;
	}elsif($mon =~ /^JUL/i){
		$dmon = 7;
	}elsif($mon =~ /^AUG/i){
		$dmon = 8;
	}elsif($mon =~ /^SEP/i){
		$dmon = 9;
	}elsif($mon =~ /^OCT/i){
		$dmon = 10;
	}elsif($mon =~ /^NOV/i){
		$dmon = 11;
	}elsif($mon =~ /^DEC/i){
		$dmon = 12;
	}
}
