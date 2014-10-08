#!/usr/bin/env /proj/sot/ska/bin/python

#################################################################################################
#                                                                                               #
#        print_html_page.py update/create html page related acis does plots                     #
#                                                                                               #
#               author: t. isobe (tisobe@cfa.harvard.edu)                                       #
#                                                                                               #
#               Last Update: Oct 29, 2013                                                       #
#                                                                                               #
#################################################################################################

import os
import sys
import re
import string
import random
import operator
import math

#
#--- check whether this is a test case
#
comp_test = 'live'
if len(sys.argv) == 2:
    if sys.argv[1] == 'test':   #---- test case
        comp_test = 'test'
    elif sys.argv[1] == 'live': #---- automated read in
        comp_test = 'live'
    else:
        comp_test = sys.argv[1].strip() #---- input data name
#
#--- reading directory list
#
if comp_test == 'test' or comp_test == 'test2':
    path = '/data/mta/Script/ACIS/Count_rate/house_keeping/dir_list_py_test'
else:
    path = '/data/mta/Script/ACIS/Count_rate/house_keeping/dir_list_py'
#    path = '/data/mta/Script/ACIS/Count_rate/house_keeping2/dir_list_py'

f= open(path, 'r')
data = [line.strip() for line in f.readlines()]
f.close()

for ent in data:
    atemp = re.split(':', ent)
    var  = atemp[1].strip()
    line = atemp[0].strip()
    exec "%s = %s" %(var, line)
#
#--- append  pathes to private folders to a python directory
#
sys.path.append(bin_dir)
sys.path.append(mta_dir)
#
#--- import several functions
#
import convertTimeFormat          as tcnv       #---- contains MTA time conversion routines
import mta_common_functions       as mcf        #---- contains other functions commonly used in MTA scripts

#
#--- temp writing file name
#
rtail  = int(10000 * random.random())       #---- put a romdom # tail so that it won't mix up with other scripts space
zspace = '/tmp/zspace' + str(rtail)

#--------------------------------------------------------------------------------------
#--- print_html_page:  print all html pages for ACIS Dose Plots                     ---
#--------------------------------------------------------------------------------------

def print_html_page(comp_test, in_year=1, in_mon=1):
    """
    driving function to print all html pages for ACIS Dose Plots
    Input:  comp_test --- test indicator. if it is "test", it will run the test version
            in_year/in_mon --- if in_year and in_mon are given, the file is created for 
                               that year/month, otherwise, the files are created in the current year/month
    Output: html pages in <web_dir> and <web_dir>/<mon_dir_name>  (e.g. JAN2013)
    """

#
#---  find today's date and convert them appropriately
#
    if comp_test == 'test':
        bchk  = 0
        tday  = 13;
        umon  = 2;
        uyear = 2013;

        cmon  = tcnv.changeMonthFormat(umon)
        cmon  = cmon.upper()
        ldate = str(uyear) + '-' + str(umon) + '-' + str(tday)          #-- update date
    else:
#
#--- find today's date
#
        [uyear, umon, tday, hours, min, sec, weekday, yday, dst] = tcnv.currentTime()
#
#--- change month in digit into letters
#
        cmon  = tcnv.changeMonthFormat(umon)
        cmon  = cmon.upper()
        ldate = str(uyear) + '-' + str(umon) + '-' + str(tday)          #-- update date
#
#--- if year and month is given, create for that month. otherwise, create for this month
#
        bchk = 0
        if mcf.chkNumeric(in_year) and mcf.chkNumeric(in_mon):
            if in_year > 1900 and (in_mon >0 and in_mon < 13):
                bchk = 1
        if bchk > 0:
            uyear = in_year
            umon  = in_mon
            cmon  = tcnv.changeMonthFormat(umon)
            cmon  = cmon.upper()

    mon_dir_name = cmon + str(uyear);

#
#--- check whether this monnth web page already opens or not
#
    dname = web_dir + mon_dir_name
    chk   = mcf.chkFile(dname)

    if chk > 0:
        if bchk == 0:
#
#-- create only when it is working for the current month
#
            print_main_html(ldate, uyear, umon);

        print_month_html(mon_dir_name, ldate, uyear, umon);

        print_png_html(mon_dir_name, ldate, uyear, umon);
#
#--- change permission level and the owner of the files
#
        cmd = 'chgrp mtagroup ' + web_dir + '/* ' + web_dir + '/*/*'
        os.system(cmd)
        cmd = 'chmod 755 '+ web_dir + '/* ' + web_dir + '/*/*'
        os.system(cmd)


#--------------------------------------------------------------------------------------
#--- print_main_html: printing the main acis dose html page                         ---
#--------------------------------------------------------------------------------------

def print_main_html(ldate, this_year, this_month):

    """
    printing the main acis dose html page
    Input:  ldate      --- date of update
            this_year  --- current year in digit
            this_month --- current month in digit

    Output: <web_dir>/main_acis_dose_plot.html
    """
    line = '<!DOCTYPE html>\n'
    line = line + '<html>\n'
    line = line + '<head>\n'
    line = line + '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n'
    line = line + '<style  type="text/css">\n'
    line = line + 'table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n'
    line = line + 'td{text-align:center;padding:8px}\n'
    line = line + '\n'
    line = line + 'a:link {color:#00CCFF;}\n'
    line = line + 'a:visited {color:yellow;}\n'
    line = line + '\n'
    line = line + 'span.nobr {white-space:nowrap;}\n'
    line = line + '</style>\n'
    line = line + '<title>ACIS Count Rate Plots </title>\n'
    line = line + '<script>\n'
    line = line + 'function MyWindowOpener(imgname) {\n'
    line = line + '    msgWindow=open("","displayname","toolbar=no,directories=no,menubar=no,location=no,scrollbars=no,status=no,width=732,height=560,resize=yes");\n'
    line = line + '    msgWindow.document.close();\n'
    line = line + '    msgWindow.document.write("<!DOCTYPE html>");\n'
    line = line + '    msgWindow.document.write("<html><head><title>Bias plot:   "+imgname+"</title></head>");\n'
    line = line + '    msgWindow.document.write("<<meta http-equiv=\'Content-Type\' content=\'text/html; charset=utf-8\' />");\n'
    line = line + '    msgWindow.document.write("<body style=\'background-color:white\'>");\n'
    line = line + '    msgWindow.document.write("<img src=\'./mta_days/mta_dose_count2/"+imgname+"\' style=\"width:692px;height:540px\"></body></html>");\n'
    line = line + '    msgWindow.focus();\n'
    line = line + '}\n'
    line = line + '</script>\n'





    line = line + '</head>\n'
    line = line + '<body style="color:#FFFFFF;background-color:#000000;">\n'

    line = line + '<h2 style="color:aqua;text-align:center">ACIS Dose Plots</h2>\n'
    line = line + '<h3 style="text-align:center">Last Update: ' + ldate + '</h3>\n'
    line = line + '<hr />\n'

#
#--- the links to long term plots
#
    line = line + '<h3>Long Term Trend Plots</h3>\n'
    line = line + '<p style="text-align:center">\n'
    line = line + '<a href="javascript:MyWindowOpener(\'./long_term_plot.png\')"><img src="./long_term_plot.png" style="text-align:center; width: 60%"></a>\n'
    line = line + '</p>\n'

    line = line + '<h3>Monthly Averaged Plots</h3>\n'
    line = line + '<p style="padding-bottom:20px">\n'

    line = line + '<a href=./month_avg_img.html>Imaging CCDs</a><br />\n'
    line = line + '<a href=./month_avg_spec.html>Front Side Spec CCDs</a><br />\n'
    line = line + '<a href=./month_avg_bi.html>Back Side Spec CCDs</a><br />\n'
    line = line + '</p>\n'
    line = line + '<p style="padding-top:20px;padding-bottom:20px"><b> Please Select A Period</b> </p>\n'
#
#--- table explanation
#
    line = line + '<p>\n'
    line = line + 'The following tabless list links to  plots of photon count rates  (counts/sec) for averages of 5min intervals against time (DOM).\n'
    line = line + 'They are simple photon counts for each CCD and not a back ground photon counts; \n'
    line = line + 'it means that no sources are removed from the computation.\n'
    line = line + '</p>\n'
    line = line + '\n'
#
#--- first table from year 2010 to current
#
    
    line = line + '<div style="padding-top:40px"></div>\n'
    line = line + '<table border=1>\n'
    line = line + '<tr>\n'
    line = line + '<th>Year</th>\n'

    for iyear in range(2010, this_year+1):
        line = line +  '<th><b>' + str(iyear) + '</b></th>\n'

    line = line +  '</tr>' + "\n"

    idiff = this_year - 2009

    for dmon in range(1, 13):

        cmon = tcnv.changeMonthFormat(dmon)
        cmon = cmon.upper()
        lmon = cmon.lower()

        line = line +  '<tr><th>' + cmon + '</th>'

        for ix in range(0, idiff):
            dyear     = 2010 + ix

            if ix < idiff -1:

                line = line +  '<td>';
                line = line +  '<a href=./'+ cmon + str(dyear) + '/acis_' + lmon + str(dyear) + '_dose_plot.html>'
                line = line +  cmon + ' ' +  str(dyear) + '</a></td>\n';

            elif ix >= idiff-1:

                if dmon > this_month:
                    line = line + '<td>---</td>\n'
                else:
                    line = line + '<td>'
                    line = line + '<a href=./' + cmon + str(dyear) + '/acis_'+ lmon + str(dyear) + '_dose_plot.html>'
                    line = line + cmon + str(dyear) + '</a></td>\n'

        line = line +  '</tr>\n'
        
    line = line +  '</table>\n'

    line = line + '<div style="padding-bottom:40px"> </div>\n'

#
#--- second table from year 2000 to 2009
#
    
    line = line + '<table border=1>\n'
    line = line + '<tr>\n'
    line = line + '<th>Year</th>\n'

    for iyear in range(2000, 2010):
        line = line +  '<th><b>' + str(iyear) + '</b></th>\n'

    line = line + '</tr>' + "\n"

    for dmon in range(1, 13):

        cmon = tcnv.changeMonthFormat(dmon)
        cmon = cmon.upper()
        lmon = cmon.lower()
        line = line +  '<tr><th>' + cmon + '</th>'

        for ix in range(0, 10):
            dyear     = 2000 + ix

            line = line +  '<td>';
            line = line +  '<a href=./'+ cmon + str(dyear) + '/acis_' + lmon + str(dyear) + '_dose_plot.html>'
            line = line +  cmon + ' ' + str(dyear) + '</a></td>\n';

        line = line +  '</tr>\n'
        
    line = line +  '</table>\n'
#
#--- links to monthly data files
#
    line = line + '<h3>Monthly Average Data</h3>\n'

    line = line + '<div style="padding-top:20px;padding-bottom:20px;text-align:left">\n'
    line = line + '<table border = 1><tr>\n'
    for ccd in range(0, 10):
       line = line + '<th>CCD ' + str(ccd) + '</th>'
    line = line + '</tr>\n'
    for ccd in range(0, 10):
        line = line + '<td><a href="monthly_avg_data_ccd' + str(ccd) + '.dat">Data</td>\n'

    line = line + '</tr></table>\n'
    line = line + '</div>\n'


    line = line + '<hr />\n'
    line = line + '<p style="padding-top:10px;padding-bottom:40px">\n'
    line = line + 'If you have any questions about this page, please contact <a href='
    line = line + '"mailto:tisobe@cfa.harvard.edu">tisobe@cfa.harvard.edu</a>.\n'
    line = line + '</p>'

	
    line = line + '</body>\n'
    line = line + '</html>\n'
#
#--- print the page
#
    file  = web_dir + '/main_acis_dose_plot.html'
    f     = open(file, 'w')
    f.write(line)
    f.close()


#--------------------------------------------------------------------------------------
#--- print_month_html: printing html page for each month                            ---
#--------------------------------------------------------------------------------------

def print_month_html(mon_dir_name, ldate, this_year, this_month):

    """
    printing html page for each month
    Input:  mon_dir_name --- a directory in which the plots are kept
            ldate        --- date of update
            this_year    --- current year in digit
            this_month   --- current month in digit

    Output: <web_dir>/<mon_dir_name>/acis_<lmon><year>_dose_plot.html
    """
    cmon = tcnv.changeMonthFormat(this_month)
    cmon = cmon.upper()
    lmon = cmon.lower()

    line = '<!DOCTYPE html>\n'
    line = line + '<html>\n'
    line = line + '<head>\n'
    line = line + '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n'
    line = line + '<style  type="text/css">\n'
    line = line + 'table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n'
    line = line + 'td{text-align:center;padding:8px}\n'
    line = line + '\n'
    line = line + 'a:link {color:#00CCFF;}\n'
    line = line + 'a:visited {color:yellow;}\n'
    line = line + '\n'
    line = line + 'span.nobr {white-space:nowrap;}\n'
    line = line + '</style>\n'
    line = line + '<title>ACIS Count Rate Plots </title>\n'
    line = line + '</head>\n'
    line = line + '<body style="color:#FFFFFF;background-color:#000000;">\n'

    line = line + '<h2 style="text-align:center;color:aqua">ACIS Count Rate Plot: ' + cmon + ', ' + str(this_year) + '</h2>\n'
    line = line + '<h3 style="text-align:center">Created on ' + ldate + '</h3>\n'
    line = line + '<hr />\n'
    line = line + '<p><b> Please Select CCD:</b> </p>\n'
    line = line + '<table  border=0 style="margin-left:auto;margin-right:auto">\n'
    line = line + '<tr><th style="font-size:110%">Plot</td><th style="font-size:110%">Data</td></tr>\n'

    for ccd in range(0, 10):
        line = line + '<tr><td><a href="./acis_dose_ccd' + str(ccd) + '.html">CCD ' + str(ccd) + ' Plot</a></td>' 
        line = line + '<td><a href="./ccd' + str(ccd) + '">CCD ' + str(ccd) + ' Data</a></td></tr>\n'

    line = line + '<td><a href="./acis_dose_ccd_5_7.html">CCDs 5 - 7 Plot</a></td><td>&#160</td></tr>\n'
    line = line + '<td><a href="./ephin_rate.html">Ephin Count Rate Plot</a></td><td><a href="./ephin_rate">Ephin Data</a></td></tr>\n'
    line = line + '</table>\n'


    line = line + '<p style="padding-top:15px;padding-bottom:15px">To check a dose map, please go to <a href=https://cxc.cfa.harvard.edu/mta/REPORTS/MONTHLY/'
    line = line +  str(this_year) + cmon +  '/MONTHLY.html>' + cmon + ' ' +  str(this_year) + ' Monthly Report</a>.</p>\n'

    line = line +  '<p>Back to <a href=../main_acis_dose_plot.html>Main Page</a>\n'
    line = line + '</body>\n</html>\n'

    cmon = tcnv.changeMonthFormat(this_month)
    cmon = cmon.upper()
    lmon = cmon.lower()

    name = web_dir + '/' + mon_dir_name + '/acis_' + lmon + str(this_year) + '_dose_plot.html'
    f    = open(name, 'w')
    f.write(line)
    f.close()


#--------------------------------------------------------------------------------------
#--- print_png_html: print html pages for png files                                 ---
#--------------------------------------------------------------------------------------

def    print_png_html(mon_dir_name, ldate, this_year, this_month):

    """
    printing html pages for png files
    Input:  mon_dir_name --- a directory in which the plots are kept
            ldate        --- date of update
            this_year    --- current year in digit
            this_month   --- current month in digit
    Output: <web_dir>/<html_name>.html
            <web_dir>/<mon_dir_name>/<html_name>.html
    """

    nlist = ('month_avg_img', 'month_avg_spc', 'month_avg_bi', 'long_term_plot', 'acis_dose_ccd0', \
		     'acis_dose_ccd1', 'acis_dose_ccd2','acis_dose_ccd3', 'acis_dose_ccd4', 'acis_dose_ccd5', \
             'acis_dose_ccd6', 'acis_dose_ccd7', 'acis_dose_ccd8', 'acis_dose_ccd9', 'acis_dose_ccd_5_7',\
             'ephin_rate')

    for name in nlist:
        html_name = name + '.html'
        png_name  = name + '.png'

        line = '<!DOCTYPE html>\n'
        line = line + '<html>\n'
        line = line + '<head>\n'
        line = line + '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n'
        line = line + '<style  type="text/css">\n'
        line = line + 'table{text-align:center;margin-left:auto;margin-right:auto;border-style:solid;border-spacing:8px;border-width:2px;border-collapse:separate}\n'
        line = line + 'td{text-align:center;padding:8px}\n'
        line = line + '\n'
        line = line + 'a:link {color:#00CCFF;}\n'
        line = line + 'a:visited {color:yellow;}\n'
        line = line + '\n'
        line = line + 'span.nobr {white-space:nowrap;}\n'
        line = line + '</style>\n'
        line = line + '<title>ACIS Count Rate Plots: ' + name + ' </title>\n'
        line = line + '</head>\n'
        line = line + '<body style="color:#FFFFFF;background-color:#000000;">\n'

        line = line + '<img src="./' + png_name + '" style="text-align:center; width:90%;padding-bottom:30px">\n'
        line = line + '<hr />\n'
        line = line + '<h3 style="padding-top:20px">Last Update: ' + ldate + '</h3>\n'
        line = line + '</body>\n</html>\n'


        m1 = re.search('month', name)
        m2 = re.search('long', name)

        if (m1 is not None) or (m2 is not None):
            file = web_dir + '/' + html_name
        else:
            file = web_dir + '/' + mon_dir_name + '/' + html_name

        f    = open(file, 'w')
        f.write(line)
        f.close()

#--------------------------------------------------------------------------------------

if __name__ == "__main__":

    print_html_page(comp_test='no')
