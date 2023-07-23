import alphaplinkpython.PlinkWriter as pw

bim = pw.readBimFile("../loo/SI_hair_128_10000_bpEQ.bim")
fam = pw.readFamFile("../loo/SI_hair_128_10000_bpEQ.fam")
bed = pw.readBedFile("../loo/SI_hair_128_10000_bpEQ.bed", bim, fam)

pw.writeBedFile(bed, 'test.bed')