#!/usr/bin/perl

#########################################################################
#									#
#	print_html.perl: create html pages for count rate plots		#
#									#
#	author:	Isobe Takashi (tisobe@cfa.harvard.edu)			#
#									#
#	last update: Mar 21, 2011   					#	
#									#
#########################################################################

######################################################
#
#----- setting directories
#

open(FH, '/data/mta/Script/ACIS/Count_rate/house_keeping/dir_list');
@atemp = ();
while(<FH>){
        chomp $_;
        push(@atemp, $_);
}
close(FH);

$bin_dir       = $atemp[0];
$bdata_dir     = $atemp[1];
$web_dir       = $atemp[2];
$hosue_keeping = $atemp[3];

######################################################

#
#---  find today's date and convert them appropriately
#

($usec, $umin, $uhour, $umday, $umon, $uyear, $uwday, $uyday, $uisdst)= localtime(time);

$uyear += 1900;
$umon++;
$cmon   = $umon;

#
#--- change month in digit into letters
#

month_dig_lett();

$mon_dir_name = "$cmon"."$uyear";

#
#--- check whether this monnth web page already opens or not
#

print_main_html();

print_month_html();

print_gif_html();


system("chgrp mtagroup $web_dir/* $web_dir/*/*");


#####################################################################
### print_main_html: printing the main acis dose html page        ###
#####################################################################

sub print_main_html{

	open(OUT, ">$web_dir/main_acis_dose_plot.html");

	print OUT '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="red" VLINK="red" ';
	print OUT "\n";
	print OUT 'ALINK="yellow" background="./stars.jpg">';
	print OUT "\n";
	print OUT '<title> ACIS Count Rate Plots </title>';
	print OUT "\n";
	
	print OUT "\n";
	print OUT '<CENTER><H1><font color="aqua" size="+5">ACIS Dose Plots</font></CENTER></CENTER>';
	print OUT "\n";
	
	print OUT '<CENTER><H3>Last Update: ',"$uyear-$umon-$umday",'</H3></CENTER>';
	print OUT "\n";
	print OUT '<HR>';
	print OUT "\n";
	print OUT '<P>';
	print OUT "\n";
	print OUT 'The followings are plots of photon counts/sec for averages of 5min ';
	print OUT "\n";
	print OUT 'intervals against time (DOM).';
	print OUT "\n";
	
	print OUT "\n";
	print OUT 'They are simple photon counts for each CCD and not a back ground photon counts;';
	print OUT "\n";
	print OUT 'it means that no sources are removed from the computation.';
	print OUT "\n";
	
	
	print OUT '</P>';
	print OUT "\n";
	
	print OUT '<P> Please Select A Period </P>';
	print OUT "\n";
	

        print OUT '<CENTER>',"\n";
        print OUT '<TABLE BORDER=1 CELLPADDING=5>';

        print OUT '<TR>';
        print OUT '<TH>Year</TH>',"\n";

        for($iyear = 2000; $iyear<$uyear+1; $iyear++) {
                print OUT '<TD ALIGN=center><b>',"$iyear",'</b></TD>';
        }

        print OUT '</TR>',"\n";

        $idiff = $uyear - 2000 + 1;

        for($dmon = 1;$dmon < 13; $dmon++){
		$cmon = $dmon;

		month_dig_lett();

		$lmon = $cmon;
                print OUT '<TR>';
                print OUT '<TH>',"$lmon",'</TH>';

                for($ix = 0; $ix < $idiff; $ix++){
                        $dyear = 2000 + $ix;
                        $file_name = "$lmon".'_'."$dyear".'.html';

                        if($ix < $idiff -1){
				$cmon = $dmon;

				month_dig_lett();

				$lmo = lc($cmon);
				print OUT '<TD>';
				print OUT '<A HREF=./',"$cmon"."$dyear",'/acis_',"$lmo","$dyear",'_dose_plot.html>';
				print OUT "\n";
				print OUT "$cmon",',',"$dyear",'</A>';
				print OUT '</TD>';
				print OUT "\n";

                        }elsif($ix >= $idiff -1){

                                if($dmon > $umon){
					print OUT '<TD>';
                                        print OUT '---';
					print OUT '</TD>';
					print OUT "\n";

                                }else{
					$cmon = $dmon;

					month_dig_lett();

					$lmo = lc($cmon);
					print OUT '<TD>';
					print OUT '<A HREF=./',"$cmon"."$dyear",'/acis_',"$lmo","$dyear",'_dose_plot.html>';
					print OUT "\n";
					print OUT "$cmon",',',"$dyear",'</A>';
					print OUT '</TD>';
					print OUT "\n";
                                }
                        }
                }
                print OUT '</TR>',"\n";
        }
        print OUT '</TABLE></FORM></BODY></HTML>',"\n";
        print OUT '</CENTER>',"\n";


	print OUT '<font size=-1>',"\n";
	print OUT '<P>';
	print OUT "\n";
	print OUT '<A HREF=./long_term_plot.html>Photon Counts since Jan 2000</A>';
	$cmon = $umon;

	month_dig_lett();

	print OUT "\n";
	print OUT '</P>';
	print OUT "\n";
	print OUT '<P>',"\n";
	print OUT 'Monthly Averaged Plots:<Br>',"\n";
	print OUT '<A HREF=./month_avg_img.html>Imaging CCDs</A><Br>',"\n";
	print OUT '<A HREF=./month_avg_spec.html>Front Side Spec CCDs</A><Br>',"\n";
	print OUT '<A HREF=./month_avg_bi.html>Back Side Spec CCDs</A><Br>',"\n";
	print OUT '</P>',"\n";
	
	close(OUT);
}


########################################################################################
### print_month_html: printing html page for each month                              ###
########################################################################################

sub print_month_html{
	$cmon = $umon;

	month_dig_lett();

	$lmon = lc ($cmon);

	$name            = "$web_dir".'/'."$mon_dir_name". '/acis_'."$lmon"."$uyear".'_dose_plot.html';

	open(OUT,">$name");

	print OUT '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="red" VLINK="red" ALINK="yellow" background="./stars/jpg">',"\n";
	print OUT '<title> ACIS Count Rate Plots </title>',"\n";
	print OUT '<CENTER><H1><font color="aqua">ACIS Count Rate Plots: ';
	print OUT "$cmon, $uyear",'</font></CENTER>',"\n";
	print OUT '<CENTER><H3>Created on: ',"$uyear-$umon-$umday",'</H3></CENTER>',"\n";
	print OUT '<HR>',"\n";
	print OUT '<P> Please Select CCD: </P>',"\n";
	print OUT '<font size="+4">',"\n";
	print OUT '<TABLE Boder = 0 width = 400 align = center>',"\n";
	print OUT '<TR>',"\n";
	print OUT '<TD><font size=+3>Plot</font></TD><TD><font size=+3>Data</font></TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./acis_dose_ccd_2.html>CCD 2 Plot</TD>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ccd2>CCD 2 Data</TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./acis_dose_ccd_3.html>CCD 3 Plot</TD>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ccd3>CCD 3 Data</TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./acis_dose_ccd_4.html>CCD 4 Plot</TD>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ccd4>CCD 4 Data</TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./acis_dose_ccd_5.html>CCD 5 Plot</TD>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ccd5>CCD 5 Data</TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./acis_dose_ccd_6.html>CCD 6 Plot</TD>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ccd6>CCD 6 Data</TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./acis_dose_ccd_7.html>CCD 7 Plot</TD>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ccd7>CCD 7 Data</TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./acis_dose_ccd_8.html>CCD 8 Plot</TD>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ccd8>CCD 8 Data</TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./acis_dose_ccd_9.html>CCD 9 Plot</TD>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ccd9>CCD 9 Data</TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./acis_dose_ccd_5_7.html>CCDs 5 - 7 Plot</TD>';
	print OUT "\n";
	print OUT '<TD></TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '<TR>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ephin_rate.html>Ephin Count Rate Plot</TD>';
	print OUT "\n";
	print OUT '<TD><A HREF=./ephin_rate>Ephin Data </TD>';
	print OUT "\n";
	print OUT '</TR>';
	print OUT "\n";
	print OUT '</TABLE>';
	print OUT "\n";
	print OUT '</font>';
	print OUT "\n";

	print OUT '<P>';
	print OUT "\n";
	print OUT 'To check a dose map, please go to';
	print OUT "\n";
	print OUT '<A HREF=http://asc.harvard.edu/mta/REPORTS/MONTHLY/';
	print OUT "\n";
	print OUT "$cmon","$uyear",'/MONTHLY.html>',"$cmon",' monthly report';
	print OUT "\n";
	print OUT '</A>.';
	print OUT "\n";
	print OUT '</P>';
	print OUT "\n";
	print OUT '<P>';
	print OUT "\n";
	print OUT '<font size=4>';
	print OUT "\n";
	print OUT 'Back to <A HREF=../main_acis_dose_plot.html>a main page</a>';
	print OUT "\n";
	print OUT '</font>';
	print OUT "\n";
	print OUT '</P>';
	print OUT "\n";
	close(OUT);
}

########################################################
### print_gif_html: print html pages for gif files   ###
########################################################

sub print_gif_html{

	foreach $name (
		'month_avg_img', 'month_avg_spec', 'month_avg_bi', 'long_term_plot', 'acis_dose_ccd_2', 
		'acis_dose_ccd_3', 'acis_dose_ccd_4', 'acis_dose_ccd_5', 'acis_dose_ccd_6', 
		'acis_dose_ccd_7', 'acis_dose_ccd_8', 'acis_dose_ccd_9', 'acis_dose_ccd_5_7', 
		'ephin_rate'){
		$html_name = "$name".'.html';
		$gif_name  = "$name".'.gif';

		if($name =~ /month/ || $name =~ /long/){
			open(OUT, ">$web_dir/$html_name");
		}else{
			open(OUT, ">$web_dir/$mon_dir_name/$html_name");
		}

		print OUT '<HTML><BODY TEXT="#FFFFFF" BGCOLOR="#000000" LINK="red" VLINK="red" ';
		print OUT "\n";
		print OUT 'ALINK="yellow" background="./stars.jpg">';
		print OUT "\n";
		print OUT '<title> ACIS Count Rate Plots: ',"$name",' </title>';
		print OUT "\n";
		
		print OUT "<img src = './$gif_name', height=600, width=900>";
		
		print OUT '<HR>',"\n";
		print OUT '<H3>Last Update: ',"$uyear-$umon-$umday",'</H3>';
		print OUT "\n";
		
		print OUT '</html>';

		close(OUT);
	}
}

#########################################################
### month_dig_lett: change month from digits to letters #
#########################################################

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

