# genome_imputation
Code for genome imputation comparison study


### Notes for myself
venv/ contains AlphaImpute2 (py 3.11)
venv3.6 contains alphaplinkpython (py 3.6)

#### Calling AlphaImpute2
```
AlphaImpute2 \
    -bfile SI_hair_128_10000_bpRN.bed \
    -binaryoutput \
    -out test.bim
```

This does not work:
```
AlphaImpute2 \
    -bfile SI_hair_128_10000_bpRN_hail \
    -binaryoutput \
    -out test.bim
```
This works:
```
AlphaImpute2 \
    -genotypes SI_hair_128_10000_bpRN.txt \
    -binaryoutput \
    -out test.bim
```