import os, h5py, numpy as np
from pandas_plink import read_plink


def write_to_hdf5(hdf5_filename, data_dict):
    """Write genotype data to HDF5 file."""
    with h5py.File(hdf5_filename, 'w') as f:
        for key, value in data_dict.items():
            fields = key.split('_')
            print(fields)
            sample_name = '_'.join(fields[:3])
            num_snps = fields[3]
            snp_sel_method = fields[4]
            num_ind = fields[5]
            replicate = fields[6]

            group_name = f"{sample_name}/{num_snps}/{snp_sel_method}/{num_ind}/{replicate}"
            print(group_name)
            if group_name not in f:
                group = f.create_group(group_name)
            else:
                group = f[group_name]

            value = value.astype('int')
            group.create_dataset('SNPs', data=value, chunks=True, compression='gzip', compression_opts=9)

if __name__ == '__main__':
    # Specify the directory containing PLINK Files
    plink_dir = 'replicates'

    all_genotypes = {}

    # Iterate over each file in the directory
    for filename in os.listdir(plink_dir):
        if filename.endswith('.bed'):
            sample_name = os.path.splitext(filename)[0]
            prefix = os.path.join(plink_dir, sample_name)

            # Read in the file using pandas_plink
            (bim, fam, bed) = read_plink(prefix)

            # Convert genotype data to a numpy array
            genotypes = bed.compute()

            # Store genotypes
            all_genotypes[sample_name] = genotypes

    write_to_hdf5('all_genotypes.h5', all_genotypes)
