#!/proj/axaf/bin/perl
use PGPLOT;

#########################################################################################
#											#
#	radiation_data.perl: extract radiation data					#
#											#
#	NOTE: THIS SCRIPT DOES NOT PRODUCE ANY MEANINGFUL DATA ANY MORE. FOR THE TEST	#
#	      THIS SCRIPT SETS UP THE OUTPUT DIRECTORY, BUT DOES NOT GET ANY RADIATION	#
#	      DATA. IF YOU LIKE TO SEE THE RADIATION DATA GO TO INTERRUPT. 		#
#		(T. I. FEB 13, 2013)							#
#											#
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	Last Update: Feb 13, 2013							#
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
#--- if this is a test case, create a test output directory
#


if($comp_test =~ /test/i){
	system("mkdir $web_dir");
	system("mkdir $web_dir/house_keeping");
	
	system("cp /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/ephin_old_dir_list $web_dir/house_keeping/.");
	system("cp /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/month_avg_data     $web_dir/house_keeping/.");
	system("cp /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/old_file_list      $web_dir/house_keeping/.");
	system("cp /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/rad_data           $web_dir/house_keeping/.");
	
	system("cp -r /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/JAN2013         $web_dir/");
	system("cp -r /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/FEB2013         $web_dir/");
}

exit 1;			#---- this script cannot get any more data from the given data directory; so terminate at here. 

#
#--- this check starting and ending dates of the this period and one before
#

check_date();

#
#--- here looping around possible periods; two periods if last 10 days go over two different months
#

for($m = 0; $m < $tot_ent; $m++){  
        $syear  = $start_year[$m];
        $smonth = $start_month[$m];
        $sday   = $start_date[$m];
        $eyear  = $end_year[$m];
        $emonth = $end_month[$m];
        $eday   = $end_date[$m];

#
#--- update radiation data
#
        get_rad_data(); 
}

			
######################################################################################
### check_date: check starting and ending dates of the this period and one before ####
######################################################################################

sub check_date {

#
#--- find today's date
#
	if($comp_test =~ /test/i){
		$tday = 13;
		$tmon = 2;
		$tyear = 2013;
	}else{
        	($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

        	$tot_ent = 1;
		$uyear  += 1900;
		$umon++;

        	$tday  = $umday;
        	$tmon  = $umon;
        	$tyear = $uyear;
	}

        @input_data_list = ();

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
                        $lday  = 30 - $lday;
                        $lmon  = $tmon - 1;

                        push(@end_year,    $tyear);
                        push(@end_month,   $lmon);
                        push(@end_date,    '30');
                        push(@start_year,  $tyear);
                        push(@start_month, $lmon);
                        push(@start_date,  $lday);

                }elsif($tmon == 2 || $tmon == 4 || $tmon == 6 || $tmon == 8
                        || $mon == 9 || $mon == 11) {
                        $lday = 31 - $lday;
                        $lmon = $tmon -1;

                        push(@end_year,    $tyear);
                        push(@end_month,   $lmon);
                        push(@end_date,    '31');
                        push(@start_year,  $tyear);
                        push(@start_month, $lmon);
                        push(@start_date,  $lday);

                }elsif($tmon == 3) {
                        $lday = 28 - $lday;
                        $lmon = $tmon -1;

                        push(@end_year,    $tyear);
                        push(@end_month,   $lmon);
                        push(@start_year,  $tyear);
                        push(@start_month, $lmon);

			$tchk = 4.0 * int($tyear/4.0);
			if($tchk == $tyear){
                                $lday++;
                                push(@end_date, '29');
                        }else{
                                push(@end_date, '28');
                        }
                        push(@start_date, $lday);

                }elsif($tmon == 1) {
                        $lday  = 31 - $lday;
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
}


##########################################################################
### get_rad_data: extract rad date for a specified period              ###
##########################################################################

sub get_rad_data {

#
#--- get the month in digit
#
        $cmon = $smonth;
        month_dig_lett();
#
#--- actual radiation extract sub script
#
        get_rad();

        @rad_data = ();
        open(FH, "$house_keeping/rad_data");

        while(<FH>) {
                chomp $_;
                push(@rad_data, $_);
        }
        close(FH);

        @temp = @rad_data;
#
#--- remove duplicated lines
#
        rad_b_rm_dupl();

        open(OUT, ">$house_keeping/rad_data");
        foreach $ent (@new_save){
                print OUT "$ent\n";
        }

}

#########################################################################
### get_rad: extract radiation data for a given period                ###
#########################################################################

sub get_rad {
	
	if($comp_test =~ /test/i){
		system("ls -d /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/Test_input/FEB* > ./zdata_list");
	}else{
		$cmon = "$cmon".'*';
		system("ls -d  /data/mpcrit1/mplogs/$syear/$cmon > ./zdata_list");
	}
	
	@data_list = ();
	open(FH,'./zdata_list');
	while(<FH>) {
		chomp $_;
		push(@data_list, $_);
	}
	close(FH);
	system("rm zdata_list");
	
	@radzone_entry = ();
	@radzone_exit  = ();
	$fchk          = 0;				# indicator to read the first line
	$entry_cnt     = 0;
	$exit_cnt      = 0;
	$last_time     = 0;
	
	foreach $dir (@data_list) {
		$name = `ls $dir/ofls/*.dot`;
		open(FH, "$name");
		while(<FH>) {
			chomp $_;
			@atemp = split(/\,/, $_);
			if($atemp[1] eq '2_RADZONE_ENTRY') {

				@btemp = split(/ /, $atemp[2]);
				@ctemp = split(/=/, $btemp[0]);
				$time  = $ctemp[1];

				change_date_format();

				push(@radzone_entry, $dom);
				$entry_cnt++;

			}elsif($atemp[1] eq '2_RADZONE_EXIT') {

				@btemp = split(/ /, $atemp[2]);
				@ctemp = split(/=/, $btemp[0]);
				$time  = $ctemp[1];

				change_date_format();

				push(@radzone_exit, $dom);
				$exit_cnt++;

			}elsif($fchk == 0) {

				@btemp = split(/TIME=/, $_);
				@ctemp = split(/:/, $btemp[1]);

				if($ctemp[0] =~ /\d/) {
					@ctemp = split(/ /, $btemp[1]);
					$time  = $ctemp[0];

					change_date_format();

					$start_time = $dom;
					$fchk = 1;
				}
			}

			@btemp = split(/TIME=/, $_);
			@ctemp = split(/:/, $btemp[1]);

			if($ctemp[0] =~ /\d/) {
				@ctemp = split(/ /, $btemp[1]);
				$time  = $ctemp[0];

				change_date_format();

				if($dom > $last_time){
					$last_time = $dom;
				}
			}
		}
	}
	
	@temp          = @radzone_entry;
	rad_b_rm_dupl();
	@radzone_entry = @new_save;
	$entry_cnt     = $cnt;
	
	@temp          = @radzone_exit;
	rad_b_rm_dupl();
	@radzone_exit  = @new_save;
	$exit_cnt      = $cnt;
	
	@temp          = ();
	$cnt           = 1;
	$comp = $radzone_entry[$entry_cnt-1];
	push(@temp, $comp);

	for($j = 1; $j < $entry_cnt; $j++){
		$i    = $entery_cnt - $j - 1;
		$diff = $comp - $radzone_entry[$i];

		if(abs($diff) > 2.4) {
			unshift(@temp, $radzone_entry[$i]);
			$comp = $radzone_entry[$i];
			$cnt++;
		}
	}
	
	@radzone_entry = @temp;
	$entry_cnt     = $cnt;
	
	@temp          = ();
	$cnt           = 1;
	$comp          = $radzone_exit[$exit_cnt-1];
	push(@temp,$comp);

	for($j = 1; $j < $exit_cnt; $j++){
		$i    = $exit_cnt - $j - 1;
		$diff = $comp - $radzone_exit[$i];

		if(abs($diff) > 2.4) {
			unshift(@temp, $radzone_exit[$i]);
			$comp = $radzone_exit[$i];
			$cnt++;
		}
	}
	
	@radzone_exit = @temp;
	$exit_cnt     = $cnt;
	
	for($i = 0;$i == $entry_cnt; $i++){
		$data_ind[$i] = 0;
	}
	
	if($radzone_entry[$entry_cnt -1] > $radzone_exit[$exit_cnt -1]) {
		push(@radzone_exit, $last_time);
		$exit_cnt++;
		$data_ind[$entry_cnt-1] = 2;
	}
	
	if($radzone_entry[0] > $radzone_exit[0]) {
		unshift(@radzone_entry, $start_time);
		$entry_cnt++;
		$data_ind[0] = 1;
	}
#
#--- just in a case, the data  has some problem.....
#	
	if($radzone_entry[0] < 0) {		
		$radzone_entry[0] = $radzone_exit[0];	
	}

	if($radzone_exit[$entry_cnt-1] < 0){
		$radzone_exit[$entry_cnt-1] = $radzone_entry[$entry_cnt-1];
	}

	open(OUT,">>$house_keeping/rad_data");
	for($i = 0;$i < $entry_cnt; $i++) {
		print OUT "$radzone_entry[$i]\t$radzone_exit[$i]\n";
	}
	close(OUT);
}
	
	
##################################
## change_date_format:     #######
##################################

sub change_date_format {
        @temp  = split(/:/,$time);
        $year  = $temp[0];
	$date  = $temp[1];
	$hour  = $temp[2];
	$min   = $temp[3];
	$sec   = $temp[4];
	$dom   = $date + $hour/24 + $min/1440.0 + $sec/86400.0;

	if($year == 1999) {
		$dom -= 202;
	}else{
		$dom = $dom + 163 + ($year - 2000) * 365;
		$add = int(0.25 * ($year - 1997));
		$dom += $add;
	}
}

########################################
### rad_b_rm_dupl: remove duplication  #
########################################

sub rad_b_rm_dupl {
	@save     = sort{$a<=>$b} @temp;
	@new_save = shift(@save);
	$cnt      = 1;

	OUTER:
	foreach $ent (@save){
		foreach $comp (@new_save){
			if($ent == $comp){
				next OUTER;
			}
		}
		push(@new_save, $ent);
		$cnt++;
	}
}

######################################
######################################
######################################

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
