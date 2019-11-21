
import sys, os

subsets = [[3, 1000], 
           [1000, 2000], 
           [2000, 3000],
           [3000, 4000],
           [4000, 5000],
           [5000, 6000],
           [6000, 7000],
           [7000, 8000],
           [8000, 9000],
          [9000, 9657]]
for subset in subsets:
    print('running %s'%subset)
    os.system('screen -d -m ipython el_calc_runoff_anomalies.py %d %d'%(subset[0], subset[1]))