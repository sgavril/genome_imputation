import h5py, os
import numpy as np
from pandas_plink import read_plink


def load_masked_positions(plink_path):
    (bim, fam, bed) = read_plink(plink_path)
    masked_genotypes = bed.compute()
    masked_positions = np.where(np.isnan(masked_genotypes))
    return masked_positions

masked_positions_dict = {}
masked_plink_dir = 'replicates'

for filename in os.listdir(masked_plink_dir):
    if filename.endswith('.bed'):
        sample_name = os.path.splitext(filename)[0]
        prefix = os.path.join(masked_plink_dir, sample_name)
        
        masked_position = load_masked_positions(prefix)

        masked_positions_dict[sample_name] = masked_position

print(masked_positions_dict.keys())


# Open the existing HDF5 file to update
with h5py.File('all_genotypes.h5', 'a') as f:  # Note the 'a' mode for appending
    # Loop through each sample_name
    for sample_name in f.keys():
        sample_group = f[sample_name]
        
        # Loop through each num_snps
        for num_snps in sample_group.keys():
            num_snps_group = sample_group[num_snps]
            
            # Loop through each snp_sel_method
            for snp_sel_method in num_snps_group.keys():
                snp_sel_method_group = num_snps_group[snp_sel_method]
                
                # Loop through each num_ind
                for num_ind in snp_sel_method_group.keys():
                    num_ind_group = snp_sel_method_group[num_ind]

                    # Loop through each replicate
                    for replicate in num_ind_group.keys():
                        replicate_group = num_ind_group[replicate]

                        # Get the corresponding masked positions
                        key = f"{sample_name}_{num_snps}_{snp_sel_method}_{num_ind}_{replicate}"
                        print(key)
                        masked_positions = masked_positions_dict.get(key, None)
                        print(masked_positions)
                        
                        if masked_positions is not None:
                            # Add the masked positions as a new dataset under this replicate
                            replicate_group.create_dataset('Masked_Positions', data=masked_positions)