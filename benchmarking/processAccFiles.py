import xdr_acc
import numpy as np

filename = 'results/CPU/NONSMP/1/HEX/generic/single/0.1/32/out.000005.acc2'
with xdr_acc.File(filename, 150000) as f:
    print(np.min(f.acc), np.max(f.acc))