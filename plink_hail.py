import hail as hl, numpy as np

hl.init()

mt = hl.import_plink(bed='SI_hair_128_10000_bpRN.bed',
                    bim='SI_hair_128_10000_bpRN.bim',
                    fam='SI_hair_128_10000_bpRN.fam',
                    skip_invalid_loci=True)

all_individuals = mt.s.collect()
file_name = "SI_hair_128_10000_bpRN"
individual_of_interest = "_".join(file_name.split("_")[:3])
unique_individuals_new = np.setdiff1d(all_individuals, individual_of_interest)
num=10
random_sample = np.random.choice(unique_individuals_new, num-1, replace=False)
final_sample = np.append(random_sample, individual_of_interest).tolist()

mt_filtered = mt.filter_cols(hl.literal(final_sample).contains(mt.s))
hl.export_plink(mt_filtered, 'SI_hair_128_10000_bpRN_hail')