import h5py

with h5py.File('loo.dgf5', 'r') as f:
    for name in f:
        print("Dataset: ", name)

        data = f[name]

        print("Shape: ", data.shape)
        print("Data type: ", data.dtype)