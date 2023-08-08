# genome_imputation
Code for genome imputation comparison study


### Notes for myself
- venv3.6 contains uses python3.6 as being compatible with alphaplinkpython 0.0.8
    - as well as AlphaImpute2 after modifying jitclass imports

### Overview
1. Run `squeue runImputationPipeline.sh` which creates the files of SNPs to mask down to in `data/snpsToMaskDownTo/`. 
2. Run `squeue maskGenotypesIndividuals.sh` to generate the masked replicate files.
3. Run the imputation jobs: `squeue alphaImpute2_parallel.sh` and `convertMaskedToVcfForBeagle.sh`.

### TODO
- Figure out how to combine all imputed genotypes into some python object (HDF5?)