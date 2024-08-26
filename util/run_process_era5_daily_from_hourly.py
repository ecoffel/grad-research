
import sys, os, time

for y in range(1961, 1990+1, 1):
    print('running %s'%y)
    os.system('screen -d -m ipython era5_merge_lat_slices.py %d'%(y))
    time.sleep(600)