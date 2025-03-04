#!/bin/bash
# Check if the user is in both the 'video' and 'render' groups
if groups  | grep -q '\bvideo\b' && groups  | grep -q '\brender\b'; then
  echo "$USERNAME is a member of both the 'video' and 'render' groups."
else
  echo "$USERNAME is NOT a member of both the 'video' and 'render' groups."
fi
echo "HSA_OVERRIDE_GFX_VERSION == ${HSA_OVERRIDE_GFX_VERSION}"
echo "short sleep to review status above..."
sleep 5

set -ex

# Write the Python code to test.py
cat <<EOF > test.py

 

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

EOF

 

# Run the Python file

echo "running some training tests - first cpu-only, then with iGPU"

python3 test.py


#time python /ryzers/lerobot/lerobot/scripts/train.py --dataset.repo_id=lerobot/pusht --policy.type=diffusion --env.type=pusht --device=cpu --steps=10

 

#time python /ryzers/lerobot/lerobot/scripts/train.py --dataset.repo_id=lerobot/pusht --policy.type=diffusion --env.type=pusht --device=cuda --steps=100




#time python /opt/lerobot/examples/2_evaluate_pretrained_policy.py