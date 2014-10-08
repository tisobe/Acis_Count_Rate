#!/usr/bin/env /proj/sot/ska/bin/python

#########################################################################################################
#                                                                                                       #
#   count_rate_main.py: Read ACIS evnent 1 file and create quick dose count plot                        #
#                                                                                                       #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                                   #
#                                                                                                       #
#           Last Update: Oct 02, 2014                                                                   #
#                                                                                                       #
#########################################################################################################

import os
import sys
import re
import string
import operator
import math
import numpy

#
#--- pylab plotting routine related modules
#
import matplotlib as mpl

if __name__ == '__main__':

    mpl.use('Agg')

from pylab import *
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines as lines


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
#--- following three all contain acis dose related functions
#
import update_data_files          as udf
import plot_count_rate            as pcr
import print_html_page            as phtml

#
#--- temp writing file name
#
import random
rtail  = int(10000 * random.random())       #---- put a romdom # tail so that it won't mix up with other scripts space
zspace = '/tmp/zspace' + str(rtail)

#-----------------------------------------------------------------------------------------------------------
#--- count_rate_main: the main function to run all acis count rate                                       ---
#-----------------------------------------------------------------------------------------------------------

def count_rate_main(comp_test):

    """
    the main function to run all acis count rate 
    Input: comp_test --- if it is "test", the test data is used
    Output: data file (e.g. ccd0) and plots
    """
#
#--- update data files
#
    dir_save = udf.update_data_files()
#
#--- for the case the data are collected over two months period
#
    for dir in dir_save:
        pcr.create_plots(dir)
#
#--- update html pages
#
    phtml.print_html_page(comp_test)

#-----------------------------------------------------------------------------------------------------------
#--- test_prep: create directories/data and prepare for the test run                                     ---
#-----------------------------------------------------------------------------------------------------------

def test_prep():

    """
    create directories/data and prepare for the test run

    Input: none, but everything is read from house_keeping directory
    Output: test directories and files
    """

    if comp_test == 'test':

        cmd = "mkdir " + web_dir
        os.system(cmd)
    
        cmd = "mkdir " + web_dir + "/house_keeping"
        os.system(cmd)
    
        cmd = "cp /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/ephin_old_dir_list " 
        cmd = cmd + web_dir + "/house_keeping/."
        os.system(cmd)
    
        cmd = "cp /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/month_avg_data "  
        cmd = cmd + web_dir + "/house_keeping/."
        os.system(cmd)
    
        cmd = "cp /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/old_file_list  "  
        cmd = cmd + web_dir + "/house_keeping/."
        os.system(cmd)
    
        cmd = "cp /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/rad_data " 
        cmd = cmd + web_dir + "/house_keeping/."
        os.system(cmd)
    
        cmd = "cp -r /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/JAN2013 " + web_dir + "/"
        os.system(cmd)
    
        cmd = "cp -r /data/mta/Script/ACIS/Count_rate/house_keeping/Test_data_save/FEB2013 " + web_dir + "/"
        os.system(cmd)


#--------------------------------------------------------------------

#
#--- pylab plotting routine related modules
#

#from pylab import *
#import matplotlib.pyplot as plt
#import matplotlib.font_manager as font_manager
#import matplotlib.lines as lines

if __name__ == '__main__':
#
#--- if this is a test case, prepare the test output directory
#
    if comp_test == 'test':
        test_prep()

    count_rate_main(comp_test)

