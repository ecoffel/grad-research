# -*- coding: utf-8 -*-
"""
Created on Tue Mar 19 10:51:12 2019

@author: Ethan
"""

import math

def wetBulb(T, RH):
    return T * math.atan(.151977 * (RH + 8.313659)**(0.5)) + math.atan(T + RH) - \
            math.atan(RH - 1.676331) + (.00391838 * (RH ** (3.0/2)) * math.atan(.023101 * RH)) - 4.686035