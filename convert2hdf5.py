import os, h5py, numpy as np
from pandas_plink import read_plink


def write_to_hdf5(hdf5_filename, data_dict, sample_names_dict):
    """Write genotype data to HDF5 file."""
    with h5py.File(hdf5_filename, 'w') as f:
        for key, value in data_dict.items():
            fields = key.split('_')
            sample_name = '_'.join(fields[:3])
            num_snps = fields[3]
            snp_sel_method = fields[4]
            num_ind = fields[5]
            replicate = fields[6]

            group_name = f"{sample_name}/{num_snps}/{snp_sel_method}/{num_ind}/{replicate}"
            if group_name not in f:
                group = f.create_group(group_name)
            else:
                group = f[group_name]

            value = value.astype('int')  # Convert to float64 to accommodate NaN
            dataset = group.create_dataset('SNPs', data=value, chunks=True, compression='gzip', compression_opts=9)
            group.create_dataset('Sample_Names', data=np.array(sample_names_dict[key], dtype='S'))

def load_masked_positions(plink_path):
    """ Get the indices of positions that were masked (and subsequently imputed) """
    (bim, fam, bed) = read_plink(plink_path)
    masked_genotypes = bed.compute()
    masked_positions = np.where(np.isnan(masked_genotypes))[0]
    return masked_positions

def add_masked_positions_to_hdf5(hdf5_filename, masked_positions_dict):
    """ Append an array containing the positions that were masked. """
    with h5py.File(hdf5_filename, 'a') as f:
        for sample_name in f.keys():
            sample_group = f[sample_name]
            for num_snps in sample_group.keys():
                num_snps_group = sample_group[num_snps]
                for snp_sel_method in num_snps_group.keys():
                    snp_sel_method_group = num_snps_group[snp_sel_method]
                    for num_ind in snp_sel_method_group.keys():
                        num_ind_group = snp_sel_method_group[num_ind]
                        for replicate in num_ind_group.keys():
                            replicate_group = num_ind_group[replicate]
                            key = f"{sample_name}_{num_snps}_{snp_sel_method}_{num_ind}_{replicate}"
                            masked_positions = masked_positions_dict.get(key, None)
                            if masked_positions is not None:
                                replicate_group.create_dataset('Masked_Positions', data=masked_positions)

def validate_bed():
    pass

if __name__ == '__main__':
    # Specify the directory containing PLINK Files
    plink_dir = 'outputs'

    all_genotypes = {}
    sample_names_dict = {}

    # Iterate over each file in the directory
    print("ADDING GENOTYPES TO H5...")
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

            sample_names = fam['iid'].tolist()
            sample_names_dict[sample_name] = sample_names

    write_to_hdf5('all_genotypes.h5', all_genotypes, sample_names_dict)

    masked_positions_dict = {}
    masked_plink_dir = 'replicates'
    print("UPDATING IMPUTED POSITIONS...")
    for filename in os.listdir(masked_plink_dir):
        if filename.endswith('.bed'):
            print(filename)
            sample_name = os.path.splitext(filename)[0]
            prefix = os.path.join(masked_plink_dir, sample_name)
            masked_positions = load_masked_positions(prefix)
            masked_positions_dict[sample_name] = masked_positions

    add_masked_positions_to_hdf5('all_genotypes.h5', masked_positions_dict)

