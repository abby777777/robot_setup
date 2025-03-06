# LeRobot Setup and Docker Run Instructions

This guide provides comprehensive steps to set up your system, clone, and run the Docker container. It covers configuring USB serial devices, preparing the Docker environment, testing and calibration, setting up the robot, running inference, and collecting datasets.

---

## 1. Set Up Udev Rules for USB Serial Devices

1. **Record Serial IDs:**  
   First, connect only the leader arm (e.g., to your Jetson or Pheonix) and record the serial ID by running:
   ```bash
   ll /dev/serial/by-id/


2. **Edit Udev Rules:**
    Edit the first lines of ./99-usb-serial.rules (make this file if it doesn't exist) to have the idVendor, product and serial that are specific to your lerobot. Here are examples of mine.

    SUBSYSTEM=="tty", ATTRS{idVendor}=="2f5d", ATTRS{idProduct}=="2202", ATTRS{serial}=="BA98C8C350304A46462E3120FF121B06", SYMLINK+="ttyACM_kochleader"
    
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2f5d", ATTRS{idProduct}=="2202", ATTRS{serial}=="00000000000000000000000000000000", SYMLINK+="ttyACM_kochfollower"

3. **Apply the Rules:**

    sudo cp ./99-usb-serial.rules /etc/udev/rules.d/
    sudo reboot


## 2. Prepare the Docker Base Image

docker pull rocm/pytorch:rocm6.3.3_ubuntu22.04_py3.10_pytorch_release_2.4.0

## 3. Set Up X11 Access

xhost +local:

## 4. Build and Run the Docker Container
Note that you need to change the video devices to the current ones that show on your computer. You also need to ensure that the model/policy you are trying to deploy (if that is part of your goal) is mounted by changing the -v paths.

docker build -t ryzerdocker .

sudo docker run -it --rm --shm-size=16G \
  --cap-add=SYS_PTRACE \
  --network=host \
  --ipc=host \
  -e HSA_OVERRIDE_GFX_VERSION=11.0.0 \
  --device=/dev/kfd \
  --device=/dev/dri \
  --device=/dev/ttyACM_kochleader:/dev/ttyACM_kochleader \
  --device=/dev/ttyACM_kochfollower:/dev/ttyACM_kochfollower \
  --device=/dev/video0:/dev/video0 \
  --device=/dev/video2:/dev/video2 \
  --security-opt seccomp=unconfined \
  --group-add video \
  --group-add render \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $(pwd)/pretrained_model/:/opt/pretrained_model/ \
  -p 8888:8888 \
  ryzerdocker


## 5. Testing and Calibration

1. **To check video streaming, choose the one you are trying to stream.**

    Example command: ffplay /dev/video0

2. **Update Video Device Configuration**

    Edit the file lerobot/lerobot/common/robot_devices/robots config.py and update the two instances where the word logitech appears to match your actual device values (e.g., /dev/video0 and /dev/video1).

    Note: After updating, push the changes to GitHub so the Dockerfile can clone the new config file (disable cache if necessary).

3. **Before you try moving robot, make sure to callibrate**

    python lerobot/scripts/control_robot.py --robot.type=koch --control.type calibrate

## Robot Operation Commands

1. **Record a Dataset**
python lerobot/scripts/control_robot.py \
  --robot.type=koch \
  --control.type=record \
  --control.single_task="Grasp a lego block and put it in the bin." \
  --control.fps=10 \
  --control.repo_id=${HF_USER}/nvidia_trash \
  --control.warmup_time_s=5 \
  --control.episode_time_s=45 \
  --control.reset_time_s=30 \
  --control.num_episodes=30 \
  --control.push_to_hub=true

  optional (if you want to record it doing your policy)
  --control.policy.path="{trained model path}"


2. **Setting up your Robot**
from lerobot.common.robot_devices.motors.configs import DynamixelMotorsBusConfig
from lerobot.common.robot_devices.motors.dynamixel import DynamixelMotorsBus

leader_config = DynamixelMotorsBusConfig(
    port="/dev/ttyACM_kochleader",
    motors={
        "shoulder_pan": (1, "xl330-m077"),
        "shoulder_lift": (2, "xl330-m077"),
        "elbow_flex": (3, "xl330-m077"),
        "wrist_flex": (4, "xl330-m077"),
        "wrist_roll": (5, "xl330-m077"),
        "gripper": (6, "xl330-m077"),
    },
)

follower_config = DynamixelMotorsBusConfig(
    port="/dev/ttyACM_kochfollower",
    motors={
        "shoulder_pan": (1, "xl430-w250"),
        "shoulder_lift": (2, "xl430-w250"),
        "elbow_flex": (3, "xl330-m288"),
        "wrist_flex": (4, "xl330-m288"),
        "wrist_roll": (5, "xl330-m288"),
        "gripper": (6, "xl330-m288"),
    },
)

leader_arm = DynamixelMotorsBus(leader_config)
follower_arm = DynamixelMotorsBus(follower_config)

from lerobot.common.robot_devices.cameras.configs import OpenCVCameraConfig
from lerobot.common.robot_devices.cameras.opencv import OpenCVCamera
from lerobot.common.robot_devices.robots.configs import KochRobotConfig
from lerobot.common.robot_devices.robots.manipulator import ManipulatorRobot

config_cam_1 = OpenCVCameraConfig(
    camera_index="/dev/video0",
    fps=10,
    width=1280,
    height=720,
    color_mode='rgb'
)
config_cam_2 = OpenCVCameraConfig(
    camera_index="/dev/video2",
    fps=10,
    width=1280,
    height=720,
    color_mode='rgb'
)

robot = ManipulatorRobot(
    KochRobotConfig(
        leader_arms={"main": leader_config},
        follower_arms={"main": follower_config},
        calibration_dir=".cache/calibration/koch",
        cameras={
            "logitech1": config_cam_1,
            "logitech2": config_cam_2,
        },
    )
)
robot.connect()

2. **Training a Model**

python lerobot/scripts/train.py \
  --dataset.repo_id=abbyoneill/koch_test \
  --policy.type=act \
  --output_dir=outputs/train/act_koch_test \
  --job_name=act_koch_test \
  --device=cuda \
  --wandb.enable=false \
  --steps=100

2. **Inference**

from lerobot.common.policies.act.modeling_act import ACTPolicy

inference_time_s = 120
fps = 10
device = "cuda"  # TODO: On Mac, use "mps" or "cpu"


ckpt_path =  "/opt/pretrained_model" #edit with correct path here
policy = ACTPolicy.from_pretrained(ckpt_path)
policy.to(device)

import torch
import time
from lerobot.scripts.control_robot import busy_wait


for _ in range(inference_time_s * fps):
    start_time = time.perf_counter()

    # Read the follower state and access the frames from the cameras
    observation = robot.capture_observation()

    # Convert to pytorch format: channel first and float32 in [0,1]
    # with batch dimension
    for name in observation:
        if "image" in name:
            observation[name] = observation[name].type(torch.float32) / 255
            observation[name] = observation[name].permute(2, 0, 1).contiguous()
        observation[name] = observation[name].unsqueeze(0)
        observation[name] = observation[name].to(device)

    # Compute the next action with the policy
    # based on the current observation
    action = policy.select_action(observation)
    # Remove batch dimension
    action = action.squeeze(0)
    # Move to cpu, if not already the case
    action = action.to("cpu")
    # Order the robot to move
    robot.send_action(action)

    dt_s = time.perf_counter() - start_time
    busy_wait(1 / fps - dt_s)
