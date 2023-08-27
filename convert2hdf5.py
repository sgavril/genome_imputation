import os, h5py
from pandas_plink import read_plink

def write_to_hdf5(hdf5_filename, data_dict):
    """Write genotype data to HDF5 file."""
    with h5py.File(hdf5_filename, 'w') as f:
        for key, value in data_dict.items():
            f.create_dataset(key, data=value)

if __name__ == '__main__':
    # Specify the directory containing PLINK Files
    plink_dir = 'outputs'

    all_genotypes = {}

    # Iterate over each file in the directory
    for filename in os.listdir(plink_dir):
        if filename.endswith('.bed'):
            sample_name = os.path.splitext(filename)[0]
            prefix = os.path.join(plink_dir, sample_name)

            # Read in the file using pandas_plink
            (bim, fam, bed) = read_plink(prefix)

            # Convert genotype data to a numpy array
            genotypes = bed.compute().values

            # Store genotypes
            all_genotypes[sample_name] = genotypes

    write_to_hdf5('all_genotypes.h5', all_genotypes)
