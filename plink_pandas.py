import pandas_plink as pp
import pandas as pd

# test = read_plink1_bin("../loo/SI_hair_128_10000_bpRN.bed",
#                        "../loo/SI_hair_128_10000_bpRN.bim",
#                        "../loo/SI_hair_128_10000_bpRN.fam")

file_name = "SI_hair_128_10000_bpRN"
(bim, fam, bed) = pp.read_plink(file_name)
individual_of_interest = "_".join(file_name.split("_")[:3])
iteration = "_".join(file_name.split("_")[:5])
unique_individuals = pd.Series(fam.iid.unique())

nums_to_sample = [10, 25, 50, 75, 100, 110]

for num in nums_to_sample:
    # Get a sample of individuals, ensuring the individual of interest is included
    sample_inds = unique_individuals.sample(n=num-1, replace=False)
    sample_inds_list = sample_inds.to_list()
    sample_inds_list.append(individual_of_interest)
    
    # Subset the original data by the sampled individuals
    subset = bed.sel[dict(sample=sample_inds_list)]
    write_plink1_bin(subset, f'{iteration}_{num}.bed')

num=10
sample_inds = unique_individuals.sample(n=num-1, replace=False, random_state=1)
sample_inds_list.append(individual_of_interest)
subset = bed.sel[dict(sample=sample_inds_list)]
