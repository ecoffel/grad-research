import matplotlib.font_manager as font_manager
import matplotlib as mpl
from IPython import get_ipython
ipython = get_ipython()

ipython.magic('load_ext autoreload')
ipython.magic('autoreload 2')
ipython.magic('matplotlib inline')


font_dirs = ['/dartfs-hpc/rc/lab/C/CMIG/ecoffel/fonts', ]
font_files = font_manager.findSystemFonts(fontpaths=font_dirs)
font_list = font_manager.createFontList(font_files)
font_manager.fontManager.ttflist.extend(font_list)