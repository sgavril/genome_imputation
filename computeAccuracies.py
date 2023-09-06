import h5py
import numpy as np

from pandas_plink import read_plink

(bim, fam, bed) = read_plink('/home/stefan.gavriliuc/projects/imputation/02_AlphaImpute2/Sable_October_2018_filt')
reference_genotypes = bed.compute()

def calculate_accuracy(ref_geno, imp_geno):
    full_matches = np.sum(ref_geno == imp_geno)
    partial_matches = 0
    for i in range(len(ref_geno)):
        if ref_geno[i] == 0 and imp_geno[i] == 1:
            partial_matches += 0.5
        if ref_geno[i] == 1 and imp_geno[i] in [0, 2]:
            partial_matches += 0.5
        if ref_geno[i] == 2 and imp_geno[i] == 1:
            partial_matches += 0.5
    accuracy = (full_matches + partial_matches) / len(ref_geno)
    return accuracy

# Open the HDF5 file in read mode
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
                        
                        print(f"        Datasets: {list(replicate_group.keys())}")

                        # Load imputed genotypes and masked positions
                        imputed_genotypes = replicate_group['SNPs'][:]
                        masked_positions = replicate_group['Masked_Positions'][:]

                        # print(f"        Sample Imputed Genotypes: {imputed_genotypes}")
                        # print(f"        Sample Masked Positions: {masked_positions}")
                        
                        # Filter reference and imputed genotypes to only include masked positions
                        masked_reference_genotypes = reference_genotypes[masked_positions[0], masked_positions[1]]
                        masked_imputed_genotypes = imputed_genotypes[masked_positions[0], masked_positions[1]]
                        
                        # Compute percent match
                        percent_match = np.mean(masked_reference_genotypes == masked_imputed_genotypes) * 100
                        
                        # Compute genotype correlation
                        correlation = np.corrcoef(masked_reference_genotypes, masked_imputed_genotypes)[0, 1]
                        
                        # Compute custom accuracy method
                        custom_accuracy = calculate_accuracy(masked_reference_genotypes, masked_imputed_genotypes)

                        print(f"Accuracy Metrics for {sample_name}/{num_snps}/{snp_sel_method}/{num_ind}/{replicate}:")
                        print(f"  Percent Match: {percent_match}%")
                        print(f"  Genotype Correlation: {correlation}")
                        print(f"  Accuracy: {new_accuracy * 100}%")