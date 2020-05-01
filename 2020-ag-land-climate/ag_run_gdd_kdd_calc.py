
import sys, os
import numpy as np

crop = 'Maize'
wxData = '20cr'
subsets = [(x,x+1) for x in np.arange(1970, 2016, 2)]

for subset in subsets:
    print('running %s'%str(subset))
    os.system('screen -d -m ipython ag_calc_gdd_kdd_sacks.py %s %s %d %d'%(crop, wxData, subset[0], subset[1]))