
import sys, os

for y in range(1981, 2021+1, 1):
    print('running %s'%y)
    os.system('screen -d -m ipython lens_calc_tw.py %d'%(y))