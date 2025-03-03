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

#build
docker build -t ryzerdocker .

#run
docker run -it --rm --shm-size=16G \
  --cap-add=SYS_PTRACE \
  --network=host \
  --ipc=host \
  -e HSA_OVERRIDE_GFX_VERSION=11.0.0 \
  --device=/dev/kfd \
  --device=/dev/dri \
  --device=/dev/ttyACM_kochleader:/dev/ttyACM_kochleader \
  --device=/dev/ttyACM_kochfollower:/dev/ttyACM_kochfollower \
  --device=/dev/videoC270_front:/dev/video0 \
  --device=/dev/videoC270_top:/dev/video1 \
  --security-opt seccomp=unconfined \
  --group-add video \
  --group-add render \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $(pwd)/data/lerobot/:/opt/lerobot/ \
  ryzerdocker

