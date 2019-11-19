import warnings
import numpy as np
import pandas as pd
import scipy.stats as st
import statsmodels as sm
import matplotlib
import matplotlib.pyplot as plt
import sys, os
import pickle

"""
matplotlib.rcParams['figure.figsize'] = (16.0, 12.0)
matplotlib.style.use('ggplot')


plotFigs = False
dumpData = False

# grdc or gldas
runoffData = 'grdc'

# world, useu, entsoe-nuke
plantData = 'entsoe-nuke'

qstr = '-qdistfit-gamma'
"""

# Create models from data
def best_fit_distribution(data, bins=200, ax=None):
    """Model data by finding best fit distribution to data"""
    # Get histogram of original data
    y, x = np.histogram(data, bins=bins, density=True)
    x = (x + np.roll(x, -1))[:-1] / 2.0

    # Distributions to check
    DISTRIBUTIONS = [        
        st.alpha,st.anglit,st.arcsine,st.beta,st.betaprime,st.bradford,st.burr,st.cauchy,st.chi,st.chi2,st.cosine,
        st.dweibull,st.erlang,st.expon,st.exponnorm,st.exponweib,st.exponpow,st.f,st.fatiguelife,st.fisk,
        st.foldcauchy,st.foldnorm,st.frechet_r,st.frechet_l,st.genlogistic,st.genpareto,st.gennorm,st.genexpon,
        st.genextreme,st.gausshyper,st.gamma,st.gengamma,st.genhalflogistic,st.gilbrat,st.gompertz,st.gumbel_r,
        st.gumbel_l,st.halfcauchy,st.halflogistic,st.halfnorm,st.halfgennorm,st.hypsecant,st.invgamma,st.invgauss,
        st.invweibull,st.johnsonsb,st.johnsonsu,st.ksone,st.kstwobign,st.laplace,st.levy,st.levy_l,#st.levy_stable,
        st.logistic,st.loggamma,st.loglaplace,st.lognorm,st.lomax,st.maxwell,st.mielke,st.nakagami,st.ncx2,st.ncf,
        st.norm,st.pareto,st.pearson3,st.powerlaw,st.powerlognorm,st.powernorm,st.rdist,st.reciprocal,
        st.rayleigh,st.rice,st.recipinvgauss,st.semicircular,st.t,st.triang,st.truncexpon,st.truncnorm,st.tukeylambda,
        st.uniform,st.vonmises,st.vonmises_line,st.wald,st.weibull_min,st.weibull_max,st.wrapcauchy
    ]

    # Best holders
    best_distribution = st.norm
    best_params = (0.0, 1.0)
    best_sse = np.inf
    best_std = np.nan
    # Estimate distribution parameters from data
    for distribution in DISTRIBUTIONS:
        #print('testing distribution: %s'%distribution)
        # Try to fit the distribution
        try:
            # Ignore warnings from data that can't be fit
            with warnings.catch_warnings():
                warnings.filterwarnings('ignore')

                # fit dist to data
                params = distribution.fit(data)

                # Separate parts of parameters
                arg = params[:-2]
                loc = params[-2]
                scale = params[-1]

                # Calculate fitted PDF and error with fit in distribution
                pdf = distribution.pdf(x, loc=loc, scale=scale, *arg)
                sse = np.sum(np.power(y - pdf, 2.0))

                
                # if axis pass in add to plot
                try:
                    if ax:
                        pd.Series(pdf, x).plot(ax=ax)
                    end
                except Exception:
                    pass

                curstd = distribution.std(*params)
                
                # identify if this distribution is better
                if best_sse > sse > 0 and not (np.isnan(curstd) or np.isinf(curstd)):
                    best_distribution = distribution
                    best_params = params
                    best_sse = sse
                    best_std = curstd
#                     print(curstd)

        except Exception:
            pass

    return (best_distribution.name, best_params, best_std)

def make_pdf(dist, params, size=100):
    """Generate distributions's Probability Distribution Function """

    # Separate parts of parameters
    arg = params[:-2]
    loc = params[-2]
    scale = params[-1]

    # Get sane start and end points of distribution
    start = dist.ppf(0.01, *arg, loc=loc, scale=scale) if arg else dist.ppf(0.01, loc=loc, scale=scale)
    end = dist.ppf(0.99, *arg, loc=loc, scale=scale) if arg else dist.ppf(0.99, loc=loc, scale=scale)

    # Build PDF and turn into pandas Series
    x = np.linspace(start, end, size)
    y = dist.pdf(x, loc=loc, scale=scale, *arg)
    pdf = pd.Series(y, x)

    return pdf

"""
print('loading qs data...')
fileNameRunoffDistFit = '/dartfs-hpc/rc/lab/C/CMIG/ecoffel/data/projects/electricity/script-data/%s-pp-runoff-qdistfit-gamma.csv'%plantData
plantQsData = np.genfromtxt(fileNameRunoffDistFit, delimiter=',', skip_header=0)

nbins = 500

dists = []

for p in range(plantQsData.shape[0]):
    
    if os.path.isfile('dist-fits/best-fit-plant-%d.dat'%p):
        continue
    
    print('processing plant %d'%p)
    
    # Load data from statsmodels datasets
    data = pd.Series(plantQsData[p,:])
    data[data < -10] = np.nan
    data[data > 10] = np.nan
    data=data.dropna()
    #data = data.loc[data.shift(-1) != data]

    # Plot for comparison
    plt.figure(figsize=(6,4))
    ax = data.plot(kind='hist', bins=nbins, density=True, alpha=0.5)
    # Save plot limits
    dataYLim = ax.get_ylim()

    # Find best fit distribution
    print('fitting best distribution...')
    best_fit_name, best_fit_params = best_fit_distribution(data, nbins, ax)
    best_dist = getattr(st, best_fit_name)

    # Update plots
    ax.set_ylim(dataYLim)
    ax.set_title(u'Runoff\n All Fitted Distributions')
    ax.set_xlabel(u'SD')
    ax.set_ylabel('Frequency')

    # Make PDF with best params 
    print('building pdf...')
    pdf = make_pdf(best_dist, best_fit_params)

    # Display
    plt.figure(figsize=(6,4))
    ax = pdf.plot(lw=2, label='PDF', legend=True)
    data.plot(kind='hist', bins=nbins, density=True, alpha=0.5, label='Data', legend=True, ax=ax)

    param_names = (best_dist.shapes + ', loc, scale').split(', ') if best_dist.shapes else ['loc', 'scale']
    param_str = ', '.join(['{}={:0.2f}'.format(k,v) for k,v in zip(param_names, best_fit_params)])
    dist_str = '{}({})'.format(best_fit_name, param_str)

    ax.set_title(u'Runoff with best fit distribution \n' + dist_str)
    ax.set_xlabel(u'SD')
    ax.set_ylabel('Frequency')

    plt.show()
    
    print('plant %d: dist: %s'%(p, best_fit_name))
    curPlantBestFit = {'name':best_fit_name, \
                       'params':best_fit_params}
    with open('dist-fits/best-fit-plant-%d.dat'%p, 'wb') as f:
        pickle.dump(curPlantBestFit, f)
    #dists.append((best_fit_name, best_fit_params))
    
print('done')
"""