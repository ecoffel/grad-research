
import sys, os, time

for y in range(1981, 2022):
    print('running %s'%y)
    os.system('ipython era5_calc_huss-metpy.py %d'%(y))
#     time.sleep(500)