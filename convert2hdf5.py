from pandas_plink import read_plink
import h5py, numpy as np

plink_files = []

with h5py.File('genotypes.h5', 'a') as f:
    for path in plink_files:
        (_, _, G) = read_plink(path)

        genotype_data_numpy = G.compute()

        if 'genotypes' in f:
            dataset = f['genotypes']
            new_shape = (dataset.shape[0] + genotype_data_numpy.shape[0], *genotype_data_numpy.shape[1:])
            dataset.resize(new_shape)
            dataset[-genotype_data_numpy.shape[0]:] = genotype_data_numpy
        else:
            maxshape = (None, *genotype_data_numpy.shape[1:])
            f.create_dataset('genotypes', data=genotype_data_numpy, maxshape=maxshape, chunks=True)

