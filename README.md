# LeRobot Setup and Docker Run Instructions

Follow these steps to set up your system, clone and overlay LeRobot, and run the Docker container.

## 1. Set Up Udev Rules for USB Serial Devices

First, only connect the leader arm to the Jetson and record the serial ID by running:

ll /dev/serial/by-id/


Then, edit the first line of `./99-usb-serial.rules` as follows:

SUBSYSTEM=="tty", ATTRS{idVendor}=="2f5d", ATTRS{idProduct}=="2202", ATTRS{serial}=="BA98C8C350304A46462E3120FF121B06", SYMLINK+="ttyACM_kochleader" SUBSYSTEM=="tty", ATTRS{idVendor}=="2f5d", ATTRS{idProduct}=="2202", ATTRS{serial}=="00000000000000000000000000000000", SYMLINK+="ttyACM_kochfollower"

Copy the udev rules file and reboot:
sudo cp ./99-usb-serial.rules /etc/udev/rules.d/ sudo reboot


chmod +x clone_lerobot.sh
chmod +x overlay.sh

./clone_lerobot.sh
./overlay.sh

#Pull the docker file base
docker pull rocm/pytorch:rocm6.3.3_ubuntu22.04_py3.10_pytorch_release_2.4.0

#Allow local connections to the X server:
xhost +local

#build
docker build -t ryzerdocker .

#run
sudo docker run -it --rm --shm-size=16G \
  --privileged \
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
  ryzerdocker

## 6. Testing and Calibration

### Check Video Device Streaming

To check video streaming, run:

ffplay /dev/video0

### Update Video Device Configuration

Edit the file `lerobot/lerobot/common/robot_devices/robots/config.py` and update the two instances where the word `logitech` appears to reflect your actual device values for `/dev/video0` and `/dev/video1`.

> **Note:** After updating the config, push the changes to GitHub so the Dockerfile will clone the new config file (disable cache if necessary).

### Run Calibration

To test calibration, run:

python lerobot/scripts/control_robot.py --robot.type=koch --control.type calibrate

If you need to mount files from your host, you can use the following volume mapping:

-v $(pwd)/data/lerobot/:/opt/lerobot/


#callibration leader
{"homing_offset": [0, 3072, -1024, 3072, -3072, -2048], "drive_mode": [0, 1, 0, 1, 0, 0], "start_pos": [1036, 2952, 1122, 3241, 2935, 2022], "end_pos": [1083, -2058, 2057, -2148, 4188, 2688], "calib_mode": ["DEGREE", "DEGREE", "DEGREE", "DEGREE", "DEGREE", "DEGREE"], "motor_names": ["shoulder_pan", "shoulder_lift", "elbow_flex", "wrist_flex", "wrist_roll", "gripper"]}

#callibration follower
{"homing_offset": [3072, 2048, -1024, 3072, -3072, -2048], "drive_mode": [1, 1, 0, 1, 0, 0], "start_pos": [2019, 1985, 1032, 3125, 3041, 1990], "end_pos": [-2013, -1052, 2057, -2050, 4059, 2958], "calib_mode": ["DEGREE", "DEGREE", "DEGREE", "DEGREE", "DEGREE", "DEGREE"], "motor_names": ["shoulder_pan", "shoulder_lift", "elbow_flex", "wrist_flex", "wrist_roll", "gripper"]}
