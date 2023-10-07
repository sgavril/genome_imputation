import os, h5py, numpy as np, argparse
from pandas_plink import read_plink

# genotype_output_hdf5_file='all_genotypes.h5'
# masked_plink_directory='replicates2'
# plink_dir = 'outputs2'

# genotype_output_hdf5_file='all_genotypes_test.h5'
# masked_plink_directory='replicates3'
# plink_dir = 'outputs3'

# genotype_output_hdf5_file='all_genotypes_full.h5'
masked_plink_directory='replicates'
plink_dir = 'outputs'

# genotype_output_hdf5_file='beagle_test.h5'
# masked_plink_directory='replicates3'
# plink_dir = 'outputs_beagle3'

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
    unique_masked_positions = np.unique(masked_positions)
    return unique_masked_positions

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
    parser = argparse.ArgumentParser(description = "Process a list of PLINK genotype files and write to HDF5.")
    parser.add_argument('--chunk_file', type=str, required=True, help="Path to the text file containing filenames for this chunk.")
    args = parser.parse_args()

    all_genotypes = {}
    sample_names_dict = {}

    # Iterate over each file in the directory
    print("ADDING GENOTYPES TO H5...")
    count=0
    with open(args.chunk_file, 'r') as f:
        filenames = [line.strip() for line in f]
        print(f"Number of files: {len(filenames)}")
        chunk_identifier = os.path.splitext(os.path.basename(args.chunk_file))[0]  # e.g., "chunk_1" from "chunk_1.txt"
        genotype_output_hdf5_file = f'data/hdf5_chunks/output_{chunk_identifier}.h5'
        for filename in filenames:
            count+=1
            if filename.endswith('.bim'):
                sample_name = os.path.splitext(filename)[0]
                prefix = os.path.join(plink_dir, sample_name)

                # Read in the file using pandas_plink
                (bim, fam, bed) = read_plink(prefix, verbose=False)

                # Convert genotype data to a numpy array
                genotypes = bed.compute()

                # Store genotypes
                all_genotypes[sample_name] = genotypes

                sample_names = fam['iid'].tolist()
                sample_names_dict[sample_name] = sample_names
                print(f"Number of genotype files added: {len(sample_names_dict)}")

    write_to_hdf5(genotype_output_hdf5_file, all_genotypes, sample_names_dict)

    masked_positions_dict = {}
    masked_plink_dir = masked_plink_directory
    print("UPDATING IMPUTED POSITIONS...")
    for filename in os.listdir(masked_plink_dir):
        if filename.endswith('.bed'):
            print(filename)
            sample_name = os.path.splitext(filename)[0]
            prefix = os.path.join(masked_plink_dir, sample_name)
            masked_positions = load_masked_positions(prefix)
            masked_positions_dict[sample_name] = masked_positions

    add_masked_positions_to_hdf5(genotype_output_hdf5_file, masked_positions_dict)