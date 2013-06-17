#!/usr/bin/env /usr/local/bin/perl
use PGPLOT;
#use lib '/home/rpete/local/perlmods/sun4-solaris-thread';
#use lib '/opt/local/lib/perl5/5.00501/sun4-solaris-thread';			#on colossus
#use CFITSIO qw( :shortnames );

#########################################################################################
#											#
#	dose_plot.perl: create acis count rate plots					#
#											#
#	Author: Takashi Isobe (tisobe@cfa.havard.edu)					#
#											#
#	Last Update: Apr 15, 2013							#
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
#----- first find starting and ending dates of the this period and one before
#

check_date();
	
#
#----- change date format 
#

$start_time = "$uyear".'-'."$umon".'-01T00:00:00';

st_change_date_format(); 

#
#---- set date range
#

$month_min = $dom;
$month_max = $month_min + 31;

#
#----  find new data file from /dsops  
#----  the data are saved in @input_data_list
#

get_data_list();

#
#---- check whether the data is in a bad fits file list
#

open(FH, "$house_keeping/bad_fits_file");

@bad_fits_file = ();
while(<FH>){
	chomp $_;	
	push(@bad_fits_file, $_);
}
close(FH);

#
#---- loop for each fits file
#

OUTER:
foreach $file (@input_data_list) {
	@atemp = split(/acis\//,$file);
	$fname = $atemp[1];

#
#--- if it is in a bad fits list, skip it
#
	foreach $comp (@bad_fits_file) {
		if($comp eq $fname) {
			next OUTER;
		}
	}
#
#--- extract data: first check the file is real	
#
						
	system("ls $file > file_test");		
	open(IN, './file_test');
	$in_chk = 0;
	while(<IN>){
		chomp $_;
		if($_ =~ /acisf/){
			$in_chk++;
		}
	}
	close(IN);
	system("rm file_test");

	if($in_chk == 0){
		next OUTER;
	}

#
#-- extract obs date
#

	system("dmlist infile=\"$file\" outfile=\"header\" opt=head");
	open(FH, './header');
	while(<FH>) {
		chomp $_;

		if($_ =~ /DATE-OBS/){
			@atemp      = split (/\s+/, $_);
			$start_time = $atemp[2];

			st_change_date_format();	# change date format
			last;
		}
	}
	close(FH);
	system("rm header");

#
#---- first find out # of rows. devide the data to 1/3 so that we do not use up
#---- memory to save the all the data. then count # of the insidences for each
#---- ccd for 300 sec intervals.
#
	
#
#--- initialize
#
	$t_chk     = 0;	
	$bin_cnt   = 0;
	@time_list = ();
	
    $line = "$file"."[cols time, ccd_id]";
    system("dmlist \"$line\" opt=data > ztemp");
    open(FH, "./ztemp");
	OUTER:
	while(<FH>){
           chomp $_;
           @atemp = split(/\s+/, $_);
           if($atemp[0] =~ /\d/){
		        $time   = $atemp[1];
		        $ccd_id = $atemp[2];
           }elsif($atemp[1] =~ /\d/){
		        $time   = $atemp[2];
		        $ccd_id = $atemp[3];
           }else{
               next OUTER;
           }

		if($time < 1){
			next OUTER;
		}
#
#---- initialization at the begining of data reading (every 300 sec)
#			
		if($t_chk == 0) {
			$t_chk = 1;	
			$start = $time;
			$prev  = $time;
			$sum   = 0;
			$bin_cnt++;

			for($j = 0; $j < 10; $j++) {
				${cnt_ccd.$j.$bin_cnt} = 0;	
			}

			push(@time_list, $start);
#
#--- check wether time inteval reached 300 sec
#
		}else{		
			$sum += $time - $prev;
			$diff = $time - $start;
			$prev = $time;

			if($diff >= 300) {
				$t_chk = 0;
			}
		}
#
#---- accumurate counts for each CCD
#				
		${cnt_ccd.$ccd_id.$bin_cnt}++;
	}
				
			
	for($kval = 0; $kval < 10; $kval++){
		@{sv_ccd.$kval}= ();
#
#---- normalized if the last bin is smaller than a specified size
#
		if($diff < 300) {

			if($irow == 2){
				$ratio = $diff/300;
				${cnt_ccd.$kval.$bin_cnt} = int (${cnt_ccd.$kval.$bin_cnt}/$ratio);
			}
		}
	}
			
	for($ival = 1; $ival <= $bin_cnt; $ival++) {

		for($kval = 0; $kval < 10; $kval++){
			push(@{sv_ccd.$kval},${cnt_ccd.$kval.$ival});
		}
	}

#
#--- changing time to DOM
#						

	$start = $time_list[0];
	@time  = ();
	foreach $time_t (@time_list){
		$ptime = $dom + ($add_time + $time_t - $start)/86400;
		push(@time, $ptime);
	}

#
#--- set time so that the next 1/3 starts from a correct time
#

	$add_time = $add_time + $time_list[$bin_cnt-1] - $start;
	
#
#---- save (print out) data so far collected before goint to the next 1/3 of data set
#

	for($kval = 0; $kval< 10; $kval++) {
		$ccd_name = 'ccd'."$kval";
		@y_val    = @{sv_ccd.$kval};

		open(OUT,">>$mon_name/$ccd_name");

		for($ival = 0; $ival < $bin_cnt; $ival++){
			print OUT  "$time[$ival]\t$y_val[$ival]\n";
		}
		close(OUT);
	}
			
}						#---- fits file group list loop end

#
#---- sort the data and remove duplication
#

if($new_test > 0){
	rm_dupl();	
}
	
############# plotting starts here ################

#
#--- read radiation data
#

@rad_list = ();
open(FH, "$house_keeping/rad_data");	
while(<FH>) {
       	chomp $_;
       	@rad       = split(/\t/,$_);
	$rad_start = $rad[0];
	$rad_end   = $rad[1];
       	push(@rad_start_list, $rad_start);
       	push(@rad_end_list,   $rad_end);
}
close(FH);
	
for($i = 0; $i < 10; $i++) {
	$file  = 'ccd'."$i";
	@time  = ();
	@y_val = ();
	$count = 0;
	open(FH,"$mon_name/$file\n");

	while(<FH>) {
		chomp $_;
		@data = split(/\t/, $_);
		if($data[1] > 0){
			push(@time,  $data[0]);
			push(@y_val, $data[1]/300.0);	
			$count++;
		}
	}
	$xmin = $month_min;
	$xmax = $time[$count-1];
	@temp = sort{$a <=> $b} @y_val;
	$ymin = $temp[0];
	$ymax = $temp[$count-1];

	if($ymin == $ymax){
		if($ymin == 0){
			$ymax = 5;
		}else{
			$ymin = 0;
		}
	}

	$ydel = 0.1*($ymax - $ymin);
	$ymin = 0;
	$ymax = $ymax + $ydel;	
	
	
	pgbegin(0, "/cps",1,1);     
	pgsubp(1,1);              
	pgsch(2);
	pgslw(4);
	$output_file = "acis_dose_ccd_"."$i".'.gif';
	$ccd_name    = 'ccd'."$i";

	plot_fig();
	pgclos;

	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $mon_name/$output_file");
	system("rm pgplot.ps");

}

#
#---- a plot which shows both CCD5 and CCD7
#

plot_comb_5_7();	

#
#--- this is a CCD7 long term plot
#

plot_ccd7();


##################################
### plot_fig: plotting routine ###
##################################

sub plot_fig {

        pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

        pgpt(1, $time[0], $y_val[0], -1);                # plot a point (x, y)
        for($im = 1; $im < $count-1; $im++) {
                unless($y_val[$im] eq '*****' || $y_val[$im] eq ''){
                        pgpt(1,$time[$im], $y_val[$im], -2);
                }
        }
        pglabel("Time (DOM)","counts/sec", "ACIS count rate: $ccd_name ");
							     # write labels

        @temp_list = @rad_end_list;
        foreach $rad_s (@rad_start_list) {
                $rad_e = shift(@temp_list);
                if($rad_s> $xmin && $rad_s < $xmax) {
                        if($rad_e > $xmax){
                                $rad_e = $xmax;
                        }
                        pgsci(2);		#---- color
                        pgsls(4);		#---- line width
                        pgsfs(2);		#---- box fill selection
                        pgrect($rad_s, $rad_e, 0, $ymax);
                        pgsci(1);
                        pgsls(1);
                        pgsfs(1);
                        $y_e = 0.9* $ymax;
                        $test = 'radiation belt';
                        pgptxt($rad_s, $y_e, 90, 0.5, $text);
                }
        }
        pgsci(2);
        $diff = $xmax - $xmin;
        $x_e  = $xmin + $diff/10;
        $diff = $ymax - $ymin;
        $y_s  = $ymax + 0.05*$diff;
        $y_e  = $ymax + 0.1*$diff;
        pgrect($xmin, $x_e, $y_s, $y_e);
        pgsci(1);
}

##########################################################			
## st_change_date_format: change date format to dom   ####			
##########################################################			

sub st_change_date_format {
	@temp  = split(/-/, $start_time);
	$year  = $temp[0];
	$mon   = $temp[1];
	@atemp = split(/T/, $temp[2]);
	$date  = $atemp[0];
	@btemp = split(/:/, $atemp[1]);
	$hour  = $btemp[0];
	$min   = $btemp[1];
	$sec   = $btemp[2];

	$date = $date + $hour/24.0 + $min/1440.0 + $sec/86400.0;
	if($mon == 1){
		$m_day =   0;
	}elsif($mon == 2){
		$m_day =  31;
	}elsif($mon == 3) {
		$m_day =  59;
	}elsif($mon == 4) {
		$m_day =  90;
	}elsif($mon == 5) {
		$m_day = 120;
	}elsif($mon == 6) {
		$m_day = 151;
	}elsif($mon == 7) {
		$m_day = 181;
	}elsif($mon == 8) {
		$m_day = 212;
	}elsif($mon == 9) {
		$m_day = 243;
	}elsif($mon == 10) {
		$m_day = 273;
	}elsif($mon == 11) {
		$m_day = 304;
	}elsif($mon == 12) {
		$m_day = 334;
	}

	if($year == 2000 || $year == 2004 || $year == 2008 
			 || $year == 2012 || $year == 2016 || $year == 2020){
		if($mon > 2) {
			$m_day++;
		}
	}

	$dom = $date + $m_day;
	if($year == 1999) {
		$dom -= 202;
	}else{
		$dom = $dom + 163 + ($year - 2000) * 365;
		if($year > 2000) {
			$dom++;
		}
		if($year > 2004) {
			$dom++;
		}
		if($year > 2008) {
			$dom++;
		}
		if($year > 2012) {
			$dom++;
		}
		if($year > 2016) {
			$dom++;
		}
		if($year > 2020) {
			$dom++;
		}
	}
}
			
####################################################
### rm_dupl: clean up the data set               ###
####################################################
	
sub rm_dupl {

	for($i = 0; $i < 10; $i++) {
		$file = "$mon_name".'/ccd'."$i";
        	open(FH,"$file");
        	@data = ();
        	while(<FH>) {
                	chomp $_;
			@atemp = split(/\t/,$_);
			if($atemp[0] > $month_min && $atemp[0] < $month_max){
                		push(@data, $_);
			}
        	}
        	close(FH);
	
		@sorted_data = sort{$a<=>$b} @data;
        	$comp_line   = shift(@sorted_data);
        	@new_data    = ("$comp_line");

		OUTER:
		foreach $line (@sorted_data){
			foreach $comp (@new_data){
				if($line eq $comp){
					next OUTER;
				}
			}
			push(@new_data, $line);
		}

        	open(OUT," > $file");
        	foreach $line (@new_data) {
                	print OUT "$line\n";
        	}
        	close(OUT);
        	@new_data = ()
	}
}
	
####################################################
### read_time_ccd: extract time and ccd id       ###
####################################################

sub read_time_ccd {
        $datatype  = 82;                #data type
        $firstelem = 1;                 #first element in a vector
        $nulval    = 0;                 #value to represent undefined pixels
        @anynul    = 0;                 #TRUE(=1)if returned values are undefined
        $casesen   = 0;                 #case insensitive

        @time_data = (0..$nelements);
        @ccd_data  = (0..$nelements);

        $colnum = 1;                    #reading time column
        ffgcv($fptr, $datatype, $colnum, $firstrow,
                $firstelem, $nelements, $nulval, \@time_data, $anynul, $status);

        $colnum = 2;                    #reading ccd_id column
        ffgcv($fptr, $datatype, $colnum, $firstrow,
                $firstelem, $nelements, $nulval, \@ccd_data, $anynul, $status);
}



######################################################################################
### check_date: check today's date and if there is no directory for the month, create 
######################################################################################

sub check_date {

#
#--- find about today
#
	if($comp_test =~ /test/i){
		$tday = 13;
		$tmon = 2;
		$tyear = 2013;
		$uyear = 2013;
		$umon  = 2;
	}else{
        	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

        	@input_data_list = ();

        	$tot_ent = 1;
		$uyear  += 1900;
		$umon++;
	
        	$tday  = $umday;
        	$tmon  = $umon;
        	$tyear = $uyear;
	}

        $lday  = $tday - 10;
        $lmon  = $tmon;
        $lyear = $tyear;

        push(@end_year,  $tyear);
        push(@end_month, $tmon);
        push(@end_date,  $tday);

        if($lday < 1) {
                $tot_ent = 2;
                push(@start_year,  $tyear);
                push(@start_month, $tmon);
                push(@start_date,  '1');

                if($tmon == 5 || $tmon == 7 || $tmon == 10 || $tmon == 12) {
                        $lday = 30 + $lday;
                        $lmon  = $tmon - 1;

                        push(@end_year,    $tyear);
                        push(@end_month,   $lmon);
                        push(@end_date,    '30');
                        push(@start_year,  $tyear);
                        push(@start_month, $lmon);
                        push(@start_date,  $lday);

                }elsif($tmon == 2 || $tmon == 4 || $tmon == 6 || $tmon == 8
                        || $mon == 9 || $mon == 11) {
                        $lday = 31 + $lday;
                        $lmon = $tmon -1;

                        push(@end_year,    $tyear);
                        push(@end_month,   $lmon);
                        push(@end_date,    '31');
                        push(@start_year,  $tyear);
                        push(@start_month, $lmon);
                        push(@start_date,  $lday);

                }elsif($tmon == 3) {
                        $lday = 28 + $lday;
                        $lmon = $tmon -1;

                        push(@end_year,    $tyear);
                        push(@end_month,   $lmon);
                        push(@start_year,  $tyear);
                        push(@start_month, $lmon);

#
#--- check a leap year
#
			$ychk = 4 * int (0.25 * $tyear);
			if($tyear == $ychk){
                                $lday++;
                                push(@end_date, '29');
                        }else{
                                push(@end_date, '28');
                        }
                        push(@start_date, $lday);

                }elsif($tmon == 1) {
                        $lday  = 31 + $lday;
                        $lmon  = 12;
                        $lyear = $tyear - 1;

                        push(@end_year,    $lyear);
                        push(@end_month,   $lmon);
                        push(@end_date,    '31');
                        push(@start_year,  $lyear);
                        push(@start_month, $lmon);
                        push(@start_date,  $lday);

                }
        }else{
                push(@start_year,  $lyear);
                push(@start_month, $lmon);
                push(@start_date,  $lday);
        }

        @start_year  = reverse(@start_year);
        @start_month = reverse(@start_month);
        @start_date  = reverse(@start_date);
        @end_year    = reverse(@end_year);
        @end_month   = reverse(@end_month);
        @end_date    = reverse(@end_date);

	$no = 0;
	foreach $ckmonth (@start_month){
		$cmon = $ckmonth;

		month_dig_lett();

		$mon_name = "$web_dir/"."$cmon"."$start_year[$no]";
		$no++;

		system("ls -d  $mon_name > zmon_chk");

		open(FH,'./zmon_chk');
		$dirchk = 0;
		while(<FH>) {
			$dirchk = 1;
		}
		if($dirchk == 0){
			system("mkdir $mon_name");
		}
		close(FH);
		system("rm zmon_chk");
	}
}

######################################################################################
### get_data_list: find new data file from /dsops                                  ###
######################################################################################

sub get_data_list {

#
#---- make a list of evt1 fits files in /dspos/...
#

	if($comp_test =~ /test/i){
        	system("ls -d  /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/ACIS_rad_data/*evt1.fits > file_list");
	}else{
        	system("ls -d  /dsops/ap/sdp/cache/*/acis/*evt1.fits > file_list");
	}
        open(FH,'./file_list');
        @file_list = ();
        while(<FH>){
                chomp $_;
		@atemp    = split(/acisf/,$_);
		@btemp    = split(/_/,$atemp[1]);
		@ctemp    = split(/_/,$_);
		$this_mon = $ctemp[1];
#
#----- use only non-calibration data
#
		if($btemp[0] < 50000 && $this_mon == $umon){
                	push(@file_list,$_);
		}
        }
        close(FH);
#
#---- read the previously processed data
#

        open(FH, "$house_keeping/old_file_list");
        @old_list = ();
        while(<FH>){
                chomp $_;
                push(@old_list, $_);
        }
        close(FH);

#
#---- compare the list with the previous run list and select new data
#
	$new_test = 0;
        OUTER:
        foreach $ent (@file_list){
                foreach $comp (@old_list){
                        if($ent eq $comp){
                                next OUTER;
                        }
                }
                push(@input_data_list, $ent);
		$new_test++;
        }

        system("mv file_list $house_keeping/old_file_list");

}

##################################
## change_date_format:     #######
##################################

sub change_date_format {
        @temp  = split(/:/, $time);
        $year  = $temp[0];
	$date  = $temp[1];
	$hour  = $temp[2];
	$min   = $temp[3];
	$sec   = $temp[4];
	$dom   = $date + $hour/24 + $min/1440.0 + $sec/86400.0;

	if($year == 1999) {
		$dom -= 202;
	}else{
		$dom = $dom + 163 + ($year - 2000)*365;
		if($year > 2000) {
			$dom++;
		}
		if($year > 2004) {
			$dom++;
		}
		if($year > 2008) {
			$dom++;
		}
		if($year > 2012) {
			$dom++;
		}
		if($year > 2016) {
			$dom++;
		}
		if($year > 2020) {
			$dom++;
		}
	}
}

#############################################################
### month_dig_lett: change month name from digit to letter ##
#############################################################

sub month_dig_lett {
	if($cmon == 1){
		$cmon ='JAN';
	}elsif($cmon == 2) {
		$cmon ='FEB';
	}elsif($cmon == 3) {
		$cmon ='MAR';
	}elsif($cmon == 4) {
		$cmon ='APR';
	}elsif($cmon == 5) {
		$cmon ='MAY';
	}elsif($cmon == 6) {
		$cmon ='JUN';
	}elsif($cmon == 7) {
		$cmon ='JUL';
	}elsif($cmon == 8) {
		$cmon ='AUG';
	}elsif($cmon == 9) {
		$cmon ='SEP';
	}elsif($cmon == 10) {
		$cmon ='OCT';
	}elsif($cmon == 11) {
		$cmon ='NOV';
	}elsif($cmon == 12) {
		$cmon ='DEC';
	}
}

############################################
### plot_ccd7: plot ccd 7 all past history #
############################################

sub plot_ccd7 {

#
#----- gather all past data points of CCD7
#
	system("ls $web_dir/*/ccd7 > zhtml_list");

	open(FH,'./zhtml_list');
	while(<FH>){
		chomp $_;
		system("cat $_ >> comb_data");
	}
	close(FH);
	system("rm zhtml_list");

	@time      = ();
	@y_val     = ();
	@comb_data = ();
	$count     = 0;
	open(FH,"./comb_data");
	while(<FH>) {
		chomp $_;
		push(@comb_data, $_);
	}
	close(FH);
	system("rm comb_data");

	@data = sort{$a<=>$b} @comb_data;

	foreach $ent (@data) {
		@temp = split(/\t/,$ent);
		if($temp[1] > 0){
			push(@time,  $temp[0]);
			push(@y_val, $temp[1]/300.0);
			$count++;
		}
	}
	$xmin = $time[10];
	$xmax = $time[$count-1];
	@temp = sort{$a <=> $b} @y_val;
	$ymin = $temp[0];
	$ymax = $temp[$count-1];

	if($ymin == $ymax){
		if($ymin == 0){
			$ymax = 5;
		}else{
			$ymin = 0;
		}
	}

	$ydel = 0.1*($ymax - $ymin);
	$ymin = 0;
	$ymax = $ymax + $ydel;


	pgbegin(0, "/ps",1,1);
	pgsubp(1,1);
	pgsch(2);
	pgslw(4);
	$output_file = 'acis_ccd7_dose_plot.gif';
	$ccd_name = 'ccd7';
	plot_fig_ccd7();
	pgclos();

	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $web_dir/$output_file");

	system("rm pgplot.ps");
}

########################################
### plot_fig_ccd7: plotting routine  ###
########################################

sub plot_fig_ccd7 {

        pgenv($xmin, $xmax, $ymin, $ymax, 0, 0);

        pgpt(1, $time[0], $y_val[0], -1);                # plot a point (x, y)
        for($m = 1; $m < $count-1; $m++) {
                unless($y_val[$m] eq '*****' || $y_val[$m] eq ''){
                        pgpt(1,$time[$m], $y_val[$m], -2);
                }
        }
        pglabel("Time (DOM)","counts/sec", "ACIS count rate: $ccd_name ");
                                                             # write labels
}


#######################################################
### plot_comb_5_7: plot out CCD5&7 comb data        ###
#######################################################

sub plot_comb_5_7 {

	$dir = $mon_name;
	pgopen("/cps");
	pgsubp(1,3);
	pgsch(2);
	pgslw(4);
	
	$pnlcnt = 0;
	open(FH, "$dir/ccd5");
	@time    = ();
	@y_val   = ();
	$count   = 0;

	while(<FH>) {
        	chomp $_;
        	@data = split(/\s/, $_);
		if($data[1] > 0){
        		push(@time,  $data[0]);
        		push(@y_val, $data[1]/300.0);
        		$count++;
		}
	}
	close(FH);

	$xmin     = $month_min;
	$xmax     = $time[$count-1];
	$ymin     = 0;
	$ymax     = 100;
	$ccd_name = "ccd5";
	plot_fig2();
	
	pgsch(2);
	pgslw(4);

	open(FH,"$dir/ccd6");
	@time = ();
	@y_val = ();
	$count = 0;

	while(<FH>) {
        	chomp $_;
        	@data = split(/\t/,$_);
        	push(@time,  $data[0]);
        	push(@y_val, $data[1]/300.0);
        	$count++;
	}
	close(FH);

	$ymin = 0;
	$ymax = 60;
	$ccd_name = "ccd6";
	plot_fig2();
	
	pgsch(2);
	pgslw(4);
	open(FH, "$dir/ccd7");
	@time  = ();
	@y_val = ();
	$count = 0;
	while(<FH>) {
        	chomp $_;
        	@data = split(/\t/,$_);
        	push(@time,  $data[0]);
        	push(@y_val, $data[1]/300.0);
        	$count++;
	}
	close(FH);
	$ymin     = 0;
	$ymax     = 100;
	$ccd_name = "ccd7";

	plot_fig2();

	pgclos;
	
	system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| pnmflip -r270 |ppmtogif > $dir/acis_dose_ccd_5_7.gif");
###	system("rm pgplot.ps");
	
}

##################################
### plot_fig2: plotting routine ##
##################################

sub plot_fig2 {

        pgpage;
        pgswin($xmin, $xmax,$ymin, $ymax);

        if($pnlcnt == 0){
                pgbox('BCT', 0.0, 0, 'BCNTV',0.0,  0);
        }elsif($pnlcnt == 1){
                pgbox('BCT', 0.0, 0, 'BCNTV',0.0,  0);
        }elsif($pnlcnt = 2){
                pgbox('BCNT', 0.0, 0, 'BCNTV',0.0,  0);
        }

        pgpt(1, $time[0], $y_val[0], -1);                # plot a point (x, y)
        for($mx = 1; $mx < $count-1; $mx++) {
                unless($y_val[$mx] eq '*****' || $y_val[$mx] eq ''){
                        pgpt(1,$time[$mx], $y_val[$mx], -2);
                }
        }
        $xd   = $xmax - $xmin;
        $xpos = $xmin + 0.05*$xd;
        $ypos = 1.05 * $ymax;
        pgtext($xpos,$ypos,"$ccd_name");

        if($pnlcnt == 0){
                pglabel('   ','counts/sec', 'ACIS count rate: CCD 5-7');
                $pnlcnt++;
        }elsif($pnlcnt == 1){
                pglabel('','counts/sec', '  ');
                $pnlcnt++;
        }elsif($pnlcnt = 2){
                pglabel('Time (DOM)','counts/sec', '  ');
        }
                                                             # write labels
        @temp_list = @rad_end_list;
        foreach $rad_s (@rad_start_list) {
                $rad_e = shift(@temp_list);
                if($rad_s> $xmin && $rad_s < $xmax) {
                        if($rad_e > $xmax){
                                $rad_e = $xmax;
                        }
                        pgsci(2);
                        pgsls(4);
                        pgsfs(2);
                        pgrect($rad_s, $rad_e, 0, $ymax);
                        pgsfs(3);
                        pgrect($rad_s, $rad_e, 0, $ymax);
                        pgsci(0);
                        pgsls(1);
                        pgsfs(1);
                        $y_e = 0.9* $ymax;
                        $text = 'radiation belt';
                        pgptxt($rad_s, $y_e, 90, 0.5, $text);
                }
        }
        pgsci(2);
        $diff = $xmax - $xmin;
        $x_e  = $xmin + $diff/10;
        $diff = $ymax - $ymin;
        $y_s  = $ymax + 0.05 * $diff;
        $y_e  = $ymax + 0.1  * $diff;
        pgrect($xmin, $x_e, $y_s, $y_e);
        pgsci(1);
}

