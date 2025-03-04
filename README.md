#First only connect the leader arm to Jetson and record the serial ID by running the following:
ll /dev/serial/by-id/

Then edit the first line of ./99-usb-serial.rules like the following.
SUBSYSTEM=="tty", ATTRS{idVendor}=="2f5d", ATTRS{idProduct}=="2202", ATTRS{serial}=="BA98C8C350304A46462E3120FF121B06", SYMLINK+="ttyACM_kochleader"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2f5d", ATTRS{idProduct}=="2202", ATTRS{serial}=="00000000000000000000000000000000", SYMLINK+="ttyACM_kochfollower"

sudo cp ./99-usb-serial.rules /etc/udev/rules.d/
sudo reboot


chmod +x clone_lerobot.sh
chmod +x overlay.sh

./clone_lerobot.sh
./overlay.sh

docker pull rocm/pytorch:rocm6.3.3_ubuntu22.04_py3.10_pytorch_release_2.4.0

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

#to check for video numbers
ffplay /dev/video0 for example to see the /dev/video0 will stream
#values from video0 and video1 need to be edited in the lerobot/lerobot/common/robot_devices/robots/config.py in the two places that you find the word logitech
#once changed -- they need to be pushed to github, so that the dockerfile clone pulls (without cache) the new config file

#to try callibration
python lerobot/scripts/control_robot.py --robot.type=koch --control.type calibrate



# not needed; but if you wanted to mount files on -v $(pwd)/data/lerobot/:/opt/lerobot/ \