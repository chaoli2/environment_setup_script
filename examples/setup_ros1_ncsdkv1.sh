#! /bin/bash
set -o errexit #set +o errexit echo "Begin Environment Setup"

# Check OS and Kernel Version


# Clean Existing Directories
rm -rf ~/workspace/libraries
rm -rf ~/ros2_ws

# Setup Network Proxy
tail ~/.bashrc | grep "http_proxy=http://child-prc.intel.com:913"
if [ "$?" == "1" ]; then
  echo "export http_proxy=http://child-prc.intel.com:913" >> ~/.bashrc
  echo "export https_proxy=http://child-prc.intel.com:913" >> ~/.bashrc
else
  echo "proxy already set, skip..."
fi

echo "intel" | sudo -S tail /root/.bashrc | grep "http_proxy=http://child-prc.intel.com:913"
if [ "$?" == "1" ]; then
  echo "intel" | sudo -S sh -c 'echo "export http_proxy=http://child-prc.intel.com:913" >> /root/.bashrc'
  echo "intel" | sudo -S sh -c 'echo "export https_proxy=http://child-prc.intel.com:913" >> /root/.bashrc'
else
  echo "proxy already set, skip..."
fi

echo "intel" | sudo -S touch /etc/apt/apt.conf.d/10proxy
echo "intel" | sudo -S sh -c  'echo "Acquire::http::proxy \"http://child-prc.intel.com:913\";" >> /etc/apt/apt.conf.d/10proxy'
echo "intel" | sudo -S cp ./config/sudoers /etc/

mkdir -p ~/.pip
echo "intel" | sudo -S mkdir -p /root/.pip
cp ./config/pip.conf ~/.pip
echo "intel" | sudo -S cp ./config/pip.conf /root/.pip

# Install Prerequisite
echo "intel" | sudo apt-get update
echo "intel" | sudo apt-get install -y cmake git vim tree htop wget python-pip python3-pip rpm

# Install ROS Core
echo "intel" | sudo -S sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
echo "intel" | sudo -S apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116

echo "intel" | sudo -S apt-get update
echo "intel" | sudo -S apt-get install -y ros-kinetic-desktop-full

if [ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
  echo "intel" | sudo -S rosdep init
else
  echo "file already exists, skip..."
fi

rosdep update

until [ $? == 0 ]
do
  rosdep update
done

echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
source ~/.bashrc
echo "intel" | sudo -S apt-get install -y python-rosinstall python-rosinstall-generator python-wstool build-essential

mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/
source /opt/ros/kinetic/setup.bash && catkin_make

# Install NCSDK and NCAPPZOO
mkdir -p ~/workspace/libraries && cd ~/workspace/libraries

cd ~/workspace/libraries
source ~/.bashrc && git clone https://github.com/movidius/ncappzoo.git

source ~/.bashrc && git clone https://github.com/movidius/ncsdk.git
cd ~/workspace/libraries/ncsdk

# Install LibRealSense
echo "intel" | sudo -S apt-get install -y libusb-1.0.0-dev pkg-config libgtk-3-dev libglfw3-dev libudev-dev
cd ~/workspace/libraries
git clone https://github.com/IntelRealSense/librealsense
cd ~/workspace/libraries/librealsense
git checkout v2.9.1
mkdir build && cd build
cmake ..
echo "intel" | sudo -S make uninstall
make clean
make
echo "intel" | sudo -S make install

cd ..
echo "intel" | sudo -S cp config/99-realsense-libusb.rules /etc/udev/rules.d/
echo "intel" | sudo -S udevadm control --reload-rules
udevadm trigger

rm -rf ~/catkin_ws
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src
git clone https://github.com/intel/object_msgs.git
git clone https://github.com/intel/ros_intel_movidius_ncs.git

git clone https://github.com/intel-ros/realsense.git
cd realsense
git checkout 2.0.2

cd ~/catkin_ws
catkin_make

echo "Finish Environment Setup"
