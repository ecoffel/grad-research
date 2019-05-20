# -*- coding: utf-8 -*-
"""
Created on Thu May 16 11:39:34 2019

@author: Ethan
"""
import matplotlib.pyplot as plt 
import matplotlib.cm as cmx
import numpy as np
import pandas as pd
import pickle

plotFigs = True

genData = {}
with open('genData.dat', 'rb') as f:
    genData = pickle.load(f)
    
tx = genData['txScatter']
gen = genData['genTxScatter']

subgrid = 5

txAll = []
genAll = []


for s in range(tx.shape[0]):
    txAll.extend(tx[s])
    genAll.extend(gen[s])

txAll = np.array(txAll)
genAll = np.array(genAll) * 100

pBootstrap = []
zBootstrap = []

for i in range(1000):
    resampleInd = np.random.choice(len(txAll), int(len(genAll)))
    
    data = {'Temp':txAll[resampleInd], 'Gen':genAll[resampleInd]}
    df = pd.DataFrame(data, columns=['Temp', 'Gen'])
    
    df = df.dropna()
    
    z = np.polyfit(df['Temp'], df['Gen'], 3)
    p = np.poly1d(z)
    zBootstrap.append(z)
    pBootstrap.append(p)



# unpack polyfit coefs into lists
(p1,p2,p3,p4) = zip(*[(p[0], p[1], p[2], p[3]) for p in pBootstrap])
p1 = np.array(p1)
p2 = np.array(p2)
p3 = np.array(p3)
p4 = np.array(p4)
pSel = p4

# find percentiles for quadratic coef
pPoly10 = np.percentile(pSel, 10)
pPoly50 = np.percentile(pSel, 50)
pPoly90 = np.percentile(pSel, 90)

indPoly10 = np.where(abs(pSel-pPoly10) == np.nanmin(abs(pSel-pPoly10)))[0]
indPoly50 = np.where(abs(pSel-pPoly50) == np.nanmin(abs(pSel-pPoly50)))[0]
indPoly90 = np.where(abs(pSel-pPoly90) == np.nanmin(abs(pSel-pPoly90)))[0]


xd = np.linspace(0, 50, 200)
yPolyAll = np.array([pBootstrap[i](xd) for i in range(len(pBootstrap))])
yPolyd10 = np.array(pBootstrap[indPoly10[0]](xd))
yPolyd50 = np.array(pBootstrap[indPoly50[0]](xd))
yPolyd90 = np.array(pBootstrap[indPoly90[0]](xd))

plt.figure(figsize=(4,4))
plt.ylim([-.1, 1.5])
plt.grid(True)

plt.plot(xd, yPolyAll.T, '-', linewidth = 1, color = [.6, .6, .6], alpha = .2)
p1 = plt.plot(xd, yPolyd10, '-', linewidth = 2.5, color = cmx.tab20(0), label='10th Percentile')
p2 = plt.plot(xd, yPolyd50, '-', linewidth = 2.5, color = [0, 0, 0], label='50th Percentile')
p3 = plt.plot(xd, yPolyd90, '-', linewidth = 2.5, color = cmx.tab20(6), label='90th Percentile')

plt.gca().set_xticks(range(0, 51, 10))

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Daily Tx ($\degree$C)', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Normalized subgrid generation', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'})
leg.get_frame().set_linewidth(0.0)
    
x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-demand-temp-regression-perc.png', format='png', dpi=500, bbox_inches = 'tight', pad_inches = 0)



warming = [0, 1, 2, 3, 4]

txx = np.zeros([len(warming), genData['allTx'].shape[0], len(range(1981, 2018+1))])
for year in range(1981, 2018+1):
    ind = np.where(genData['year'] == year)[0]
    
    for s in range(genData['allTx'].shape[0]):
        for w in range(len(warming)):
            txx[w, s, year-1981] = np.nanmax(genData['allTx'][s][ind]+warming[w])

histGen10 = np.array(pBootstrap[indPoly10[0]](txx))
histGen50 = np.array(pBootstrap[indPoly50[0]](txx))
histGen90 = np.array(pBootstrap[indPoly90[0]](txx))

xd = np.array(list(range(1981, 2018+1)))-1981+1

pc = np.linspace(96.1, 95.7, len(xd))/100
pcFut10 = np.linspace(96.2, 95.5, 5)/100
pcFut50 = np.linspace(95.9, 94.8, 5)/100
pcFut90 = np.linspace(95.7, 94, 5)/100

pcWorst = np.linspace(95.7, 85, 5)/100

z = np.polyfit(xd, histGen10[0,subgrid,:], 1)
histPolyTxx10 = np.poly1d(z)
z = np.polyfit(xd, histGen50[0,subgrid,:], 1)
histPolyTxx50 = np.poly1d(z)
z = np.polyfit(xd, histGen90[0,subgrid,:], 1)
histPolyTxx90 = np.poly1d(z)

plt.figure(figsize=(4,4))
plt.xlim([-1, 105])
plt.ylim([0, .6])
plt.grid(True)

plt.plot(xd, histPolyTxx10(xd), '-', linewidth = 3, color = cmx.tab20(0), alpha = .8)
#plt.plot(xd, histPolyTxx10(xd)*(pc[0]-pc+1), '--', linewidth = 3, color = cmx.tab20(0), alpha = .8)

plt.plot(xd, histPolyTxx50(xd), '-', linewidth = 3, color = [0, 0, 0], alpha = .8)
#p2 = plt.plot(xd, histPolyTxx50(xd)*(pc[0]-pc+1), '--', linewidth = 3, color = [0, 0, 0], alpha = .8, label='TXx')

plt.plot(xd, histPolyTxx90(xd), '-', linewidth = 3, color = cmx.tab20(6), alpha = .8)
#plt.plot(xd, histPolyTxx90(xd)*(pc[0]-pc+1), '--', linewidth = 3, color = cmx.tab20(6), alpha = .8)

warmGen10 = [np.nanmean(histGen10[1,subgrid,:], axis=0), \
          np.nanmean(histGen10[2,subgrid,:], axis=0), \
          np.nanmean(histGen10[3,subgrid,:], axis=0), \
          np.nanmean(histGen10[4,subgrid,:], axis=0)]
plt.plot([55, 70, 85, 100], \
         warmGen10, \
          'o', markersize=7, color=cmx.tab20(0))

warmGen50 = [np.nanmean(histGen50[1,subgrid,:], axis=0), \
          np.nanmean(histGen50[2,subgrid,:], axis=0), \
          np.nanmean(histGen50[3,subgrid,:], axis=0), \
          np.nanmean(histGen50[4,subgrid,:], axis=0)]
p1 = plt.plot([55, 70, 85, 100], \
         warmGen50, \
          'o', markersize=7, color='black', label='Without curtailment')

warmGen90 = [np.nanmean(histGen90[1,subgrid,:], axis=0), \
          np.nanmean(histGen90[2,subgrid,:], axis=0), \
          np.nanmean(histGen90[3,subgrid,:], axis=0), \
          np.nanmean(histGen90[4,subgrid,:], axis=0)]
plt.plot([55, 70, 85, 100], \
         warmGen90, \
          'o', markersize=7, color=cmx.tab20(6))




warmGen10Amp = warmGen10 * (pcFut10[0]-pcFut10[1:]+1)
plt.plot([55, 70, 85, 100], \
         warmGen10Amp, \
          'x', markersize=7, color=cmx.tab20(0))

warmGen50Amp = warmGen50 * (pcFut50[0]-pcFut50[1:]+1)
p2 = plt.plot([55, 70, 85, 100], \
         warmGen50Amp, \
          'x', markersize=7, color='black', label='With curtailment')

warmGen90Amp = warmGen90 * (pcFut90[0]-pcFut90[1:]+1)
plt.plot([55, 70, 85, 100], \
         warmGen90Amp, \
          'x', markersize=7, color=cmx.tab20(6))

#warmGen90Worst = warmGen90 * (pcWorst[0]-pcWorst+1)
#plt.plot([55, 70, 85, 100], \
#         warmGen90Worst, \
#          '+', markersize=7, color=cmx.tab20(6))

plt.plot([38,38], [0,1], '--', linewidth=2, color='black')

plt.gca().set_xticks([1, 38, 55, 70, 85, 100])
plt.gca().set_xticklabels([1981, 2018, '1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)


plt.ylabel('Normalized subgrid generation', fontname = 'Helvetica', fontsize=16)

leg = plt.legend(prop = {'size':12, 'family':'Helvetica'}, loc='upper left')
leg.get_frame().set_linewidth(0.0)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('hist-fut-gen-chg.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)




chg10 = (warmGen10-np.nanmean(histPolyTxx10(xd))) / np.nanmean(histPolyTxx10(xd))
chg10Amp = (warmGen10Amp-np.nanmean(histPolyTxx10(xd))) / np.nanmean(histPolyTxx10(xd))
chg50 = (warmGen50-np.nanmean(histPolyTxx50(xd))) / np.nanmean(histPolyTxx50(xd))
chg50Amp = (warmGen50Amp-np.nanmean(histPolyTxx50(xd))) / np.nanmean(histPolyTxx50(xd))
chg90 = (warmGen90-np.nanmean(histPolyTxx90(xd))) / np.nanmean(histPolyTxx90(xd))
chg90Amp = (warmGen90Amp-np.nanmean(histPolyTxx90(xd))) / np.nanmean(histPolyTxx90(xd))


diff10 = (chg10Amp-chg10)*100
diff50 = (chg50Amp-chg50)*100
diff90 = (chg90Amp-chg90)*100


plt.figure(figsize=(4,4))
plt.ylim([0, 3.2])
plt.grid(True)

plt.plot([1,2,3,4], diff10, 'o', markersize=7, color = cmx.tab20(0))
p2 = plt.plot([1,2,3,4], diff50, 'o', markersize=7, color = [0, 0, 0], label='TXx')
plt.plot([1,2,3,4], diff90, 'o', markersize=7, color = cmx.tab20(6))

plt.gca().set_xticks([1, 2, 3, 4])
plt.gca().set_xticklabels(['1$\degree$C', '2$\degree$C', '3$\degree$C', '4$\degree$C'])

for tick in plt.gca().xaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')
    tick.label.set_fontsize(14)
for tick in plt.gca().yaxis.get_major_ticks():
    tick.label.set_fontname('Helvetica')    
    tick.label.set_fontsize(14)

plt.xlabel('Mean warming', fontname = 'Helvetica', fontsize=16)
plt.ylabel('Additional generation (%)', fontname = 'Helvetica', fontsize=16)

x0,x1 = plt.gca().get_xlim()
y0,y1 = plt.gca().get_ylim()
plt.gca().set_aspect(abs(x1-x0)/abs(y1-y0))

if plotFigs:
    plt.savefig('subgrid-additional-gen.eps', format='eps', dpi=500, bbox_inches = 'tight', pad_inches = 0)





