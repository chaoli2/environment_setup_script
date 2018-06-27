#! /bin/bash
set -o errexit #set +o errexit echo "Begin Environment Setup"

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

cd /tmp
wget registrationcenter-download.intel.com/akdlm/irc_nas/11396/SRB4.1_linux64.zip
unzip -o SRB4.1_linux64.zip
echo "intel" | sudo -S rpm -Uivh --nodeps --force --replacepkgs intel-opencl-r4.1-61547.x86_64.rpm
echo "intel" | sudo -S rpm -Uivh --nodeps --force --replacepkgs intel-opencl-cpu-r4.1-61547.x86_64.rpm
echo "intel" | sudo -S rpm -Uivh --nodeps --force --replacepkgs intel-opencl-devel-r4.1-61547.x86_64.rpm

echo "Finish Environment Setup"
