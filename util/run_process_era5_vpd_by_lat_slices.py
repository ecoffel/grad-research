
import sys, os, time

dirERA5 = '/home/edcoffel/drive/MAX-Filer/Research/Climate-02/Data-02-edcoffel-F20/ERA5'


for year in range(1988, 1988+1):
    for lat in range(90,-90,-5):
        
        l1 = lat
        l2 = lat-4.75
        
        if l1 == -85:
            l2 = -90
        
        l1=float(l1)
        l2=float(l2)
        fname = f'{dirERA5}/hourly/vpd/vpd_{year}_{l1}_{l2}.nc'
        
        mustrun = False
        if os.path.isfile(fname):
            fsize = os.stat(fname)
            fsize = fsize.st_size / (1024 * 1024);
            
            if fsize < 300:
                mustrun = True
                os.remove(fname)
                print('removed', fname)
        
        if not os.path.isfile(fname):
            mustrun = True
            
        if mustrun:
#             print(fname)
            print(f'running ({year}, {l1}, {l2})')
            os.system(f"screen -d -m ipython era5_calc_vpd.py -- {year} {l1} {l2}")
            # time.sleep(0)