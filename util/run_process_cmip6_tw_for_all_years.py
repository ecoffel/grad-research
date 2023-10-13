
import sys, os, time

for y in range(1981, 2015):
    print('running %s'%y)
    os.system('screen -d -m ipython cmip6_calc_tw.py mpi-esm1-2-lr %d'%(y))
    time.sleep(500)