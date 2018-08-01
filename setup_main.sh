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

#Get Config Parameters
CLEAN=`cat modules.conf | grep 'clean'`
CLEAN=${CLEAN##*=}
echo "Set CLEAN to $CLEAN"

NETWORK_PROXY=`cat modules.conf | grep 'network_proxy'`
NETWORK_PROXY=${NETWORK_PROXY##*=}
echo "Set NETWORK_PROXY to $NETWORK_PROXY"

PIP_PROXY=`cat modules.conf | grep 'pip_proxy'`
PIP_PROXY=${PIP_PROXY##*=}
echo "Set PIP_PROXY to $PIP_PROXY"

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
if [ "$CLEAN" == "1" ]; then
  echo "===================Cleaning...===================================="
  rm -rf ~/workspace/libraries
  rm -rf ~/catkin_ws
  rm -rf ~/ros2_ws
fi

echo $ROOT_PASSWD | sudo -S rm -f /var/lib/apt/lists/lock
echo $ROOT_PASSWD | sudo -S rm -f /var/lib/dpkg/lock
echo $ROOT_PASSWD | sudo -S rm -f /var/cache/apt/archives/lock

# Setup Network Proxy
if [ "$NETWORK_PROXY" == "1" ]; then
  echo "===================Setting Network Proxy...======================="

  set +o errexit 
  tail ~/.bashrc | grep "http_proxy=http://child-prc.intel.com:913"
  if [ "$?" == "1" ]; then
    echo "export http_proxy=http://child-prc.intel.com:913" >> ~/.bashrc
    echo "export https_proxy=http://child-prc.intel.com:913" >> ~/.bashrc
  else
    echo "proxy already set, skip..."
  fi

  echo $ROOT_PASSWD | sudo -S tail /root/.bashrc | grep "http_proxy=http://child-prc.intel.com:913"
  if [ "$?" == "1" ]; then
    echo $ROOT_PASSWD | sudo -S sh -c 'echo "export http_proxy=http://child-prc.intel.com:913" >> /root/.bashrc'
    echo $ROOT_PASSWD | sudo -S sh -c 'echo "export https_proxy=http://child-prc.intel.com:913" >> /root/.bashrc'
  else
    echo "proxy already set, skip..."
  fi
  . ~/.bashrc
  set -o errexit 

  echo $ROOT_PASSWD | sudo -S touch /etc/apt/apt.conf.d/10proxy
  echo $ROOT_PASSWD | sudo -S sh -c  'echo "Acquire::http::proxy \"http://child-prc.intel.com:913\";" > /etc/apt/apt.conf.d/10proxy'
  echo $ROOT_PASSWD | sudo -S cp ./config/sudoers /etc/
fi

if [ "$PIP_PROXY" == "1" ]; then
  echo "===================Setting PIP Proxy...======================="
  mkdir -p ~/.pip
  echo $ROOT_PASSWD | sudo -S mkdir -p /root/.pip
  cp ./config/pip.conf ~/.pip
  echo $ROOT_PASSWD | sudo -S cp ./config/pip.conf /root/.pip
  echo "Network proxy setup done"
fi

# Setup Prerequisite
if [ "$PREREQUISITE" == "1" ]; then
  echo "===================Installing Prerequisite...======================="
  echo $ROOT_PASSWD | sudo -S apt-get update
  echo $ROOT_PASSWD | sudo -S apt-get install -y cmake git vim tree htop wget python-pip python3-pip rpm
  echo "Prerequisite Setup Done"
fi

# Setup ROS from Debian
if [ "$ROS_DEBIAN" == "1" ]; then
  echo "===================Installing ROS from Debian Package...======================="
  echo $ROOT_PASSWD | sudo -S sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  echo $ROOT_PASSWD | sudo -S apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116

  echo $ROOT_PASSWD | sudo -S apt-get update
  echo $ROOT_PASSWD | sudo -S apt-get install -y ros-kinetic-desktop-full

  if [ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
    echo $ROOT_PASSWD | sudo -S rosdep init
  else
    echo "file already exists, skip..."
  fi

  set +o errexit 
  rosdep update
  until [ $? == 0 ]
  do
    rosdep update
  done
  set -o errexit 

  echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
  source ~/.bashrc
  echo $ROOT_PASSWD | sudo -S apt-get install -y python-rosinstall python-rosinstall-generator python-wstool build-essential

  mkdir -p ~/catkin_ws/src
  cd ~/catkin_ws/
  source /opt/ros/kinetic/setup.bash && catkin_make
fi

# Setup ROS from Src
if [ "$ROS_SRC" == "1" ]; then
  echo "===================Installing ROS from Source...======================="
fi

# Setup ROS2 from Debian
if [ "$ROS2_DEBIAN" == "1" ]; then
  echo "===================Installing ROS2 from Debian Package...======================="
fi

# Setup ROS2 from src
if [ "$ROS2_SRC" == "1" ]; then
  echo "===================Installing ROS2 from Source...======================="
  echo $ROOT_PASSWD | sudo -S locale-gen en_US en_US.UTF-8
  echo $ROOT_PASSWD | sudo -S update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
  export LANG=en_US.UTF-8

  #echo $ROOT_PASSWD | sudo -S apt update && sudo apt install -y build-essential git  python3-colcon-common-extensions python3-pip python-rosdep python3-vcstool wget
  #echo $ROOT_PASSWD | sudo -S -H python3 -m pip install -U argcomplete flake8 flake8-blind-except flake8-builtins flake8-class-newline flake8-comprehensions flake8-deprecated flake8-docstrings \
  #  flake8-import-order flake8-quotes pytest-repeat pytest-rerunfailures
  #python3 -m pip install -U pytest pytest-cov pytest-runner setuptools
  #echo $ROOT_PASSWD | sudo -S apt install --no-install-recommends -y libasio-dev libtinyxml2-dev

  echo $ROOT_PASSWD | sudo -S sh -c 'echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros-latest.list'
  echo $ROOT_PASSWD | sudo -S apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116

  echo $ROOT_PASSWD | sudo -S apt-get update
  echo $ROOT_PASSWD | sudo -S apt-get install -y git wget
  echo $ROOT_PASSWD | sudo -S apt-get install -y build-essential cppcheck cmake libopencv-dev python-empy python3-catkin-pkg-modules python3-dev python3-empy python3-nose python3-pip python3-pyparsing python3-setuptools python3-vcstool python3-yaml libtinyxml-dev libeigen3-dev libassimp-dev libpoco-dev
  echo $ROOT_PASSWD | sudo -S apt-get install -y python3-colcon-common-extensions

  # dependencies for testing
  echo $ROOT_PASSWD | sudo -S apt-get install -y clang-format pydocstyle pyflakes python3-coverage python3-mock python3-pep8 uncrustify

  # Install argcomplete for command-line tab completion from the ROS2 tools.
  # Install from pip rather than from apt because of a bug in the Ubuntu 16.04 version of argcomplete:
  echo $ROOT_PASSWD | sudo -S -H python3 -m pip install argcomplete

  # additional testing dependencies from pip (because not available on ubuntu 16.04)
  echo $ROOT_PASSWD | sudo -S -H python3 -m pip install flake8 flake8-blind-except flake8-builtins flake8-class-newline flake8-comprehensions flake8-deprecated flake8-docstrings flake8-import-order flake8-quotes pytest pytest-cov pytest-runner

  # additional pytest plugins unavailable from Debian
  echo $ROOT_PASSWD | sudo -S -H python3 -m pip install pytest-repeat pytest-rerunfailures

  # dependencies for FastRTPS
  echo $ROOT_PASSWD | sudo -S apt-get install -y libasio-dev libtinyxml2-dev

  # dependencies for RViz
  echo $ROOT_PASSWD | sudo -S apt-get install -y libcurl4-openssl-dev libqt5core5a libqt5gui5 libqt5opengl5 libqt5widgets5 libxaw7-dev libgles2-mesa-dev libglu1-mesa-dev qtbase5-dev

  cd /usr/lib/x86_64-linux-gnu
  #if [ ! -f "libboost_python3.so" ]; then
  #  echo "Creating soft link..."
  #  echo $ROOT_PASSWD | sudo -S ln -s libboost_python-py35.so libboost_python3.so
  #else
  #  echo "soft link already exists, skip..."
  #fi
  echo $ROOT_PASSWD | sudo -S rm -f libboost_python3.so
  echo $ROOT_PASSWD | sudo -S ln -s libboost_python-py35.so libboost_python3.so

  mkdir -p ~/ros2_ws/src
  cd ~/ros2_ws
  wget https://raw.githubusercontent.com/ros2/ros2/master/ros2.repos
  vcs-import src < ros2.repos

  colcon build --symlink-install
fi

# Setup OpenCV
if [ "$OPENCV" == "1" ]; then
  echo "===================Installing OpenCV3 from Source...======================="
  echo $ROOT_PASSWD | sudo -S apt-get install -y build-essential
  echo $ROOT_PASSWD | sudo -S apt-get install -y cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev

  mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
  echo "begin clone opencv"
  git clone https://github.com/opencv/opencv.git
  git clone https://github.com/opencv/opencv_contrib.git
  echo "finish clone opencv"

  cd ~/Desktop
  if [ -f "/home/intel/Desktop/ippicv_2017u2_lnx_intel64_20170418.tgz" ]; then
    echo "=======ippicv already existed, checking md5..."
    md5=`md5sum ippicv_2017u2_lnx_intel64_20170418.tgz`
    if [ "$md5" != "87cbdeb627415d8e4bc811156289fa3a  ippicv_2017u2_lnx_intel64_20170418.tgz" ]; then
      echo "=======md5 incorrect, updating...========"
      rm ippicv_2017u2_lnx_intel64_20170418.tgz
      wget https://raw.githubusercontent.com/opencv/opencv_3rdparty/a62e20676a60ee0ad6581e217fe7e4bada3b95db/ippicv/ippicv_2017u2_lnx_intel64_20170418.tgz
    else
      echo "=======md5 correct, continue...=========="
    fi
  else
    echo "==========ippicv file no exist============"
    ls /home/intel/Desktop
    wget https://raw.githubusercontent.com/opencv/opencv_3rdparty/a62e20676a60ee0ad6581e217fe7e4bada3b95db/ippicv/ippicv_2017u2_lnx_intel64_20170418.tgz
  fi

  mkdir ~/workspace/libraries/opencv/.cache/ippicv/ -p
  mv ippicv_2017u2_lnx_intel64_20170418.tgz ~/workspace/libraries/opencv/.cache/ippicv/87cbdeb627415d8e4bc811156289fa3a-ippicv_2017u2_lnx_intel64_20170418.tgz

  cd ~/workspace/libraries/opencv
  git checkout 3.3.0
  cd ~/workspace/libraries/opencv_contrib
  git checkout 3.3.0

  cd ~/workspace/libraries/opencv
  mkdir build && cd build
  cmake -DOPENCV_EXTRA_MODULES_PATH=/home/intel/workspace/libraries/opencv_contrib/modules -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_opencv_cnn_3dobj=OFF ..
  #make -j4
  #echo $ROOT_PASSWD | sudo -S make install
  #echo $ROOT_PASSWD | sudo -S ldconfig
fi

# Setup NCSDK
if [ "$NCSDK" == "1" ]; then
  echo "===================Installing NCSDK...======================="
  mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
  cd ~/workspace/libraries
  . ~/.bashrc && git clone https://github.com/movidius/ncsdk.git
  cd ncsdk
  make install
fi

# Setup NCAPPZOO
if [ "$NCAPPZOO" == "1" ]; then
  echo "===================Installing NCAPPZOO...======================="
  mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
  cd ~/workspace/libraries
  . ~/.bashrc && git clone https://github.com/movidius/ncappzoo.git
fi

# Setup LIBREALSENSE
if [ "$LIBREALSENSE" == "1" ]; then
  echo "===================Setting Up LibRealSense...======================="
  echo $ROOT_PASSWD | sudo -S apt-get install -y libusb-1.0.0-dev pkg-config libgtk-3-dev libglfw3-dev libudev-dev
  mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
  git clone https://github.com/IntelRealSense/librealsense
  cd ~/workspace/libraries/librealsense
  git checkout v2.9.1
  mkdir build && cd build
  cmake ..
  echo $ROOT_PASSWD | sudo -S make uninstall
  make clean
  make
  echo $ROOT_PASSWD | sudo -S make install

  cd ..
  echo $ROOT_PASSWD | sudo -S cp config/99-realsense-libusb.rules /etc/udev/rules.d/
  echo $ROOT_PASSWD | sudo -S udevadm control --reload-rules
  udevadm trigger
fi

# Setup CLCAFFE
if [ "$CLCAFFE" == "1" ]; then
  echo "===================Installing clCaffe...======================="
  # Install OpenCL Driver
  cd /tmp
  wget registrationcenter-download.intel.com/akdlm/irc_nas/11396/SRB4.1_linux64.zip
  unzip -o SRB4.1_linux64.zip
  echo $ROOT_PASSWD | sudo -S rpm -Uivh --nodeps --force --replacepkgs intel-opencl-r4.1-61547.x86_64.rpm
  echo $ROOT_PASSWD | sudo -S rpm -Uivh --nodeps --force --replacepkgs intel-opencl-cpu-r4.1-61547.x86_64.rpm
  echo $ROOT_PASSWD | sudo -S rpm -Uivh --nodeps --force --replacepkgs intel-opencl-devel-r4.1-61547.x86_64.rpm

  echo $ROOT_PASSWD | sudo -S apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev protobuf-compiler
  echo $ROOT_PASSWD | sudo -S apt-get install -y --no-install-recommends libboost-all-dev
  echo $ROOT_PASSWD | sudo -S apt-get install -y libopenblas-dev liblapack-dev libatlas-base-dev
  echo $ROOT_PASSWD | sudo -S apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev
  rm -rf $HOME/code
  mkdir -p $HOME/code
  cd $HOME/code
  git clone https://github.com/viennacl/viennacl-dev.git
  cd viennacl-dev
  mkdir build && cd build
  cmake -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=$HOME/local -DOPENCL_LIBRARY=/opt/intel/opencl/libOpenCL.so ..
  make -j4
  make install
  cd $HOME/code
  git clone https://github.com/intel/isaac
  cd isaac
  mkdir build && cd build
  cmake -DCMAKE_INSTALL_PREFIX=$HOME/local .. && make -j4
  make install

  # Install MKL
  cd /tmp
  wget http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/13005/l_mkl_2018.3.222.tgz
  tar xvf l_mkl_2018.3.222.tgz

  cd l_mkl_2018.3.222
  cp $basedir/config/silent.cfg .
  echo $ROOT_PASSWD | sudo -S ./install.sh --silent silent.cfg
  echo "Intel MKL installed"
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/intel/mkl/lib/intel64_lin/

  cd $HOME/code
  git clone https://github.com/01org/caffe clCaffe
  cd clCaffe
  git checkout inference-optimize
  mkdir build && cd build
  export ISAAC_HOME=$HOME/local
  cmake .. -DUSE_GREENTEA=ON -DUSE_CUDA=OFF -DUSE_INTEL_SPATIAL=ON -DBUILD_docs=0 -DUSE_ISAAC=ON -DViennaCL_INCLUDE_DIR=$HOME/local/include -DBLAS=mkl -DOPENCL_LIBRARIES=/opt/intel/opencl/libOpenCL.so -DOPENCL_INCLUDE_DIRS=/opt/intel/opencl/include
  make -j4
  export CAFFE_ROOT=$HOME/code/clCaffe
  echo $ROOT_PASSWD | sudo -S ln -s /home/intel/code/clCaffe/ /opt/clCaffe
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/clCaffe/build/lib

  # Convert YOLO Model
  cd $HOME/code/clCaffe
  wget https://pjreddie.com/media/files/yolo-voc.weights -O models/yolo/yolo416/yolo.weights
  pip install scikit-image protobuf
  python models/yolo/convert_yolo_to_caffemodel.py
  python tools/inference-optimize/model_fuse.py --indefinition models/yolo/yolo416/yolo_deploy.prototxt --outdefinition models/yolo/yolo416/fused_yolo_deploy.prototxt --inmodel models/yolo/yolo416/yolo.caffemodel --outmodel models/yolo/yolo416/fused_yolo.caffemodel

  # Compile
  cd ~/catkin_ws/src
  git clone https://github.com/intel/object_msgs
  git clone https://github.com/intel/ros_opencl_caffe
  cd ~/catkin_ws/
  catkin_make
fi

#rm -rf ~/catkin_ws
#mkdir -p ~/catkin_ws/src
#cd ~/catkin_ws/src
#git clone https://github.com/intel/object_msgs.git
#git clone https://github.com/intel/ros_intel_movidius_ncs.git

#git clone https://github.com/intel-ros/realsense.git
#cd realsense
#git checkout 2.0.2

#cd ~/catkin_ws
#catkin_make

echo "Environment Setup Done"

