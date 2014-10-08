#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################################
#                                                                                                       #
#   update_data_files.py: update/create ACIS count rate data sets                                       #
#                                                                                                       #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                                   #
#                                                                                                       #
#           Last Update: Ict 02, 2014                                                                   #
#                                                                                                       #
#########################################################################################################

import os
import sys
import re
import string
import random
import operator
import math
import numpy
import pyfits
import unittest

#
#--- reading directory list
#
path = '/data/mta/Script/ACIS/Count_rate/house_keeping/dir_list_py'

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


#---------------------------------------------------------------------------------------------------
#--- update_data_files: main function to run all function to create/update ACIS Dose Plots       ---
#---------------------------------------------------------------------------------------------------

def update_data_files():
    """
    main function to run all function to create/update ACIS Dose Plots
    Input:  none, but data are extracted according to current date
    Output: all data, plots, and html 
    """

    (uyear, umon, mon_name) = check_date()          #--- mon_name is this month's data/plot directory
    dir_save = [mon_name]

#
#--- ACIS count rate data
#
    data_list = get_data_list()

    for file in data_list:
#
#--- check when the data is created
#
        (tyear, tmonth, tdate) = find_date_obs(file)
        if tyear == 1900:
            continue
#
#--- choose an appropriate output directory
#
        cmonth    = tcnv.changeMonthFormat(tmonth)      #--- convert digit to letter month
        ucmon     = cmonth.upper()
        tmon_name = web_dir + '/' + ucmon + str(tyear)
#
#--- if the directory is not the current output directory (mon_name), add to dir_list
#
        chk = 0
        for test in dir_save:
            if tmon_name == test:
                chk = 1
                break
        if chk == 0:
            dir_save.append(tmon_name)
#
#--- now actually extract data and update/create the count rate data
#
#        try:
        extract_data(file, tmon_name)
#        except:
#            pass
#
#--- EPHIN count rate data
#
    data_list = get_ephin_list()

    for file in data_list:
#        try:
        (tyear, tmonth, tdate) = find_date_obs(file)
        if tyear == 1900:
            continue

        cmonth    = tcnv.changeMonthFormat(tmonth) 
        ucmon     = cmonth.upper()
        tmon_name = web_dir + '/' + ucmon + str(tyear)

        chk = 0
        for test in dir_save:
            if tmon_name == test:
                chk = 1
                break
        if chk == 0:
            dir_save.append(tmon_name)

        extract_ephin_data(file, tmon_name)
#        except:
#            pass

#
#-- clean the data files
#
    for ent in dir_save:
        cleanUp(ent)

    return dir_save

#---------------------------------------------------------------------------------------------------
#--- check_date: check wether there is an output directory and if it is not, create one          ---
#---------------------------------------------------------------------------------------------------

def check_date(comp_test=''):

    """
    check wether there is an output directory and if it is not, create one
    Input:  comp_test --- if it is "test", the test data is used
    Output: uyear     --- the current year
            umon      --- the current month
            mon_name  --- the current output direcotry (if it is not there, created)
    """

    start_year  = []
    start_month = []
    start_date  = []
    end_year    = []
    end_month   = []
    end_date    = []
    tot_ent     = 1

    if comp_test == 'test':
#
#--- test case, date is fixed
#
        tyear = 2013
        tmon  = 2
        tday  = 13
        uyear = tyear
        umon  = tmon
    else:
#
#--- find today's date
#
        [uyear, umon, uday, hours, min, sec, weekday, yday, dst] = tcnv.currentTime()
        tyear = uyear
        tmon  = umon
        tday  = uday

    end_year.append(tyear)
    end_month.append(tmon)
    end_date.append(tday)
#
#--- check 10 days ago
#
    lday  = tday - 10
    lmon  = tmon
    lyear = tyear

    if lday < 1:
#
#--- if 10 days ago is the last month, set starting time in the last month
#
        tot_ent = 2
        start_year.append(tyear)
        start_month.append(tmon)
        start_date.append(1)

        if tmon == 5 or tmon == 7 or tmon == 10 or tmon == 12:
            lday += 30
            lmon  =  tmon - 1

            end_year.append(tyear)
            end_month.append(lmon)
            end_date.append(30)
            start_year.append(tyear)
            start_month.append(lmon)
            start_date.append(lday)

        elif tmon == 2 or tmon == 4 or tmon == 6 or tmon == 8 or tmon == 9 or tmon == 11:
            lday += 31
            lmon  = tmon - 1

            end_year.append(tyear)
            end_month.append(lmon)
            end_date.append(31)
            start_year.append(tyear)
            start_month.append(lmon)
            start_date.append(lday)

        elif tmon == 3:
#
#--- last month is in Feb
#
            fday = 28
            if tcnv.isLeapYear(tyear) > 0:
                fday = 29

            lday += fday 
            lmon  = tmon -1

            end_year.append(tyear)
            end_month.append(lmon)
            end_date.append(fday)
            start_year.append(tyear)
            start_month.append(lmon)
            start_date.append(lday)
            
        elif tmon == 1:
#
#--- last month is the year before
#
            lday += 31
            lmon  = 12
            lyear = tyear -1

            end_year.append(tyear)
            end_month.append(lmon)
            end_date.append(31)
            start_year.append(tyear)
            start_month.append(lmon)
            start_date.append(lday)
    else:
#
#--- 10 days ago is in the same month
#
        start_year.append(lyear)
        start_month.append(lmon)
        start_date.append(lday)
#
#--- reverse the list
#
    start_year.reverse()
    start_month.reverse()
    start_date.reverse()
    end_year.reverse()
    end_month.reverse()
    end_date.reverse()
#
#--- start checking whether directory exists. if not create it
#
    no = 0
    for dmon in(start_month):
        cmonth = tcnv.changeMonthFormat(dmon)      #--- convert digit to letter month
        ucmon  = cmonth.upper()

        mon_name = web_dir + '/' + ucmon + str(start_year[no])
        no += 1
        chk = mcf.chkFile(mon_name)
        if chk == 0:
            cmd = 'mkdir ' + mon_name
            os.system(cmd)


    return (uyear, umon, mon_name)

#---------------------------------------------------------------------------------------------------
#-- get_data_list: compare the current input list to the old one and select data                 ---
#---------------------------------------------------------------------------------------------------

def get_data_list(comp_test=''):

    """
    compare the current input list to the old one and select out the data which are not used
    Input:  comp_test  --- if it is "test" the test data is used
            house_keeping/old_file_list --- previous data list
            house_keeping/bad_fits_file --- bad fits data list

            the data are read from /dsops/ap/sdp/cache/*/acis/*evt1.fits (if it is an actual run)

    Output: input_data --- the data list
    """
#
#--- create a current file list
#
    if comp_test == 'test':
        cmd = 'ls -d /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/ACIS_rad_data/*evt1.fits > '
    else:
        cmd = 'ls -d  /dsops/ap/sdp/cache/*/acis/*evt1.fits > '

    cmd = cmd + zspace
    os.system(cmd)

    f    = open(zspace, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
    mcf.rm_file(zspace)
#
#--- choose files with only non-calibration data
#
    file_list = []
    for ent in data:
        atemp = re.split('acisf', ent)
        btemp = re.split('_', atemp[1])
        ctemp = re.split('N', btemp[1])
        mark  = int(ctemp[0])

        if mark < 50000:
            file_list.append(ent)
#
#--- read the old file list
#
    file     = house_keeping + 'old_file_list'
    old_list = mcf.readFile(file)
#
#--- read bad fits file list
#
    try:
        file2    = house_keeping + 'bad_fits_file'
        bad_list = mcf.readFile(file2)
    except:
        bad_list = []
        
#
#--- update old_file_list while reading out new files
#
    f = open(file, 'w')
#
#--- compara two files and select out new file names
#
    input_data = []
    for ent in file_list:

        f.write(ent)
        f.write('\n')

        chk = 1
        for comp in old_list:
            if ent == comp:
                chk = 0
                break
        if chk == 1:
            chk2 = 1
            for bad in bad_list:
                if ent == bad:
                    chk2 = 0
                    break
            if chk2 == 1:
                input_data.append(ent)

    f.close()

    return input_data


#---------------------------------------------------------------------------------------------------
#--- find_date_obs: find observation time                                                        ---
#---------------------------------------------------------------------------------------------------

def find_date_obs(file):
  
    """ 
    find observation time
    Input: file --- input fits file name
    Output: year, month, and date
    """
    try:
        dout  = pyfits.open(file)
        date  = dout[0].header['DATE-OBS']

        atemp = re.split('T', date)
        btemp = re.split('-', atemp[0])
    
        year  = int(btemp[0])
        month = int(btemp[1])
        date  = int(btemp[2])
    
        return (year, month, date)
    except:
        return (1900, 1, 1)

#---------------------------------------------------------------------------------------------------
#--- extract_data: extract time and ccd_id from the fits file and create count rate data         ---
#---------------------------------------------------------------------------------------------------

def extract_data(file, out_dir, comp_test =''):

    """
    extract time and ccd_id from the fits file and create count rate data
    Input:  file    --- fits file data
            out_dir --- the directory in which data will be saved
    Output: ccd<ccd>--- 5 min accumulated count rate data file
    """
#
#--- extract time and ccd id information from the given file
#
    data      = pyfits.getdata(file, 0)
    time_col  = data.field('TIME')
    ccdid_col = data.field('CCD_ID')
#
#--- initialize
#
    diff  = 0
    chk   = 0
    ccd_c = [0  for x in range(0, 10)]
    ccd_h = [[] for x in range(0, 10)]
#
#--- check each line and count the numbers of ccd in the each 300 sec intervals
#
    for k in range(0, len(time_col)):

        if mcf.chkNumeric(time_col[k]) and mcf.chkNumeric(ccdid_col[k]) :
            ftime  = float(time_col[k])

            if ftime > 0:
                ccd_id = int(ccdid_col[k])

                if chk == 0:
                    ccd_c[ccd_id] += 1
                    s_time = ftime
                    diff   = 0
                    chk    = 1
                elif diff >= 300.0:
#
#--- convert time in dom
#
                    dom = tcnv.stimeToDom(s_time)
#
#--- print out counts per 300 sec 
#
                    for i in range(0, 10):
                        line = str(dom) + '\t' + str(ccd_c[i]) + '\n'
                        ccd_h[i].append(line)
#
#--- re initialize for the next round
#
                        ccd_c[i] = 0

                    ccd_c[ccd_id] += 1
                    s_time = ftime
                    diff   = 0
                    chk    = 0
#
#--- accumurate the count until the 300 sec interval is reached
#
                else:
                    diff = ftime - s_time
                    ccd_c[ccd_id] += 1
#
#--- for the case the last interval is less than 300 sec, 
#--- estimate the the numbers of hit and adjust
#
    if diff > 0 and diff < 300:
        ratio = 300.0 / diff

        for i in range(0, 10):
            ccd_c[i] *= ratio

            line = str(dom) + '\t' + str(ccd_c[i]) + '\n'
            ccd_h[i].append(line)
#
#--- if this is a test, return output 
#
    if comp_test == 'test':

        return ccd_h
#
#--- otherwise, print out the results
#
    else:
        for i in range(0, 10):
            file = out_dir + '/ccd' + str(i)
            f    = open(file, 'a')

            for ent in ccd_h[i]:
                f.write(line)
            f.close()

#---------------------------------------------------------------------------------------------------
#--- get_ephin_list: create an ephin data list                                                   ---
#---------------------------------------------------------------------------------------------------

def get_ephin_list(comp_test=''):

    """
    create an ephin data list
    Input: comp_test --- if it is test, test data is used
           ephin data ---  /dsops/ap/sdp/cache/*/ephin/*lc1.fits
    Output: input_data_list: a list of ephin data file which is not extract
    """

    if comp_test == 'test':
        cmd = 'ls -d  /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/Ephin_data/*lc1.fits >'
        cmd = cmd + house_keeping + '/ephin_dir_list'
    else:
        cmd = 'ls -d  /dsops/ap/sdp/cache/*/ephin/*lc1.fits > '
        cmd = cmd + house_keeping + '/ephin_dir_list'

    os.system(cmd)

#
#--- get a list of the current entries
#
    file = house_keeping + '/ephin_dir_list'
    f    = open(file, 'r')
    data = [line.strip() for line in f.readlines()]
    f.close()
#
#--- read the list which we read the last time
#
    file = house_keeping + '/ephin_old_dir_list'
    f    = open(file, 'r')
    old  = [line.strip() for line in f.readlines()]
    f.close()
#
#--- find the last entry of the list
#
    last_entry = old[len(old)-1]
#
#--- select data which is new
#
    input_data_list = []
    chk = 0
    for ent in data:
        if chk == 0:
            if ent == last_entry:
                chk = 1
        else:
            input_data_list.append(ent)
#
#--- replace the old list with the new one
#
    cmd = 'mv ' + house_keeping + '/ephin_dir_list ' + house_keeping + '/ephin_old_dir_list'
    os.system(cmd)

    return input_data_list


#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------

def extract_ephin_data(file, out_dir, comp_test=''):

    """
    extract ephine data from a given data file name and save it in out_dir
    Input:  file    --- ephin data file name
            out_dir --- directory which the data is saved
    Output: <out_dir>/ephin_data --- ephin data (300 sec accumulation) 
    """
#
#--- extract time and ccd id information from the given file
#
    data      = pyfits.getdata(file, 1)
    time_r    = data.field("TIME")
    scp4_r    = data.field("SCP4")
    sce150_r  = data.field("SCE150")
    sce300_r  = data.field("SCE300")
    sce1500_r = data.field("SCE1300")
#
#--- initialize
#
    diff       = 0
    chk        = 0
    ephin_data = []
#
#--- sdata[0]: scp4, sdata[1]: sce150, sdata[2]: sce300, and sdata[3]: sce1300
#
    sdata = [0 for x in range(0,4)]

#
#--- check each line and count the numbers of ccd in the each 300 sec intervals
#

    for k in range(0, len(time_r)):
        if mcf.chkNumeric(time_r[k]):
            ftime  = float(time_r[k])
            if ftime > 0:
                if chk == 0:
#                    for j in range(2, 6):
#                        sdata[j-2] += atemp[j]

                    if mcf.chkNumeric(scp4_r[k]) and mcf.chkNumeric(sce150_r[k]) \
                        and mcf.chkNumeric(sce300_r[k]) and mcf.chkNumeric(sce1500_r[k]):
                        sdata[0] += float(scp4_r[k])
                        sdata[1] += float(sce150_r[k])
                        sdata[2] += float(sce300_r[k])
                        sdata[3] += float(sce1500_r[k])

                    s_time = ftime
                    diff   = 0
                    chk    = 1
                elif diff >= 300.0:
#
#--- convert time in dom
#
                    dom = tcnv.stimeToDom(s_time)
#
#--- print out counts per 300 sec 
#
                    line = str(dom) + '\t' 
                    for j in range(0, 4):
                        line = line + str(sdata[j]) + '\t'
                        sdata[j] = 0
                    line = line + '\n'
                    ephin_data.append(line)
                    chk = 0
#
#--- re initialize for the next round
#
                    if mcf.chkNumeric(scp4_r[k]) and mcf.chkNumeric(sce150_r[k]) \
                        and mcf.chkNumeric(sce300_r[k]) and mcf.chkNumeric(sce1500_r[k]):
                        sdata[0] += float(scp4_r[k])
                        sdata[1] += float(sce150_r[k])
                        sdata[2] += float(sce300_r[k])
                        sdata[3] += float(sce1500_r[k])
                    s_time = ftime
                    diff   = 0
#
#--- accumurate the count until the 300 sec interval is reached
#
                else:
                    diff = ftime - s_time
                    if mcf.chkNumeric(scp4_r[k]) and mcf.chkNumeric(sce150_r[k]) \
                        and mcf.chkNumeric(sce300_r[k]) and mcf.chkNumeric(sce1500_r[k]):
                        sdata[0] += float(scp4_r[k])
                        sdata[1] += float(sce150_r[k])
                        sdata[2] += float(sce300_r[k])
                        sdata[3] += float(sce1500_r[k])
#
#--- for the case the last interval is less than 300 sec, 
#--- estimate the the numbers of hit and adjust
#
    if diff > 0 and diff < 300:

        line = str(dom) + '\t' 

        ratio = 300.0 / diff
        for j in range(0, 4):
            var  = sdata[j] * ratio
            line = line + str(var) + '\t'

        line = line + '\n'
        ephin_data.append(line)
#
#--- if this is a test, reutrn the result
#
    if comp_test == 'test':
        return ephin_data
#
#--- otherwise, print the result
#
    else:

        file = out_dir + '/ephin_rate'
        f    = open(file, 'a')
        for ent in ephin_data:
            f.write(ent)
        f.close()

#---------------------------------------------------------------------------------------------------
#-- cleanUp: sort and remove duplicated lines in all files in given data directory               ---
#---------------------------------------------------------------------------------------------------

def cleanUp(cdir):
    
    """
    sort and remove duplicated lines in all files in given data directory
    Input       cdir   --- directory name
    Output      cdir/files ---- cleaned up files

    """
    if os.listdir(cdir) != []:
        cmd = 'ls ' + cdir + '/* > ' +  zspace
        os.system(cmd)
        data = mcf.readFile(zspace)
        mcf.rm_file(zspace)

        for file in data:
#
#--- avoid html and png files
#
            m = re.search('\.', file)
            if m is None:
                mcf.removeDuplicate(file, chk = 1, dosort=1)

#-----------------------------------------------------------------------------------------
#-- TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST    ---
#-----------------------------------------------------------------------------------------

class TestFunctions(unittest.TestCase):
    """
    testing functions

    """
#------------------------------------------------------------

    def test_extract_data(self):

        file = '/data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/ACIS_rad_data/acisf14962_000N001_evt1.fits'
        tmon_name = './'
        out = extract_data(file, tmon_name,comp_test='test')

        self.assertEquals(out[8][3], '4954.71086806\t1601\n')


#------------------------------------------------------------
    def test_extract_ephin_data(self):

        file = '/data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/Ephin_data/ephinf476924026N001_lc1.fits'
        tmon_name = './'
        out = extract_ephin_data(file, tmon_name, comp_test='test')

        self.assertEquals(out[1], '4953.95931713\t0.0\t235.042737424\t3.100896425\t1.94131750977\t\n')


#------------------------------------------------------------

if __name__ == "__main__":

        unittest.main()
