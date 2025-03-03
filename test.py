
 

import torch

 

#Example usage on ROCm

if torch.cuda.is_available():

    device = torch.device("cuda")

    # Check if ROCm is available

    if torch.version.hip:

        device = torch.device("cuda")

    else:

         raise("ROCm is not properly configured. HIP")

else:

    #device = torch.device("cpu")

    raise("ROCm is not properly configured. ROCM")

 

x = torch.tensor([1.0, 2.0, 3.0, 4.0], device=device)

mean_x = torch.mean(x)

print(mean_x) # Output: tensor(2.5)

 

y = torch.tensor([[1.0, 2.0], [3.0, 4.0]], device=device)

mean_y_dim0 = torch.mean(y, dim=0)

mean_y_dim1 = torch.mean(y, dim=1)

print(mean_y_dim0) # Output: tensor([2.0, 3.0])

print(mean_y_dim1) # Output: tensor([1.5, 3.5])

