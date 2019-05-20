eraInterimReanalysisToMat('E:\data\era-interim\raw\land\swvl', 'E:\data\era-interim\output', 'swvl1', -1, -1);
eraInterimReanalysisToMat('E:\data\era-interim\raw\land\swvl', 'E:\data\era-interim\output', 'swvl2', -1, -1);
eraInterimReanalysisToMat('E:\data\era-interim\raw\land\swvl', 'E:\data\era-interim\output', 'swvl3', -1, -1);
eraInterimReanalysisToMat('E:\data\era-interim\raw\land\swvl', 'E:\data\era-interim\output', 'swvl4', -1, -1);

eraInterimReanalysisToMat('E:\data\era-interim\raw\land\snow', 'E:\data\era-interim\output', 'sd', -1, -1);
%run('regridEra.m');
%run('ch_processBowenRatio.m');