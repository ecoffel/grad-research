# -*- coding: utf-8 -*-
"""
Created on Sat Oct  7 15:09:18 2017

@author: Ethan
"""

import numpy as np
from matplotlib import pyplot as plt
from sompy.sompy import SOMFactory

data = np.random.randint(0, 255, (100, 3))

dims = np.array([5, 5])
iterations = 2000
learningRate = 0.01

# normalize
data = data / data.max()

sm = SOMFactory().build(data, normalization = 'var', initialization='random', component_names=['r', 'g', 'b'])
sm.train(n_job=1, verbose=False, train_rough_len=2, train_finetune_len=5)
topographic_error = sm.calculate_topographic_error()
quantization_error = np.mean(sm._bmu[1])