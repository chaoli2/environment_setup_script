#! /bin/bash
set -o errexit
#set +o errexit
echo "Begin Environment Setup"

# Check OS and Kernel Version


# Clean Existing Directories
rm -rf ~/workspace/libraries
rm -rf ~/ros2_ws

# Setup Network Proxy
echo "export http_proxy=http://child-prc.intel.com:913" >> ~/.bashrc
echo "export https_proxy=http://child-prc.intel.com:913" >> ~/.bashrc
echo "intel" | sudo -S sh -c 'echo "export http_proxy=http://child-prc.intel.com:913" >> /root/.bashrc'
echo "intel" | sudo -S sh -c 'echo "export https_proxy=http://child-prc.intel.com:913" >> /root/.bashrc'
source ~/.bashrc

echo "intel" | sudo -S touch /etc/apt/apt.conf.d/10proxy
echo "intel" | sudo -S sh -c  'echo "Acquire::http::proxy \"http://child-prc.intel.com:913\";" >> /etc/apt/apt.conf.d/10proxy'
echo "intel" | sudo -S cp ./config/sudoers /etc/

mkdir -p ~/.pip
echo "intel" | sudo -S mkdir -p /root/.pip
cp ./config/pip.conf ~/.pip
echo "intel" | sudo -S cp ./config/pip.conf /root/.pip

# Install Prerequisite
echo "intel" | sudo apt-get update
echo "intel" | sudo apt-get install -y cmake git vim tree htop wget python-pip python3-pip

# Configure Git Environment
git config --global user.name "Chao Li"
git config --global user.email "chao1.li@intel.com"

# Install NCSDK and NCAPPZOO
mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
source ~/.bashrc && git clone https://github.com/movidius/ncsdk.git
cd ~/workspace/libraries/ncsdk
set +o errexit

echo "intel" | sudo -S make install

set -o errexit
cd ~/workspace/libraries
source ~/.bashrc && git clone https://github.com/movidius/ncappzoo.git

# Install OpenCV
echo "intel" | sudo -S apt-get install -y build-essential
echo "intel" | sudo -S apt-get install -y cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev

cd ~/workspace/libraries
echo "begin clone opencv"
git clone https://github.com/opencv/opencv.git
git clone https://github.com/opencv/opencv_contrib.git
echo "finish clone opencv"

cd ~/Desktop
wget https://raw.githubusercontent.com/opencv/opencv_3rdparty/a62e20676a60ee0ad6581e217fe7e4bada3b95db/ippicv/ippicv_2017u2_lnx_intel64_20170418.tgz
mkdir ~/workspace/libraries/opencv/.cache/ippicv/ -p
mv ippicv_2017u2_lnx_intel64_20170418.tgz ~/workspace/libraries/opencv/.cache/ippicv/87cbdeb627415d8e4bc811156289fa3a-ippicv_2017u2_lnx_intel64_20170418.tgz

cd ~/workspace/libraries/opencv
git checkout 3.3.0
cd ~/workspace/libraries/opencv_contrib
git checkout 3.3.0

cd ~/workspace/libraries/opencv
mkdir build && cd build
cmake -DOPENCV_EXTRA_MODULES_PATH=/home/intel/workspace/libraries/opencv_contrib/modules -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_opencv_cnn_3dobj=OFF ..
make -j4
echo "intel" | sudo -S make install
echo "intel" | sudo -S ldconfig

# Install ROS2 Core
echo "intel" | sudo -S locale-gen en_US en_US.UTF-8
echo "intel" | sudo -S update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

echo "intel" | sudo -S sh -c 'echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros-latest.list'
echo "intel" | sudo -S apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116

echo "intel" | sudo -S apt-get update
echo "intel" | sudo -S apt-get install -y git wget
echo "intel" | sudo -S apt-get install -y build-essential cppcheck cmake libopencv-dev python-empy python3-catkin-pkg-modules python3-dev python3-empy python3-nose python3-pip python3-pyparsing python3-setuptools python3-vcstool python3-yaml libtinyxml-dev libeigen3-dev libassimp-dev libpoco-dev
echo "intel" | sudo -S apt-get install -y python3-colcon-common-extensions

# dependencies for testing
echo "intel" | sudo -S apt-get install -y clang-format pydocstyle pyflakes python3-coverage python3-mock python3-pep8 uncrustify

# Install argcomplete for command-line tab completion from the ROS2 tools.
# Install from pip rather than from apt because of a bug in the Ubuntu 16.04 version of argcomplete:
echo "intel" | sudo -S -H python3 -m pip install argcomplete

# additional testing dependencies from pip (because not available on ubuntu 16.04)
echo "intel" | sudo -S -H python3 -m pip install flake8 flake8-blind-except flake8-builtins flake8-class-newline flake8-comprehensions flake8-deprecated flake8-docstrings flake8-import-order flake8-quotes pytest pytest-cov pytest-runner

# additional pytest plugins unavailable from Debian
echo "intel" | sudo -S -H python3 -m pip install pytest-repeat pytest-rerunfailures

# dependencies for FastRTPS
echo "intel" | sudo -S apt-get install -y libasio-dev libtinyxml2-dev
 
# dependencies for RViz
echo "intel" | sudo -S apt-get install -y libcurl4-openssl-dev libqt5core5a libqt5gui5 libqt5opengl5 libqt5widgets5 libxaw7-dev libgles2-mesa-dev libglu1-mesa-dev qtbase5-dev


cd /usr/lib/x86_64-linux-gnu

if [ ! -f "libboost_python3.so" ]; then
  echo "intel" | sudo -S ln -s libboost_python-py35.so libboost_python3.so
else
  echo "soft link already exists, skip..."
fi

mkdir -p ~/ros2_ws/src
cd ~/ros2_ws
wget https://raw.githubusercontent.com/ros2/ros2/master/ros2.repos
vcs-import src < ros2.repos

# Install RealSense Dependencies
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

cd ~/ros2_ws/src
git clone https://github.com/ros-perception/vision_opencv.git
cd ~/ros2_ws/src/vision_opencv
git checkout ros2
cd ~/ros2_ws/src
git clone https://github.com/intel/ros2_intel_realsense

# Install ros2 ncs projects
cd ~/ros2_ws/src
git clone https://github.com/intel/ros2_intel_movidius_ncs
git clone https://github.com/intel/ros2_object_msgs

cd ~/ros2_ws/
colcon build --symlink-install

echo "Finish Environment Setup"
