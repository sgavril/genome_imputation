# genome_imputation
Code for genome imputation comparison study


### Notes for myself
- venv3.6 contains uses python3.6 as being compatible with alphaplinkpython 0.0.8
    - as well as AlphaImpute2 after modifying jitclass imports
- AI2 results currently stored at `/scratch/23176564/`

### Overview
1. Run `squeue runImputationPipeline.sh` which creates the files of SNPs to mask down to in `data/snpsToMaskDownTo/`. 
2. Run `squeue maskGenotypesIndividuals.sh` to generate the masked replicate files to `replicates/`.
3. Run the imputation jobs: `squeue runImputation_alphaImpute2.sh` and `runImputation_beagle.sh`.
4. Then run jobs to create hdf5 file (currently parameters must be changed in `convert2hdf5.py`) using `squeue convert2hdf5.sh`.
5. Then lastly `squeue computeAccuracy.sh` for both AI2 and Beagle, changing parameters in `computeAccuracies.py`. 

### TODO
- ~~Figure out how to combine all imputed genotypes into some python object (HDF5?)~~
- compute SNP-wise accuracy (using some script to subset hdf5)
- determine how to estimate best reference individuals 
- problem: figure out HD vs LD in AlphaImpute2, and check for Beagle
```
        Population Imputation Only        
------------------------------------------
Number of HD individuals: 23
Number of LD individuals: 3
```