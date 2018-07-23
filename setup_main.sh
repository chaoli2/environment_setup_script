#!/bin/bash

set -o errexit 
#set +o errexit 

if [ ! -n "$1" ] ;then
  echo "you have to input your sudo password!"
  exit
else
  ROOT_PASSWD=$1
  echo "Set sudo password to $ROOT_PASSWD"
fi

echo "Begin Environment Setup"

NETWORK_PROXY=`cat modules.conf | grep 'network_proxy'`
NETWORK_PROXY=${NETWORK_PROXY##*=}
echo "Set NETWORK_PROXY to $NETWORK_PROXY"

PREREQUISITE=`cat modules.conf | grep 'prerequisite'`
PREREQUISITE=${PREREQUISITE##*=}
echo "Set PREREQUISITE to $PREREQUISITE"

ROS_SRC=`cat modules.conf | grep 'ros_src'`
ROS_SRC=${ROS_SRC##*=}
echo "Set ROS_SRC to $ROS_SRC"

ROS_DEBIAN=`cat modules.conf | grep 'ros_debian'`
ROS_DEBIAN=${ROS_DEBIAN##*=}
echo "Set ROS_DEBIAN to $ROS_DEBIAN"

ROS2_SRC=`cat modules.conf | grep 'ros2_src'`
ROS2_SRC=${ROS2_SRC##*=}
echo "Set ROS2_SRC to $ROS2_SRC"

ROS2_DEBIAN=`cat modules.conf | grep 'ros2_debian'`
ROS2_DEBIAN=${ROS2_DEBIAN##*=}
echo "Set ROS2_DEBIAN to $ROS2_DEBIAN"

OPENCV=`cat modules.conf | grep 'opencv'`
OPENCV=${OPENCV##*=}
echo "Set OPENCV to $OPENCV"

NCSDK=`cat modules.conf | grep 'ncsdk'`
NCSDK=${NCSDK##*=}
echo "Set NCSDK to $NCSDK"

NCAPPZOO=`cat modules.conf | grep 'ncappzoo'`
NCAPPZOO=${NCAPPZOO##*=}
echo "Set NCAPPZOO to $NCAPPZOO"

LIBREALSENSE=`cat modules.conf | grep 'librealsense'`
LIBREALSENSE=${LIBREALSENSE##*=}
echo "Set LIBREALSENSE to $LIBREALSENSE"

CLCAFFE=`cat modules.conf | grep 'clcaffe'`
CLCAFFE=${CLCAFFE##*=}
echo "Set CLCAFFE to $CLCAFFE"

# Clean Existing Directories
rm -rf ~/workspace/libraries
rm -rf ~/catkin_ws
rm -rf ~/ros2_ws

# Setup Network Proxy
if [ "$NETWORK_PROXY" == "1" ]; then
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
  echo "Network proxy setup done"
fi

# Setup Prerequisite
if [ "$PREREQUISITE" == "1" ]; then
  echo "intel" | sudo -S apt-get update
  echo "intel" | sudo -S apt-get install -y cmake git vim tree htop wget python-pip python3-pip rpm
  echo "Prerequisite Setup Done"
fi

# Setup ROS from Debian
if [ "$ROS_DEBIAN" == "1" ]; then
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
fi

# Setup ROS from Src
if [ "$ROS_SRC" == "1" ]; then
  echo "ROS_SRC"
fi

# Setup ROS2 from Debian
if [ "$ROS2_DEBIAN" == "1" ]; then
  echo "ROS_SRC"
fi

# Setup ROS2 from src
if [ "$ROS2_SRC" == "1" ]; then
  echo "ROS_SRC"
fi

# Setup NCSDK
if [ "$NCSDK" == "1" ]; then
  mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
  cd ~/workspace/libraries
  . ~/.bashrc && git clone https://github.com/movidius/ncsdk.git
  cd ncsdk
  make install
fi

# Setup NCAPPZOO
if [ "$NCAPPZOO" == "1" ]; then
  mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
  cd ~/workspace/libraries
  . ~/.bashrc && git clone https://github.com/movidius/ncappzoo.git
fi

# Setup LIBREALSENSE
if [ "$LIBREALSENSE" == "1" ]; then
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
fi

# Setup CLCAFFE
if [ "$CLCAFFE" == "1" ]; then

fi

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

echo "Environment Setup Done"

