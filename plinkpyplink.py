from pyplink import PyPlink
import numpy as np

with PyPlink('SI_hair_128_10000_bpRN') as bed:
    all_individuals = bed.get_fam()['iid'].tolist()

file_name = "SI_hair_128_10000_bpRN"
individual_of_interest = "_".join(file_name.split("_")[:3])
unique_individuals_new = np.setdiff1d(all_individuals, individual_of_interest)
num=10
random_sample = np.random.choice(unique_individuals_new, num-1, replace=False)
final_sample = np.append(random_sample, individual_of_interest)


mask = [sample_id in final_sample for sample_id in final_sample]

with PyPlink('SI_hair_128_10000_bpRN_ind10_pyplink', 'w') as bed:
    pass
    for variant_id, genotypes in bed:
        subset_genotypes = genotypes[mask]
        print(f'Variant: {variant_id}, Genotypes: {subset_genotypes}')