#!/usr/bin/perl

use PGPLOT;
use lib '/home/rpete/local/perlmods/sun4-solaris-thread';
#use lib '/opt/local/lib/perl5/5.00501/sun4-solaris-thread';			#on colossus
use CFITSIO qw( :shortnames );

#########################################################################################
#                                                                                       #
#       acis_dose_ephin_plot.perl: plot ephin data					#
#                                                                                       #
#	author: t. isobe (tisobe@cfa.harvard.edu)					#
#											#
#	Last Update: Jul 06, 2006							#
#                                                                                       #
#########################################################################################

######################################################
#
#----- setting directories
#

$bin_dir       = '/data/mta4/MTA/bin/';
$data_dir      = '/data/mta4/MTA/data/';
$web_dir       = '/data/mta/www/mta_dose_count/';
$house_keeping = "/data/mta_www/mta_dose_count/house_keeping/";

######################################################

#
#--- find today's date
#
	check_date();
#
#--- find which data we need
#
        get_data_list(); 
#
#--- loop around each fits file
#

foreach $file (@input_data_list) {

#
#--- flist to extract data
#

        system("dmlist infile=\"$file\" outfile=\"header\" opt=head");
        open(FH, './header');
        while(<FH>) {
                chomp $_;

                if($_ =~ /DATE-OBS/){
                        @atemp      = split (/\s+/, $_);
                        $start_time = $atemp[2];

                        st_change_date_format();        # change date format
                        last;
                }
        }
        close(FH);
        system("rm header");

#
#--- here we are using fitsio routines
#
	
	$read_file = "$file".'[1]';
	$iomode = 0;
	$status = 0;

	ffopen($fptr, $read_file, $iomode, $status); 	# open file, fptr: pointer
	ffgnrw($fptr, $nrow, $status);            	# get the table row number

	$incl       = 0.3 * $nrow;
	$incl       = int ($incl);
	$add_time   = 0;
	$start_save = 0;
#
#--- handle data table 1/3 at a time
#
	OUTER2:
	for($irow = 0; $irow < 3; $irow++){
		$firstrow  = $irow*$incl + 1;
		$nelements = $incl;
		if($irow == 2){
			$nelements = $nrow - 2.0 * $incl;
		}
#
#--- reading time and ephin rates (using fits tools)
#

		read_ephin_rate();

		if($irow == 0){
			$t_chk     = 0;
			$bin_cnt   = 0;
			@time_list = ();
		}
		
		OUTER:
		for($i = 0; $i < $nelements; $i++) {
			$time       = $time_data[$i];
			$p4_data    = $p4_rate[$i];
			$e150_data  = $e150_rate[$i];
			$e300_data  = $e300_rate[$i];
			$e1300_data = $e1300_rate[$i];
			if($time < 1){
				next OUTER;
			}
			
			if($t_chk == 0) {
				$t_chk = 1;
				$start = $time;
				$prev  = $time;
				$sum   = 0;
				$bin_cnt++;
				${cnt_p4.$bin_cnt}    = 0;
				${cnt_e150.$bin_cnt}  = 0;
				${cnt_e300.$bin_cnt}  = 0;
				${cnt_e1300.$bin_cnt} = 0;
				push(@time_list, $start);
			}else{
				$sum += $time - $prev;
				$diff = $time - $start;
				$prev = $time;
				if($diff >= 300) {
					$t_chk = 0;
				}
			}
			
			${cnt_p4.$bin_cnt}    += $p4_data;
			${cnt_e150.$bin_cnt}  += $e150_data;
			${cnt_e300.$bin_cnt}  += $e300_data;
			${cnt_e1300.$bin_cnt} += $e1300_data;
		}
				
#	
#--- normalized if the last bin is smaller than a specified size
#
			
		if($diff < 300) {
			if($irow == 2){
				$ratio = $diff/300;
				${cnt_p4.$bin_cnt}    = ${cnt_p4.$bin_cnt}   /$ratio;
				${cnt_e150.$bin_cnt}  = ${cnt_e150.$bin_cnt} /$ratio;
				${cnt_e300.$bin_cnt}  = ${cnt_e300.$bin_cnt} /$ratio;
				${cnt_e1300.$bin_cnt} = ${cnt_e1300.$bin_cnt}/$ratio;
			}else{
				next OUTER2;
			}
		}
				
		@cnt_p4_save    = ();
		@cnt_e150_save	= ();
		@cnt_e300_save	= ();
		@cnt_e1300_save	= ();

		for($ival = 1; $ival <= $bin_cnt; $ival++) {
			push(@cnt_p4_save,    ${cnt_p4.$ival});
			push(@cnt_e150_save,  ${cnt_e150.$ival});
			push(@cnt_e300_save,  ${cnt_e300.$ival});
			push(@cnt_e1300_save, ${cnt_e1300.$ival});
		}
				
		$start = $time_list[0];
#
#--- changing time to DOM
#
		@time  = ();
		foreach $time_t (@time_list){
			$ptime = $dom + ($add_time + $time_t - $start)/86400;
			push(@time, $ptime);
		}

		$add_time = $add_time+ $time_list[$bin_cnt-1] - $start;

#
#--- so that the next 1/3 starts from a correct time
#
		
		open(OUT,">>$mon_name/ephin_rate");
		for($ival = 0; $ival < $bin_cnt; $ival++){
			print OUT  "$time[$ival]\t";
			print OUT  "$cnt_p4_save[$ival]\t";
			print OUT  "$cnt_e150_save[$ival]\t";
			print OUT  "$cnt_e300_save[$ival]\t";
			print OUT  "$cnt_e1300_save[$ival]\n";
		}
		close(OUT);
				
	}		#1/3 of filts files loop
#
#--- closing cfitsio file
#

	ffclos($fptr, $status);

}			# each fits file group loop

#
#--- sort the data and remove duplication
#
	
rm_dupl();			#sort the data and remove duplication


############# plotting starts here ################

#
#--- read radioation data
#

@rad_list = ();
open(FH, "$web_dir/rad_data");
while(<FH>) {
       	chomp $_;
       	@rad       = split(/\t/,$_);
       	$rad_start = $rad[0];
       	$rad_end   = $rad[1];
       	push(@rad_start_list, $rad_start);
       	push(@rad_end_list,   $rad_end);
}
close(FH);
	
pgopen("/cps");
pgsubp(1,4);
pgsch(2);
pgslw(4);

$pnlcnt = 0;
open(FH,"$mon_name/ephin_rate");
@time  = ();
@p4    = ();
@e150  = ();
@e300  = ();
@e1300 = ();
$count = 0;
while(<FH>) {
	chomp $_;
	@data = split(/\t/,$_);
       	unless($data[1] =~ /\d/){
               	$data[1] = 0;
       	}
       	unless($data[2] =~ /\d/){
               	$data[2] = 0;
       	}
       	unless($data[3] =~ /\d/){
               	$data[3] = 0;
       	}
       	unless($data[4] =~ /\d/){
               	$data[4] = 0;
       	}

	push(@time,  $data[0]);
	push(@p4,    $data[1]/300);
	push(@e150,  $data[2]/300);
	push(@e300,  $data[3]/300);
	push(@e1300, $data[4]/300);
	$count++;
}
close(FH);

$xmin  = $month_min;
$xmax  = $time[$count -1];

@temp  = sort{$a <=> $b} @p4;
$ymin  = $temp[0];
$ymin  = 0;
$ymax  = 100;
@y_val = @p4;
$text  = 'P4 Rate';

plot_fig();
	
@temp  = sort{$a <=> $b} @e150;
$ymin  = $temp[0];
$ymin  = 0;
$ymax  = 300;
@y_val = @e150;
$text  = 'E150 Rate';
plot_fig();
	
@temp  = sort{$a <=> $b} @e300;
$ymin  = $temp[0];
$ymin  = 0;
$ymax  = 100;
@y_val = @e300;
$text  = 'E300 Rate';
plot_fig();


@temp  = sort{$a <=> $b} @e1300;
$ymin  = $temp[0];
$ymin  = 0;
$ymax  = 25;
@y_val = @e1300;
$text  = 'E1300 Rate';
plot_fig();
	
pgclos;
	
system("echo ''|gs -sDEVICE=ppmraw  -r256x256 -q -NOPAUSE -sOutputFile=-  pgplot.ps| $bin_dir/pnmflip -r270 |$bin_dir/ppmtogif > $mon_name/ephin_rate.gif");

system("rm pgplot.ps");

##################################
### plot_fig: plotting routine ###
##################################

sub plot_fig {

        pgpage;
        pgswin($xmin, $xmax,$ymin, $ymax);

        if($pnlcnt == 0){
                pgbox('BCT',  0.0, 0, 'BCNTV',0.0, 0);
        }elsif($pnlcnt == 1){
                pgbox('BCT',  0.0, 0, 'BCNTV',0.0, 0);
        }elsif($pnlcnt == 2){
                pgbox('BCT',  0.0, 0, 'BCNTV',0.0, 0);
        }elsif($pnlcnt == 3){
                pgbox('BCNT', 0.0, 0, 'BCNTV',0.0, 0);
        }

        pgpt(1, $time[0], $y_val[0], -1);                # plot a point (x, y)

        for($im = 1; $im < $count-1; $im++) {

                unless($y_val[$im] eq '*****' || $y_val[$im] eq ''){
                        pgpt(1,$time[$im], $y_val[$im], -2);
                }
        }
        if($pnlcnt == 0){
                pglabel('   ', 'counts/sec', 'Ephin Rates');
                $pnlcnt++;

        }elsif($pnlcnt == 1){
                pglabel('', 'counts/sec', '  ');
                $pnlcnt++;

        }elsif($pnlcnt == 2){
                pglabel('', 'counts/sec', '  ');
                $pnlcnt++;

        }elsif($pnlcnt == 3){
                pglabel('Time (DOM)', 'counts/sec', '  ');

        }

#
#---- plotting radiation zones
#

        @temp_list = @rad_end_list;
        foreach $rad_s (@rad_start_list) {
                $rad_e = shift(@temp_list);
                if($rad_s> $xmin && $rad_s < $xmax) {
                        if($rad_e > $xmax){
                                $rad_e = $xmax;
                        }
                        pgsci(2);
                        pgsls(4);
                        pgsfs(4);
                        pgrect($rad_s, $rad_e, 0, 0.05 * $ymax);
                        pgsci(1);
                        pgsls(1);
                        pgsfs(1);
                }
        }
        pgsci(2);
        $diff = $xmax-$xmin;
        $x_e  = $xmin + $diff/10;
        $diff = $ymax-$ymin;
        $y_s  = $ymax + 0.05*$diff;
        $y_e  = $ymax + 0.1*$diff;
        pgsfs(4);
        pgrect($xmin,$x_e,$y_s,$y_e);
        pgsfs(1);
        pgsci(1);


        $y_e = 0.9* $ymax;
	$x_e = $xmin + 0.1*($xmax - $xmin);
        pgtext($x_e, $y_e, $text);
}

##################################			
## st_change_date_format:  #######			
##################################			

sub st_change_date_format {
	@temp  = split(/-/,$start_time);
	$year  = $temp[0];
	$mon   = $temp[1];
	@atemp = split(/T/,$temp[2]);
	$date  = $atemp[0];
	@btemp = split(/:/,$atemp[1]);
	$hour  = $btemp[0];
	$min   = $btemp[1];
	$sec   = $btemp[2];

	$date = $date + $hour/24.0 + $min/1440.0 + $sec/86400.0;
	if($mon == 1){
		$m_day = 0;
	}elsif($mon == 2){
		$m_day = 31;
	}elsif($mon == 3) {
		$m_day = 59;
	}elsif($mon == 4) {
		$m_day = 90;
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
	if($year == 2000 || $year == 2004 || $year == 2008 || $year == 2012){
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
### rm_dupl: removing duplicated lines           ###
####################################################
	
sub rm_dupl {

	open(FH,"$mon_name/ephin_rate");
	@data = ();
	while(<FH>) {
        	chomp $_;
        	push(@data, $_);
	}
	close(FH);
	
	@sorted_data = sort{$a<=>$b} @data;
       	$first_line = shift(@sorted_data);
       	@new_data  = ("$first_line");

       	OUTER:
       	foreach $line (@sorted_data) {
               	foreach $comp (@new_data) {
                       	if ($line eq $comp) {
                               	next OUTER;
                       	}
               	}
               	push(@new_data, $line);
       	}

       	open(OUT,">ephin_rate_clean");
       	foreach $line (@new_data) {
               	print OUT "$line\n";
       	}
       	close(OUT);
	system("mv $mon_name/ephin_rate $mon_name/ephin_rate~");
	system("mv ./ephin_rate_clean   $mon_name/ephin_rate");
       	@new_data = ()
}
	
####################################################
###read_ephin_rate: readin ephin rates           ###
####################################################

sub read_ephin_rate {

#
#--- we assume that the following lines are already processed before this
#--- sub is called
#---        ffopen($fptr, $read_file, $iomode, $status);    # open file, fptr: pointer
#---        ffgnrw($fptr, $nrow, $status);                  # get the table row number
#--- and after finishing everything, you also need to call closing fits toot
#---	    ffclos($fptr, $status);
#


        $datatype   = 82;                # data type
        $firstelem  = 1;                 # first element in a vector
        $nulval     = 0;                 # value to represent undefined pixels
        @anynul     = 0;                 # TRUE(=1)if returned values are undefined
        $casesen    = 0;                 # case insensitive

        @time_data  = (0..$nelements);
        @p4_data    = (0..$nelements);
        @e150_data  = (0..$nelements);
        @e300_data  = (0..$nelements);
        @e1300_data = (0..$nelements);
#
#--- reading time column
#
        $colnum = 1;
        ffgcv($fptr, $datatype, $colnum, $firstrow,
                $firstelem, $nelements, $nulval, \@time_data, $anynul, $status);
#
#--- reading P4 rate column
#
        $colnum = 3; 
        ffgcv($fptr, $datatype, $colnum, $firstrow,
                $firstelem, $nelements, $nulval, \@p4_rate, $anynul, $status);
#
#--- reading E150 rate column
#
        $colnum = 7;
        ffgcv($fptr, $datatype, $colnum, $firstrow,
                $firstelem, $nelements, $nulval, \@e150_rate, $anynul, $status);
#
#--- reading #300 rate column
#
        $colnum = 8;
        ffgcv($fptr, $datatype, $colnum, $firstrow,
                $firstelem, $nelements, $nulval, \@e300_rate, $anynul, $status);
#
#--- reading E1300 rate column
#
        $colnum = 9;
        ffgcv($fptr, $datatype, $colnum, $firstrow,
                $firstelem, $nelements, $nulval, \@e1300_rate, $anynul, $status);
}

#######################################################################################
### check_date: check today's date and if there is no directory for the month, create #
#######################################################################################

sub check_date {
#
#--- find today' date
#
        ($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

        @input_data_list = ();

        $tot_ent = 1;
	$uyear  += 1900;
	$umon++;

        $tday    = $umday;
        $tmon    = $umon;
        $tyear   = $uyear;


        $lday    = $tday - 10;
        $lmon    = $tmon;
        $lyear   = $tyear;

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
#
#--- set start and end time
#

		$start_time = "$uyear".'-'."$cmon".'-01T00:00:00';
		st_change_date_format();

		$month_min = $dom;
		$month_max = $month_min + 31;
#
#--- change month name from digit to letters
#

		month_dig_lett();

		$mon_name = "$web_dir/"."$cmon"."$start_year[$no]";
#
#--- check whether a directory $mon_name exists; if not, create one
#
		$no++;
		system("ls $mon_name > zmon_chk");
		open(FH,'./zmon_chk');
		$dirchk = 0;
		while(<FH>) {
			$dirchk = 1;
		}
		system("rm zmon_chk");

		if($dirchk == 0){
			system("mkdir $mon_name");
		}
		close(FH);
	}
}

######################################################################################
### get_data_list: find new data file from /dsops                                 ####
######################################################################################

sub get_data_list {

        system("ls -d  /dsops/ap/sdp/cache/*/ephin/*lc1.fits > $house_keeping/ephin_dir_list");
        open(FH, "$house_keeping/ephin_dir_list");
        @dir_list = ();
        while(<FH>){
                chomp $_;
                push(@dir_list, $_);
        }
        close(FH);

        open(FH, "$house_keeping/ephin_old_dir_list");
        @old_list = ();
        while(<FH>){
                chomp $_;
                push(@old_list, $_);
        }
        close(FH);

        $ncnt = 0;
        foreach $ent (@old_list){
                $ncnt++;
        }
        $old_last = $old_list[$ncnt-1];

        @input_data_list = ();
        $ent             = "start";

        OUT:
        while($ent =~ /\w/){
                $ent = pop(@dir_list);
                if($ent eq $old_last){
                        last OUT;
                }
                push(@input_data_list, $ent);
        }

        system("mv $house_keeping/ephin_dir_list $house_keeping/ephin_old_dir_list");
}

	
##################################
## change_date_format:     #######
##################################

sub change_date_format {
	my ($time, $year, $date, $hour, $min, $sec, @temp);

	($time) = @_;

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
	}
}

###########################################################
### month_dig_lett: change digit month to letter month  ###
###########################################################

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
