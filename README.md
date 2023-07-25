# genome_imputation
Code for genome imputation comparison study


### Notes for myself
venv3.6 contains uses python3.6 as being compatible with alphaplinkpython 0.0.8
    - as well as AlphaImpute2 after modifying jitclass imports

#### Calling AlphaImpute2
This works:
```
AlphaImpute2 \
    -bfile SI_hair_128_10000_bpRN \
    -binaryoutput \
    -out test.bim
```

Testing subset:
```
AlphaImpute2 \
    -bfile SI_hair_128_10000_bpRN_hail \
    -binaryoutput \
    -out test_hail.bim
```