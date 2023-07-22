from pandas_plink import read_plink1_bin

test = read_plink1_bin("../loo/SI_hair_128_10000_bpRN.bed",
                       "../loo/SI_hair_128_10000_bpRN.bim",
                       "../loo/SI_hair_128_10000_bpRN.fam")

test2 = read_plink1_bin("../loo/SI_hair_128_1000_bpRN.bed",
                       "../loo/SI_hair_128_1000_bpRN.bim",
                       "../loo/SI_hair_128_1000_bpRN.fam")