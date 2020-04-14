
import sys, os

subsets = [[1979, 1983], \
            [1984, 1988], \
           [1989, 1993], \
           [1994, 1998], \
           [1999, 2003], \
		   [2004, 2008], \
           [2009, 2013], \
           [2014, 2018]]

for subset in subsets:
    print('running %s'%subset)
    os.system('screen -d -m ipython era5_extract_daily_evaporation_from_hourly.py %d %d'%(subset[0], subset[1]))