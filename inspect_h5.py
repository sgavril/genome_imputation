import h5py
import numpy as np

# Open the existing HDF5 file to read
with h5py.File('all_genotypes.h5', 'r') as f:
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
                        
                        # Read the SNP data
                        snp_data = replicate_group['SNPs'][:]
                        
                        # Find unique values in the SNP data
                        unique_values = np.unique(snp_data)
                        
                        print(f"Unique SNP values for {sample_name}/{num_snps}/{snp_sel_method}/{num_ind}/{replicate}: {unique_values}")
