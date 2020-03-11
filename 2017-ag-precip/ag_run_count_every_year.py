
import sys, os

years = range(2002, 2017+1)

for year in years:
    print('running %s'%year)
    os.system('screen -d -m ipython ag_computeHourlyBins_redrizzle.py %d'%year)