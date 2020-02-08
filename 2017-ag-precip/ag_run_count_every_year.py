
import sys, os

years = [2013]

for year in years:
    print('running %s'%year)
    os.system('screen -d -m ipython ag_computeHourlyBins_redrizzle.py %d'%year)