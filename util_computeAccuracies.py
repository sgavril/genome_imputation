import h5py, argparse, numpy as np, pandas as pd
from pandas_plink import read_plink

# genotype_hdf5_file='all_genotypes_full.h5'
# accuracy_output_file='accuracy_metrics_test.csv'


(bim, fam, bed) = read_plink('data/filtered/Sable_October_2018_filt')
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


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description = "Compute accuracies from a custom HDF5 file.")
    parser.add_argument('input_genotype_hdf5_file', type=str, help="Path to custom HDF5 file containing imputed genotypes.")
    parser.add_argument('output_accuracy_metrics', type=str, help='Name of output CSV file containing accuracy metrics.')
    args = parser.parse_args()

    print(f'Input genotype file: {args.input_genotype_hdf5_file}')
    print(f'Output csv file: {args.output_accuracy_metrics}')

    df = pd.DataFrame(columns=['Sample', 'num_snps', 'snp_method', 'num_ind', 
                                'num_imputed_snps', 'Percent_Match', 'Genotype_Correlation',
                            'Custom_Accuracy'])  

    genotype_hdf5_file = args.input_genotype_hdf5_file
    accuracy_output_file = args.output_accuracy_metrics

    # Open the HDF5 file in read mode
    with h5py.File(genotype_hdf5_file, 'r') as f:
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
                            print(f"{replicate_group}")
                            # Get the sample names for this replicate
                            sample_names = replicate_group['Sample_Names'][:]
                            sample_names_str = [name.decode('utf-8') for name in sample_names]
                            individual_index = sample_names_str.index(sample_name)

                            # Load imputed genotypes and masked positions
                            imputed_genotypes = replicate_group['SNPs'][:, individual_index]
                            masked_positions = replicate_group['Masked_Positions']

                            # Filter reference and imputed genotypes to only include masked positions
                            masked_reference_genotypes = reference_genotypes[masked_positions, individual_index]
                            masked_imputed_genotypes = imputed_genotypes[masked_positions]

                            # Compute percent match
                            percent_match = np.mean(masked_reference_genotypes == masked_imputed_genotypes) * 100

                            if np.isnan(masked_reference_genotypes).any() or np.isnan(masked_imputed_genotypes).any():
                                print("Arrays contain NaN values.")
                            if np.isinf(masked_reference_genotypes).any() or np.isinf(masked_imputed_genotypes).any():
                                print("Arrays contain Inf values.")

                            # Find indices where NaNs are present in each array
                            nan_indices_reference = np.where(np.isnan(masked_reference_genotypes))[0]
                            nan_indices_imputed = np.where(np.isnan(masked_imputed_genotypes))[0]
                            # print("Indices of NaN values in Reference Genotypes:", nan_indices_reference)
                            # print("Indices of NaN values in Imputed Genotypes:", nan_indices_imputed)

                            # Combine and find unique indices where either array has a NaN
                            unique_nan_indices = np.unique(np.concatenate((nan_indices_reference, nan_indices_imputed)))

                            # Remove these indices from both arrays
                            # Remove these indices from both arrays
                            filtered_reference_genotypes = np.delete(masked_reference_genotypes, unique_nan_indices)
                            filtered_imputed_genotypes = np.delete(masked_imputed_genotypes, unique_nan_indices)
                            print(f"Number of filtered imputed genotypes: {len(filtered_imputed_genotypes)}")

                            # Compute genotype correlation
                            if len(filtered_reference_genotypes) > 1 and np.var(filtered_reference_genotypes) != 0 and np.var(filtered_reference_genotypes) != 0:
                                correlation = np.corrcoef(filtered_reference_genotypes, filtered_imputed_genotypes)[0, 1]
                            else:
                                correlation = 'NA'
                                print(f"Skipped correlation calculation for {sample_name}/{num_snps}/{snp_sel_method}/{num_ind}/{replicate} due to insufficient data.")
                                print(f"  Length: {len(filtered_reference_genotypes)}")
                                print(f"  Variance of reference: {np.var(filtered_reference_genotypes)}")
                                print(f"  Variance of imputed: {np.var(filtered_reference_genotypes)}")

                            # Compute custom accuracy method
                            custom_accuracy = calculate_accuracy(filtered_reference_genotypes, filtered_imputed_genotypes)

                            print(f"Accuracy Metrics for {sample_name}/{num_snps}/{snp_sel_method}/{num_ind}/{replicate}:")
                            print(f"  Percent Match: {percent_match}%")
                            print(f"  Genotype Correlation: {correlation}")
                            print(f"  Accuracy: {custom_accuracy * 100}%")
                            
                            iter_df = pd.DataFrame({
                                'Sample': [sample_name],
                                'num_snps': [num_snps],
                                'snp_method': [snp_sel_method],
                                'num_ind': [num_ind],
                                'num_imputed_snps': [len(filtered_imputed_genotypes)],
                                'replicate': [replicate],
                                'Percent_Match': [percent_match],
                                'Genotype_Correlation': [correlation],
                                'Custom_Accuracy': [custom_accuracy]
                            })

                            # Append the results to the main DataFrame
                            df = pd.concat([df, iter_df], ignore_index=True)

    df = df.round({
        '%match': 2,
        'correlation': 2,
        'custom_accuracy': 2
    })

    df.to_csv(accuracy_output_file, index=False)