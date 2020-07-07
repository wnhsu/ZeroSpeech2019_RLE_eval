# Author: Wei-Ning Hsu
# 
# This is adapted from $HOME/system/eval/scripts/make_abx_files.py in the 
# ZS2019 Challenge's docker image, which omits consecutive codes that are
# the same as the previous codes and is used to compute segment ABX score.


from __future__ import division

import glob
import numpy as np
import sys
from sklearn import preprocessing

# Takes embeddings from submission (arbitrary times):
# in : 
#   0107_400123_0000.txt : (one_hot_vector)
#       0 0 0 1 0 0
#       0 0 0 0 0 1
#       0 0 0 0 0 1
#       1 0 0 0 0 0
#       1 0 0 0 0 0
# out : a numpy file with two keys. "features" contains a 2-D matrix with 
#       feature along the column and times along the axis. 
#       "time" contains the middle time for each phoneme
#          
#       0107_400123_0000.npz :
#       features:[
#             [0 0 0 1 0 0],
#             [0 0 0 0 0 1],
#             [1 0 0 0 0 0]])  
#       time:[0,0.5,1]


def main(init_dir,dest_dir):
    for f in glob.iglob(init_dir+"/*.txt"):
        u_split = []
        prev_value_s = None
        with open(f, 'r') as myfile:
            for line in myfile:
                if line != prev_value_s:
                    u_split.append(line.rstrip())
                    prev_value_s = line

        time=[]
        features=[]
        for i in range(len(u_split)):
            unit_data=u_split[i].split(' ') 
            if len(unit_data)==1:
                continue
            time.append(i/len(u_split))
            #time.append(float(unit_data.pop(0)))
            features.append([float(x) for x in unit_data]) 
        filename=f.split('/')[-1].split('.')[0]
        np.savez(dest_dir+'/'+filename+'.npz', features=features, time=time)

if __name__ == '__main__':
   init_dir=sys.argv[1]
   dest_dir=sys.argv[2]
   main(init_dir,dest_dir)

