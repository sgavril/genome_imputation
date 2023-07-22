import h5py, os, glob

with h5py.File('loo.hdf5', 'w') as f:
    files = glob.glob('../loo/*.txt')

    for filename in files:
        with open(filename, 'r') as infile:
            for line in infile:
                values = line.split()
                data = list(map(int, values[1:]))
        dataset_name = os.path.splitext(os.path.basename(filename))[0]
        print(dataset_name)
        f.create_dataset(dataset_name, data=data)
