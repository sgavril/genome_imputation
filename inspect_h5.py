import h5py

# Open the HDF5 file in read mode
with h5py.File('all_genotypes.h5', 'r') as f:
    # Loop through each sample_name
    for sample_name in f.keys():
        print(f"Checking sample: {sample_name}")
        sample_group = f[sample_name]
        
        # Loop through each num_snps
        for num_snps in sample_group.keys():
            print(f"  Checking num_snps: {num_snps}")
            num_snps_group = sample_group[num_snps]
            
            # Loop through each snp_sel_method
            for snp_sel_method in num_snps_group.keys():
                print(f"    Checking snp_sel_method: {snp_sel_method}")
                snp_sel_method_group = num_snps_group[snp_sel_method]
                
                # Loop through each num_ind
                for num_ind in snp_sel_method_group.keys():
                    print(f"      Checking num_ind: {num_ind}")
                    num_ind_group = snp_sel_method_group[num_ind]
                    
                    # Loop through each replicate
                    for replicate in num_ind_group.keys():
                        print(f"        Checking replicate: {replicate}")
                        replicate_group = num_ind_group[replicate]
                        
                        # Check if 'Masked_Positions' dataset exists under this replicate
                        if 'Masked_Positions' in replicate_group:
                            # Read the dataset into a NumPy array
                            masked_positions = replicate_group['Masked_Positions'][:]
                            
                            # Print the masked positions
                            print(f"        Masked Positions for {sample_name}/{num_snps}/{snp_sel_method}/{num_ind}/{replicate}:")
                            print(masked_positions[:10])  # Preview first 10 masked positions
                            
                        else:
                            print(f"        No 'Masked_Positions' in {replicate}")
                        
                        # Assuming the genotype data is stored in a dataset named 'Genotypes' under each replicate
                        if 'Genotypes' in replicate_group:
                            # Read the genotype data into a NumPy array
                            genotypes = replicate_group['Genotypes'][:]
                            
                            # Print some of the genotypes
                            print(f"        Genotypes for {sample_name}/{num_snps}/{snp_sel_method}/{num_ind}/{replicate}:")
                            print(genotypes[:10, :10])  # Preview first 10 rows and 10 columns
