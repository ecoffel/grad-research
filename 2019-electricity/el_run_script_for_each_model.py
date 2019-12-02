
import sys, os

models = ['bcc-csm1-1-m', 'canesm2', \
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', \
              'gfdl-esm2g', 'gfdl-esm2m', \
              'inmcm4', 'miroc5', 'miroc-esm', \
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m']

for model in models:
    print('running %s'%model)
#     os.system('screen -d -m ipython el_aggregate_pc_model_warming.py %s'%model)
    os.system('screen -d -m ipython el_calc_runoff_anomalies.py %s rcp85'%model)