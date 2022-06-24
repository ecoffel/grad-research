
import sys, os

for y in range(1995, 2005):
    print('running %s'%y)
    os.system('screen -d -m ipython cmip6_calc_tw.py %d'%(y))