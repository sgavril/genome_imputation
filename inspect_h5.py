import h5py

# Function to recursively print groups and datasets
def print_hdf5_item_structure(g, offset='    '):
    """ Print the input file/group/dataset name and begin iterations over its content """
    if isinstance(g, h5py.File):
        print(g.file, '(File)', g.name)
    elif isinstance(g, h5py.Dataset):
        print('(Dataset)', g.name, '    len =', g.shape)  # , g.dtype
    elif isinstance(g, h5py.Group):
        print('(Group)', g.name)

    if isinstance(g, h5py.File) or isinstance(g, h5py.Group):
        for key, val in dict(g).items():
            subg = val
            print(offset, key)  # , '    ', subg.name # , val, subg.len(), type(subg),
            print_hdf5_item_structure(subg, offset + '    ')

# Open the existing HDF5 file
with h5py.File('all_genotypes.h5', 'r') as f:
    print_hdf5_item_structure(f)
