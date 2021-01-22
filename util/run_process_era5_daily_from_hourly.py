
import sys, os

subsets = []
for y in range(1985, 2021, 3):
	subsets.append([y, y+3])

for subset in subsets:
    print('running %s'%subset)
    os.system('screen -d -m ipython era5_extract_t_from_hourly.py %d %d'%(subset[0], subset[1]))