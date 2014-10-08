#!/usr/bin/env /proj/sot/ska/bin/python

#####################################################################################################
#                                                                                                   #
#       plot_count_rate.py: plot ACIS count rate related plots                                      #
#                                                                                                   #
#           author: t. isobe (tisobe@cfa.harvard.edu)                                               #
#                                                                                                   #
#           Last Update: Apr 07, 2014                                                               #
#                                                                                                   #
#####################################################################################################

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

#import mpl.pyplot as plt
#import mpl.font_manager as font_manager
#import mpl.lines as lines
#
from pylab import *
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import matplotlib.lines as lines

import random                   #--- random must be called after pylab
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

#----------------------------------------------------------------------------------------------
#--- create_plots: a control function to crate all acis dose plots                          ---
#----------------------------------------------------------------------------------------------

def create_plots(directory):

    """
    a control function to crate all acis dose plots
    Input: directory --- output directory 
    Output: all plots in png form
    """
    generate_count_rate_plot(directory)

    generate_ephin_rate_plot(directory)

    full_range_plot()


#----------------------------------------------------------------------------------------------
#--- generate_count_rate_plot: create count rate plots                                      ---
#----------------------------------------------------------------------------------------------

def generate_count_rate_plot(directory):

    """
    create count rate plots
    Input: directory --- the directory where data is located and the plot will be created
            <directory>/ccd<ccd> --- count rate data file
    Output: <directory>/acis_dose_ccd<ccd>.png
            <directory>/acis_dose_ccd_5_7.png
    """

    xname  = 'Time (DOM)'
    yname  = 'Count/Sec'

    data1_x = []
    data1_y = []
    data2_x = []
    data2_y = []
    data3_x = []
    data3_y = []
#
#--- plot count rates for each ccd
#
    for ccd in range(0, 10):
        file = directory + '/ccd' + str(ccd)
        chk  = mcf.chkFile(file)
        if chk == 0:
            continue

        f    = open(file, 'r')
        data = [line.strip() for line in f.readlines()]
        f.close()
        xdata = []
        ydata = []
        for ent in data:
            atemp = re.split('\s+', ent)
            if mcf.chkNumeric(atemp[0]) and mcf.chkNumeric(atemp[1]):
                xdata.append(float(atemp[0]))
#
#--- normalized to cnts/sec
#
                ydata.append(float(atemp[1]) / 300.0)

        title   = 'ACIS Count Rate: CCD' + str(ccd)
        outname = directory + '/acis_dose_ccd' + str(ccd) + '.png'

        plot_panel(xdata, ydata, xname, yname, title, outname)
#
#--- save data for three panel plot
#
        if ccd == 5:
            data1_x = xdata
            data1_y = ydata
        elif ccd == 6:
            data2_x = xdata
            data2_y = ydata
        elif ccd == 7:
            data3_x = xdata
            data3_y = ydata
#
#--- create three panel plot for ccd5, ccd6, and ccd7
#
    title1  = 'ACIS Count Rate: CCD5'
    title2  = 'ACIS Count Rate: CCD6'
    title3  = 'ACIS Count Rate: CCD7'
    outname = directory + '/acis_dose_ccd_5_7.png'

    x_set_list = [data1_x, data2_x, data3_x]
    y_set_list = [data1_y, data2_y, data3_y]
    yname_list = [yname,   yname,   yname]
    title_list = [title1,  title2, title3]

    plot_multi_panel(x_set_list, y_set_list, xname, yname_list, title_list, outname)


#----------------------------------------------------------------------------------------------
#--- full_range_plot: create long term trending plots                                       ---
#----------------------------------------------------------------------------------------------

def full_range_plot():

    """
    create long term trending plots
    Input: none but all data are read from web_dir/<MON><YEAR> directories
    Output: <web_dir>/long_term_plot.png
            <web_dir>/month_avg_img.png
            <web_dir>/month_avg_spc.png
            <web_dir>/month_avg_bi.png
    """

    ccd5_x = []
    ccd5_y = []
    ccd6_x = []
    ccd6_y = []
    ccd7_x = []
    ccd7_y = []
    for ccd in range(0, 10):

        xname = 'mccd'+ str(ccd) + '_x'
        yname = 'mccd'+ str(ccd) + '_y'
        sname = 'mccd'+ str(ccd) + '_s'
        exec "%s = []" % (xname)
        exec "%s = []" % (yname)
        exec "%s = []" % (sname)

        cmd  = 'ls ' + web_dir + '/*/ccd' + str(ccd) + ' >' + zspace
        os.system(cmd)
        f    = open(zspace, 'r')
        data = [line.strip() for line in f.readlines()]
        f.close()
        mcf.rm_file(zspace)

        for ent in data:
            f     = open(ent, 'r')
            fdata = [line.strip() for line in f.readlines()]
            f.close()
    
            time = []
            sum  = 0
            sum2 = 0
            cnt  = 0
            for line in fdata:
                atemp = re.split('\s+', line)

                if mcf.chkNumeric(atemp[0]) and mcf.chkNumeric(atemp[1]):
                    xt = float(atemp[0])
                    yt = float(atemp[1]) 
                    if xt >= 0 and xt < 20000 and yt >= 0:
                        sum += yt
                        sum2+= yt * yt
                        cnt += 1
                        time.append(xt)
#
#--- for ccd 5, 6,  7, we need 5 min average data (then normalized to cnt /sec)
#
                        if ccd  == 5:
                            ccd5_x.append(xt)
                            ccd5_y.append(yt/300.0)
                        if ccd  == 6:
                            ccd6_x.append(xt)
                            ccd6_y.append(yt/300.0)
                        if ccd  == 7:
                            ccd7_x.append(xt)
                            ccd7_y.append(yt /300.0)
#
#--- get monthly average
#
            date = int(0.5 * (min(time) + max(time)))
            avg  = sum / float(cnt) / 300.0
            sig  = sqrt(sum2 / float(cnt) / 90000.0 - avg * avg)

            xname = 'mccd'+ str(ccd) + '_x'
            yname = 'mccd'+ str(ccd) + '_y'
            sname = 'mccd'+ str(ccd) + '_s'
            exec "%s.append(%s)" % (xname , date)
            exec "%s.append(%s)" % (yname , avg)
            exec "%s.append(%s)" % (sname , sig)
#
#--- ploting starts here
#
    xname = 'Time (DOM)'
    yname = 'Counts/Sec'
#
#---- ccd 7 full history
#
    title = 'ACIS Count Rate: CCD 7'
    outname = web_dir + '/acis_ccd7_dose_plot.png'

    plot_panel(ccd7_x, ccd7_y, xname, yname, title, outname, autox='yes')
#
#--- long term plot (for ccd 5, 6, and 7)
#
    x_set_list = [ccd5_x, ccd6_x, ccd7_x]
    y_set_list = [ccd5_y, ccd6_y, ccd7_y]
    yname_list = [yname,  yname,  yname,  yname]
    title_list = ['CCD5', 'CCD6', 'CCD7']
    outname    = web_dir + '/long_term_plot.png'
    y_limit    = [1000, 1000, 1000]

    plot_multi_panel(x_set_list, y_set_list, xname, yname_list, title_list, outname, ylim =2, y_limit=y_limit, autox='yes')

#
#--- imaging ccds full history
#
    x_set_list = [mccd0_x, mccd1_x, mccd2_x, mccd3_x]
    y_set_list = [mccd0_y, mccd1_y, mccd2_y, mccd3_y]
    yname_list = [yname,  yname,  yname,  yname]
    title_list = ['CCD0', 'CCD1', 'CCD2', 'CCD3']
    outname    = web_dir + '/month_avg_img.png'

    plot_multi_panel(x_set_list, y_set_list, xname, yname_list, title_list, outname, linew=0, mrk='+', ylim=1, autox='yes')
#
#--- spectral ccds full history
#
    x_set_list = [mccd4_x, mccd6_x, mccd8_x, mccd9_x]
    y_set_list = [mccd4_y, mccd6_y, mccd8_y, mccd9_y]
    yname_list = [yname,  yname,  yname,  yname]
    title_list = ['CCD4', 'CCD6', 'CCD8', 'CCD9']
    outname    = web_dir + '/month_avg_spc.png'

    plot_multi_panel(x_set_list, y_set_list, xname, yname_list, title_list, outname, linew=0, mrk='+', ylim=1, autox='yes')
#
#--- backside ccds full history
#
    x_set_list = [mccd5_x, mccd7_x]
    y_set_list = [mccd7_y, mccd7_y]
    yname_list = [yname,  yname,  yname,  yname]
    title_list = ['CCD5', 'CCD7']
    outname    = web_dir + '/month_avg_bi.png'

    plot_multi_panel(x_set_list, y_set_list, xname, yname_list, title_list, outname, linew=0, mrk='+', ylim=1, autox='yes')

    plot_multi_panel(x_set_list, y_set_list, xname, yname_list, title_list, outname, autox='yes')
#
#--- write out monthly average data
#
    for ccd in range(0, 10):
        name = web_dir + 'monthly_avg_data_ccd' + str(ccd) + '.dat'
        f    = open(name, 'w')
        exec 'xdat = mccd%s_x' % (ccd)
        exec 'ydat = mccd%s_y' % (ccd)
        exec 'ysig = mccd%s_s' % (ccd)
        xdat =numpy.array(xdat)
        ydat =numpy.array(ydat)
        ysig =numpy.array(ysig)
        sorted_index = numpy.argsort(xdat)
        xsorted = xdat[sorted_index]
        ysorted = ydat[sorted_index]
        ssorted = ysig[sorted_index]

        for i in range(0, len(xsorted)):
            yrnded  = '%.3f' % ysorted[i]
            ysrnded = '%.3f' % ssorted[i]
            line  = str(xsorted[i]) + '\t' + yrnded + '+/-' + ysrnded + '\n'
            f.write(line)
        f.close()


#----------------------------------------------------------------------------------------------
#--- generate_ephin_rate_plot: create ephin rate plots                                      ---
#----------------------------------------------------------------------------------------------

def generate_ephin_rate_plot(directory):

    """
    create ephin rate plots
    Input: directory --- a directory where the data is kept and the plot will be created
           <directory>/ephin_rate --- ephin data file
    Ouput: <directory>/ephin_rate.png
    """

    xname  = 'Time (DOM)'
    yname  = 'Count/Sec'

    file   = directory + '/ephin_rate'
    chk  = mcf.chkFile(file)
    if chk == 0:
        return ""

    f      = open(file, 'r')
    data   = [line.strip() for line in f.readlines()]
    f.close()

    dom   = []
    p4    = []
    e150  = []
    e300  = []
    e1300 = []
    for ent in data:
        atemp = re.split('\s+', ent)
        if mcf.chkNumeric(atemp[0]) and mcf.chkNumeric(atemp[1]):
            dom.append(float(atemp[0]))
            p4.append(float(atemp[1])    / 300.0)
            e150.append(float(atemp[2])  / 300.0)
            e300.append(float(atemp[3])  / 300.0)
            e1300.append(float(atemp[4]) / 300.0)

    x_set_list = [dom, dom,  dom,  dom]
    y_set_list = [p4,  e150, e300, e1300]
    yname_list = [yname, yname, yname, yname]
    title_list = ['P4', 'E150', 'E300', 'E1300']
    outname    = directory + '/ephin_rate.png'

    plot_multi_panel(x_set_list, y_set_list, xname, yname_list, title_list, outname)

#----------------------------------------------------------------------------------------------
#--- plot_panel: createa single pamel plot                                                  ---
#----------------------------------------------------------------------------------------------

def plot_panel(xdata, ydata, xname, yname, title, outname, autox='no'):

    """
    createa single pamel plot
    Input:  xdata  --- x data
            ydata  --- y data
            xname  --- x axis legend
            yname  --- y axis legend
            title  --- title of the plot
            outname -- output file name
    Output: outname -- a png plot file
    """
#
#--- set plotting range
#
    xmin = int(min(xdata) - 1)
    if autox == 'no':
        xmax = xmin + 33
    else:
        xmax = max(xdata)
        diff = xmax - xmin
    
        if diff == 0 and xmin > 0:
            xmax = xmin + 1
        else:
            xmin -= 0.05 * diff
            xmax += 0.05 * diff
            if xmin < 0.0:
                xmin = 0

    ymin = 0
    ymax = max(ydata)
    diff = ymax - ymin
    if diff == 0 and ymin >= 0:
        ymax = ymin + 1
    else:
        ymax += 0.05 * diff

#
#--- clean up all plotting param
#
    plt.close('all')
#
#---- set a few parameters
#
####    mpl.rcParams['font.size'] = 9
    props = font_manager.FontProperties(size=9)
    plt.subplots_adjust(hspace=0.08)
#
#---- set a panel
#
    ax = plt.subplot(111)
    ax.set_autoscale_on(False)      #---- these three may not be needed for the new pylab, but 
    ax.set_xbound(xmin,xmax)        #---- they are necessary for the older version to set

    ax.set_xlim(xmin=xmin, xmax=xmax, auto=False)
    ax.set_ylim(ymin=ymin, ymax=ymax, auto=False)
#
#--- plot data
#
    p, = plt.plot(xdata, ydata, color='black', lw =0 , marker='.', markersize=0.5)
#
#--- add legend
#    
    plt.title(title)
    ax.set_xlabel(xname, size=8)
    ax.set_ylabel(yname, size=8)
#
#--- set the size of the plotting area in inch (width: 10.0in, height 5.0in)
#
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(10.0, 5.0)
#
#--- save the plot in png format
#
    plt.savefig(outname, format='png', dpi=100)
#
#--- clean up all plotting param
#
    plt.close('all')


#----------------------------------------------------------------------------------------------
#--- plot_multi_panel: create multiple panel plots                                          ---
#----------------------------------------------------------------------------------------------

def plot_multi_panel(x_set_list, y_set_list, xname, yname_list, title_list, outname, linew=0, mrk='.', ylim=0, y_limit=[], autox='no'):

    """
    create multiple panel plots
    Input:  x_set_list --- a list of x data sets
            y_set_list --- a list of y data set
            xname      --- x axis legend
            yname_list --- a list of y axix legends
            title_list --- a list of title of each panel
            outname    --- output file name
            linew      --- line width of the plot. if 0 is given, no line is drawn
            mrk        --- a marker used for plot such as '.', '*', 'o'  '+'
            ylim       --- if it is 0, each panel uses different y plotting range, otherwise set to the same 
                           if it is 2, read y_list
            y_limit    --- a list of limit in y axis
    Output: outname    --- a png plot file
    """
#
#--- how many panels?
#
    pnum = len(x_set_list)
#
#--- set x plotting_range
#
    (xmin, xmax) = find_plot_range(x_set_list)
    xmin = int(xmin) -1
    if autox == 'no':
        xmax = xmin + 33
#
#--- if it is requested set limit
#
    if ylim == 1:
        (ymin, ymax) = find_plot_range(y_set_list)

#--- clean up all plotting param
#
    plt.close('all')
#
#---- set a few parameters
#
####    mpl.rcParams['font.size'] = 9
    props = font_manager.FontProperties(size=9)
    plt.subplots_adjust(hspace=0.08)

    for i in range(0, pnum):
        axNam = 'ax' + str(i)
#
#---- set a panel #i
#
        if ylim == 0:
            ymin = 0
            if len(y_set_list[i]) > 0:
                ymax = max(y_set_list[i])
            else:
                ymax = ymin + 1

            diff = ymax - ymin
            if diff == 0:
                ymax = ymin + 1
            else:
                ymax += 0.1 * diff
        elif ylim == 2:
            ymin = 0 
            ymax = y_limit[i]

        j = i + 1
        if i == 0:
            pline = str(pnum) + '1' + str(j)
        else: 
            pline = str(pnum) + '1' + str(j) + ', sharex=ax0'

        exec "%s= plt.subplot(%s)" % (axNam, pline)
        exec "%s.set_autoscale_on(False)" % (axNam)      #---- these three may not be needed for the new pylab, but 
        exec "%s.set_xbound(xmin,xmax)" % (axNam)        #---- they are necessary for the older version to set

        exec "%s.set_xlim(xmin=%s, xmax=%s, auto=False)" % (axNam, xmin, xmax)
        exec "%s.set_ylim(ymin=%s, ymax=%s, auto=False)" % (axNam, ymin, ymax)
#
#--- plot data
#
        p, = plt.plot(x_set_list[i], y_set_list[i], color='black', lw =linew , marker= mrk, markersize=1.5)
#
#--- add legend
        leg = legend([p],  [title_list[i]], prop=props, loc=2)
        leg.get_frame().set_alpha(0.5)
    
        exec "%s.set_ylabel('%s', size=8)" % (axNam, yname_list[i])
#
#-- add x ticks label only on the last panel
#
        pval = pnum-1
        if i != pval:
            exec "line = %s.get_xticklabels()" % (axNam)
            for label in line:
                label.set_visible(False)
        else:
#            pass
#
#--- x label is only put at the last panel
#
            xlabel(xname)
#
#--- set the size of the plotting area in inch (width: 10.0in, height 5.0in)
#
    fig = matplotlib.pyplot.gcf()
    fig.set_size_inches(10.0, 5.0)
#
#--- save the plot in png format
#
    plt.savefig(outname, format='png', dpi=100)
#
#--- clean up all plotting param
#
    plt.close('all')

#----------------------------------------------------------------------------------------------
#--- find_plot_range: find a unifiedplotting range for multiple data sets                   ---
#----------------------------------------------------------------------------------------------

def find_plot_range(p_set_list):

    """
    find a unifiedplotting range for multiple data sets
    Input: p_set_list --- a list of data sets 
    Output: pmin / pmax --- min and max of the data
    """

    if len(p_set_list[0]) > 0:
        ptmin = min(p_set_list[0])
        ptmax = max(p_set_list[0])
    else: 
        ptmin = 0
        ptmax = 0

    for i in range(1, len(p_set_list)):
        if len(p_set_list[i]) > 0:
            pmin = min(p_set_list[i])
            pmax = max(p_set_list[i])
            if pmin < ptmin:
                ptmin = pmin
            if pmax > ptmax:
                ptmax = pmax

    diff = ptmax - ptmin
    if diff == 0:
        ptmax = ptmin + 1
    else:
        ptmax += 0.01 * diff
        ptmin -= 0.01 * diff
        if ptmin < 0:
            ptmin = 0

    return(ptmin, ptmax)



#--------------------------------------------------------------------
#
#--- pylab plotting routine related modules
#
#from pylab import *
#import matplotlib.pyplot as plt
#import matplotlib.font_manager as font_manager
#import matplotlib.lines as lines

if __name__ == '__main__':

    create_plots(directory)

