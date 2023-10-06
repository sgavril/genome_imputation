import os, h5py, numpy as np, logging
from multiprocessing import Pool
from pandas_plink import read_plink

# genotype_output_hdf5_file='all_genotypes.h5'
# masked_plink_directory='replicates2'
# plink_dir = 'outputs2'

# genotype_output_hdf5_file='all_genotypes_test.h5'
# masked_plink_directory='replicates3'
# plink_dir = 'outputs3'

genotype_output_hdf5_file='alphaimpute2.h5'
masked_plink_directory='replicates'
plink_dir = '/scratch/23176676/outputs'

logging.basicConfig(filename='logs/convert2hdf5.log', 
                    level=logging.INFO,
                    filemode='w',
                    format='%(asctime)s - %(levelname)s - %(message)s')

def write_to_hdf5(hdf5_filename, data_dict, sample_names_dict):
    """Write genotype data to HDF5 file."""
    with h5py.File(hdf5_filename, 'w') as f:
        for key, value in data_dict.items():
            fields = key.split('_')
            sample_name = '_'.join(fields[:3])
            num_snps = fields[3]
            snp_sel_method = fields[4]
            num_ind = fields[5]
            replicate = fields[6]

            group_name = f"{sample_name}/{num_snps}/{snp_sel_method}/{num_ind}/{replicate}"
            
            group = f.require_group(group_name)

            dataset = group.create_dataset('SNPs', data=value, chunks=True, compression='gzip', compression_opts=4)
            group.create_dataset('Sample_Names', data=np.array(sample_names_dict[key], dtype='S'))

    logging.info('Writing results to HDF5 file completed.')
    logging.info(f'Number of entries: {len(data_dict)}')

def load_masked_positions(plink_path):
    """ Get the indices of positions that were masked (and subsequently imputed) """
    (bim, fam, bed) = read_plink(plink_path, verbose=False)
    masked_genotypes = bed.compute()
    masked_positions = np.where(np.isnan(masked_genotypes))[0]
    unique_masked_positions = np.unique(masked_positions)
    return unique_masked_positions

def add_masked_positions_to_hdf5(hdf5_filename, masked_positions_dict):
    """ Append an array containing the positions that were masked. """
    with h5py.File(hdf5_filename, 'a') as f:
        for sample_name in f.keys():
            sample_group = f[sample_name]
            for num_snps in sample_group.keys():
                num_snps_group = sample_group[num_snps]
                for snp_sel_method in num_snps_group.keys():
                    snp_sel_method_group = num_snps_group[snp_sel_method]
                    for num_ind in snp_sel_method_group.keys():
                        num_ind_group = snp_sel_method_group[num_ind]
                        for replicate in num_ind_group.keys():
                            replicate_group = num_ind_group[replicate]
                            key = f"{sample_name}_{num_snps}_{snp_sel_method}_{num_ind}_{replicate}"
                            masked_positions = masked_positions_dict.get(key, None)
                            if masked_positions is not None:
                                replicate_group.create_dataset('Masked_Positions', data=masked_positions)

def validate_bed():
    pass

def process_chunk(file_chunk, plink_dir):
    all_genotypes = {}
    sample_names_dict = {}

    chunk_index = genotype_file_chunks.index(file_chunk)
    
    logging.info(f"Processing masked positions for chunk {chunk_index + 1}/{len(genotype_file_chunks)}...")
    
    for filename in file_chunk:
        if filename.endswith('.bed'):
            sample_name = os.path.splitext(filename)[0]
            prefix = os.path.join(plink_dir, sample_name)

            # Read in the file using pandas_plink
            (bim, fam, bed) = read_plink(prefix, verbose=False)

            # Convert genotype data to a numpy array
            genotypes = bed.compute()

            # Store genotypes
            all_genotypes[sample_name] = genotypes

            sample_names = fam['iid'].tolist()
            sample_names_dict[sample_name] = sample_names

    return all_genotypes, sample_names_dict

def process_chunk_masked_positions(file_chunk, masked_plink_dir):
    masked_positions_dict = {}
    for filename in file_chunk:
        if filename.endswith('.bed'):
            sample_name = os.path.splitext(filename)[0]
            prefix = os.path.join(masked_plink_dir, sample_name)
            masked_positions = load_masked_positions(prefix)
            masked_positions_dict[sample_name] = masked_positions
    return masked_positions_dict

if __name__ == '__main__':
    logging.info("ADDING GENOTYPES TO H5...")
    all_files = [f for f in os.listdir(plink_dir) if f.endswith('.bed')]
    chunk_size = 1000
    num_processes = 4
    genotype_file_chunks = [all_files[i:i+chunk_size] for i in range(0, len(all_files), chunk_size)]
    def process(genotype_file_chunks): return process_chunk(genotype_file_chunks, plink_dir)
    with Pool(num_processes) as pool:
        results = pool.map(process, genotype_file_chunks)

    # Aggregate results from chunks
    all_genotypes = {}
    sample_names_dict = {}
    for res in results: 
        all_genotypes.update(res[0])
        sample_names_dict.update(res[1])
    write_to_hdf5(genotype_output_hdf5_file, all_genotypes, sample_names_dict)

    # Process masked positions in parallel
    logging.info("UPDATING IMPUTED POSITIONS...")
    masked_plink_dir = masked_plink_directory
    all_masked_files = [f for f in os.listdir(masked_plink_dir)]
    masked_file_chunks = [all_masked_files[i:i+chunk_size] for i in range(0, len(all_masked_files), chunk_size)]
    def process_masked(masked_file_chunks): return process_chunk_masked_positions(masked_file_chunks, plink_dir)
    with Pool(num_processes) as pool:
        masked_positions_results = pool.map(process_masked, masked_file_chunks)

    # Aggregate results from all processes
    masked_positions_dict = {}
    for res in masked_positions_results:
        masked_positions_dict.update(res)

    # Update HDF5 with masked positions
    add_masked_positions_to_hdf5(genotype_output_hdf5_file, masked_positions_dict)

    # # Process each chunk
    # for idx, file_chunk in enumerate(file_chunks):
    #     print(f"Processing chunk {idx + 1} of {len(file_chunks)}")
    #     all_genotypes, sample_names_dict = process_chunk(file_chunk, plink_dir)

    #     write_to_hdf5(genotype_output_hdf5_file, all_genotypes, sample_names_dict)

    #     del all_genotypes
    #     del sample_names_dict
    

    # chunk_size=1000
    # for idx, filename in enumerate(masked_file_chunks):
    #     print(f"Processing masked positions chunk {idx + 1} of {len(masked_file_chunks)}")
    #     masked_positions_dict = process_chunk_masked_positions(file_chunk, masked_plink_dir)
    #     add_masked_positions_to_hdf5(genotype_output_hdf5_file, masked_positions_dict)
    #     del masked_positions_dict
