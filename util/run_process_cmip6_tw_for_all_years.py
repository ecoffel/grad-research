
import sys, os, time

for y in range(2036, 2060+1):
    print('running %s'%y)
    os.system('screen -d -m ipython cmip6_calc_tw.py cmcc-esm2 %d'%(y))
#     time.sleep(500)