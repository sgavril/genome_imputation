from pysnptools.snpreader import Bed
import numpy as np

bed_data = Bed("../loo/SI_hair_128_10000_bpRN.bed", count_A1=False)
all_individuals = bed_data.iid[:,1]
file_name = "SI_hair_128_10000_bpRN"
individual_of_interest = "_".join(file_name.split("_")[:3])
unique_individuals_new = np.setdiff1d(all_individuals, individual_of_interest)
num=10
random_sample = np.random.choice(unique_individuals_new, num-1, replace=False)
final_sample = np.append(random_sample, individual_of_interest)

snp_data = Bed("../loo/SI_hair_128_10000_bpRN.bed", count_A1=False)
snp_data_sub = snp_data[:,final_sample_indices]
Bed.write("SI_hair_128_bpRN_ind10.bed", snp_data_sub, count_A1=False)

mask = np.isin(all_individuals, final_sample)
subset = bed_data[mask, :]
subset.write("SI_hair_128_bpRN_ind10.bed")