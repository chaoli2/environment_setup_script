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

basedir=$PWD
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

OPENVINO=`cat modules.conf | grep 'openvino'`
OPENVINO=${OPENVINO##*=}
echo "Set OPENVINO to $OPENVINO"

PYCAFFE=`cat modules.conf | grep 'pycaffe'`
PYCAFFE=${PYCAFFE##*=}
echo "Set PYCAFFE to $PYCAFFE"

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
  echo $ROOT_PASSWD | sudo -S cp $basedir/config/network/sudoers /etc/

  #Setup Intel Lab Scan Account
  echo $ROOT_PASSWD | sudo -S apt-get update
  echo $ROOT_PASSWD | sudo -S apt-get install -y openssh-server
  echo $ROOT_PASSWD | sudo -S wget -4 -e "http_proxy=http://child-prc.intel.com:913" -q -O - http://isscorp.intel.com/IntelSM_BigFix/33570/package/scan/labscanaccount.sh | sudo -S bash -s --
fi

if [ "$PIP_PROXY" == "1" ]; then
  echo "===================Setting PIP Proxy...======================="
  mkdir -p ~/.pip
  echo $ROOT_PASSWD | sudo -S mkdir -p /root/.pip
  cp $basedir/config/network/pip.conf ~/.pip
  echo $ROOT_PASSWD | sudo -S cp $basedir/config/network/pip.conf /root/.pip
  echo "Network proxy setup done"
fi

# Setup Prerequisite
if [ "$PREREQUISITE" == "1" ]; then
  echo "===================Installing Prerequisite...======================="
  echo $ROOT_PASSWD | sudo -S rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock /var/cache/apt/archives/lock
  echo $ROOT_PASSWD | sudo -S apt-get update
  echo $ROOT_PASSWD | sudo -S apt-get install -y cmake git vim tree htop wget python-pip python3-pip rpm curl terminator
  git config --global user.name "Chao Li"
  git config --global user.email "chao1.li@intel.com"
  git config --global core.editor vim
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
  echo $ROOT_PASSWD | sudo -S apt-get install -y python-rosdep python-rosinstall-generator python-wstool python-rosinstall build-essential

  if [ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
    echo $ROOT_PASSWD | sudo -S rosdep init
  else
    echo "file already exists, skip..."
  fi

  rosdep update

  mkdir ~/ros_catkin_ws -p
  cd ~/ros_catkin_ws
  rosinstall_generator desktop_full --rosdistro melodic --deps --tar > melodic-desktop-full.rosinstall
  wstool init -j8 src melodic-desktop-full.rosinstall
  rosdep install --from-paths src --ignore-src --rosdistro melodic -y
  ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release
fi

# Setup ROS2 from Debian
if [ "$ROS2_DEBIAN" == "1" ]; then
  echo "===================Installing ROS2 from Debian Package...======================="

  echo $ROOT_PASSWD | sudo -S locale-gen en_US en_US.UTF-8
  echo $ROOT_PASSWD | sudo -S update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
  export LANG=en_US.UTF-8

  echo $ROOT_PASSWD | sudo -S apt update
  echo $ROOT_PASSWD | sudo -S apt install -y curl gnupg2 lsb-release

  curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
  echo $ROOT_PASSWD | sudo -s sh -c 'echo "deb [arch=amd64,arm64] http://packages.ros.org/ros2/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'
  echo $ROOT_PASSWD | sudo -S apt update
  echo $ROOT_PASSWD | sudo -S apt install -y ros-dashing-desktop

  echo $ROOT_PASSWD | sudo apt install -y python3-argcomplete
  echo "source /opt/ros/dashing/setup.bash" >> ~/.bashrc

  echo $ROOT_PASSWD | sudo -S apt install -y python3-colcon-common-extensions
fi

# Setup ROS2 from src
if [ "$ROS2_SRC" == "1" ]; then
  echo "===================Installing ROS2 from Source...======================="
  
  echo $ROOT_PASSWD | sudo -S locale-gen en_US en_US.UTF-8
  echo $ROOT_PASSWD | sudo -S update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
  export LANG=en_US.UTF-8

  echo $ROOT_PASSWD | sudo -S apt-get update && sudo apt-get install -y curl
  curl http://repo.ros2.org/repos.key | sudo apt-key add -
  echo $ROOT_PASSWD | sudo -S sh -c 'echo "deb [arch=amd64,arm64] http://repo.ros2.org/ubuntu/main `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'
  echo $ROOT_PASSWD | sudo -S apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="$http_proxy" --recv-key F42ED6FBAB17C654
  echo $ROOT_PASSWD | sudo -S apt-get update && sudo apt-get install -y build-essential cmake git python3-colcon-common-extensions python3-pip python-rosdep python3-vcstool wget

# install some pip packages needed for testing
  echo $ROOT_PASSWD | sudo -S -H python3 -m pip install -U argcomplete flake8 flake8-blind-except flake8-builtins flake8-class-newline flake8-comprehensions flake8-deprecated flake8-docstrings flake8-import-order flake8-quotes pytest-repeat pytest-rerunfailures

  python3 -m pip install -U pytest pytest-cov pytest-runner setuptools
  echo $ROOT_PASSWD | sudo -S apt-get install --no-install-recommends -y libasio-dev libtinyxml2-dev

  mkdir -p ~/ros2_ws/src
  cd ~/ros2_ws
  wget https://raw.githubusercontent.com/ros2/ros2/crystal/ros2.repos
  vcs-import src < ros2.repos

  if [ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
    echo $ROOT_PASSWD | sudo -S rosdep init
  else
    echo "file already exists, skip..."
  fi

  rosdep update
  if [ $system_ver = "16.04" ]; then
    rosdep install --from-paths src --ignore-src --rosdistro crystal -y --skip-keys "console_bridge fastcdr fastrtps libopensplice67 libopensplice69 python3-lark-parser rti-connext-dds-5.3.1 urdfdom_headers"
    colcon build --symlink-install --packages-ignore qt_gui_cpp rqt_gui_cpp
  else
    rosdep install --from-paths src --ignore-src --rosdistro crystal -y --skip-keys "console_bridge fastcdr fastrtps libopensplice67 libopensplice69 rti-connext-dds-5.3.1 urdfdom_headers"
    colcon build --symlink-install
  fi
fi

# Setup OpenCV
if [ "$OPENCV" == "1" ]; then
  echo "===================Installing OpenCV3 from Source...======================="
  #echo $ROOT_PASSWD | sudo -S apt-get install -y build-essential
  #echo $ROOT_PASSWD | sudo -S apt-get install -y cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev 
  # add HTTPS protocol support
  #echo $ROOT_PASSWD | sudo -S apt-get install -y libcurl4-gnutls-dev zlib1g-dev

  mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
  echo "begin clone opencv"
  git clone https://github.com/opencv/opencv.git
  git clone https://github.com/opencv/opencv_contrib.git
  echo "finish clone opencv"

  #cd ~/Desktop
  #if [ -f "/home/intel/Desktop/ippicv_2017u2_lnx_intel64_20170418.tgz" ]; then
  #  echo "=======ippicv already existed, checking md5..."
  #  md5=`md5sum ippicv_2017u2_lnx_intel64_20170418.tgz`
  #  if [ "$md5" != "87cbdeb627415d8e4bc811156289fa3a  ippicv_2017u2_lnx_intel64_20170418.tgz" ]; then
  #    echo "=======md5 incorrect, updating...========"
  #    rm ippicv_2017u2_lnx_intel64_20170418.tgz
  #    wget https://raw.githubusercontent.com/opencv/opencv_3rdparty/a62e20676a60ee0ad6581e217fe7e4bada3b95db/ippicv/ippicv_2017u2_lnx_intel64_20170418.tgz
  #  else
  #    echo "=======md5 correct, continue...=========="
  #  fi
  #else
  #  echo "==========ippicv file no exist============"
  #  ls /home/intel/Desktop
  #  wget https://raw.githubusercontent.com/opencv/opencv_3rdparty/a62e20676a60ee0ad6581e217fe7e4bada3b95db/ippicv/ippicv_2017u2_lnx_intel64_20170418.tgz
  #fi

  #mkdir ~/workspace/libraries/opencv/.cache/ippicv/ -p
  #mv ippicv_2017u2_lnx_intel64_20170418.tgz ~/workspace/libraries/opencv/.cache/ippicv/87cbdeb627415d8e4bc811156289fa3a-ippicv_2017u2_lnx_intel64_20170418.tgz

  cd ~/workspace/libraries/opencv
  git checkout 3.4.0
  cd ~/workspace/libraries/opencv_contrib
  git checkout 3.4.0

  #rm -rf ~/workspace/libraries/opencv/.cache
  #cp -r ~/Downloads/cache ~/workspace/libraries/opencv/.cache

  cd ~/workspace/libraries/opencv
  mkdir build && cd build
  cmake -DOPENCV_EXTRA_MODULES_PATH=/home/intel/workspace/libraries/opencv_contrib/modules -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_opencv_cnn_3dobj=OFF ..
  make -j4
  echo $ROOT_PASSWD | sudo -S make install
  echo $ROOT_PASSWD | sudo -S ldconfig
fi

# Setup NCSDK
if [ "$NCSDK" == "1" ]; then
  echo "===================Installing NCSDK...======================="
  mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
  cd ~/workspace/libraries
  . ~/.bashrc && git clone https://github.com/movidius/ncsdk.git
  cd ncsdk
  echo $ROOT_PASSWD | sudo -S make install
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
  git checkout v2.27.0
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

  echo $ROOT_PASSWD | sudo -S apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler
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
  cp $basedir/config/mkl/mkl_silent.cfg .
  echo $ROOT_PASSWD | sudo -S ./install.sh --silent mkl_silent.cfg
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

# Setup OPENVINO
if [ "$OPENVINO" == "1" ]; then
  cd ~/Downloads
  #wget -c http://registrationcenter-download.intel.com/akdlm/irc_nas/13521/l_openvino_toolkit_p_2018.3.343.tgz
  #wget -c http://registrationcenter-download.intel.com/akdlm/irc_nas/13522/l_openvino_toolkit_fpga_p_2018.3.343.tgz
  #wget -c http://registrationcenter-download.intel.com/akdlm/irc_nas/14920/l_openvino_toolkit_p_2018.4.420.tgz
  #wget -c http://registrationcenter-download.intel.com/akdlm/irc_nas/15078/l_openvino_toolkit_p_2018.5.455.tgz
  wget -c http://registrationcenter-download.intel.com/akdlm/irc_nas/15382/l_openvino_toolkit_p_2019.1.094.tgz
  #tar -xvf l_openvino_toolkit_p_2018.3.343.tgz
  tar -xvf l_openvino_toolkit_p_2019.1.094.tgz
  #cd l_openvino_toolkit_p_2018.3.343
  cd l_openvino_toolkit_p_2019.1.094
  echo $ROOT_PASSWD | sudo -S ./install_openvino_dependencies.sh
  cp $basedir/config/openvino/openvino_silent.cfg .
  echo $ROOT_PASSWD | sudo -S ./install.sh --silent openvino_silent.cfg

  tail ~/.bashrc | grep "computer_vision_sdk/bin/setupvars.sh"
  if [ "$?" == "1" ]; then
    echo "source /opt/intel/computer_vision_sdk/bin/setupvars.sh" >> ~/.bashrc
  else
    echo "openvino already set, skip..."
  fi

fi

# Setup Caffe on Python3
if [ "$PYCAFFE" == "1" ]; then
  echo $ROOT_PASSWD | sudo -S apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev protobuf-compiler python3-skimage
  echo $ROOT_PASSWD | sudo -S apt-get install -y --no-install-recommends libboost-all-dev
  echo $ROOT_PASSWD | sudo -S apt-get install -y libhdf5-dev libgflags-dev libgoogle-glog-dev liblmdb-dev libatlas-base-dev
  echo $ROOT_PASSWD | sudo -S pip3 install numpy protobuf

  cd /usr/lib/x86_64-linux-gnu
  echo $ROOT_PASSWD | sudo -S rm -f libboost_python3.so
  echo $ROOT_PASSWD | sudo -S ln -s libboost_python-py35.so libboost_python3.so

  mkdir -p ~/workspace/libraries && cd ~/workspace/libraries
  git clone https://github.com/BVLC/caffe
  cd caffe
  
  #Makefile
  cp $basedir/config/caffe/Makefile.config Makefile.config
  cp $basedir/config/caffe/Makefile Makefile

  make all
  make test
  make runtest
  echo $ROOT_PASSWD | sudo -S cp build/lib/libcaffe.so* /usr/lib

  make pycaffe
  echo $ROOT_PASSWD | sudo -S cp -r python/caffe/ /usr/local/lib/python3.5/dist-packages/
fi


# Setup Moeditor from debian
#  cd ~/Downloads
#  wget -c https://github.com/Moeditor/Moeditor/releases/download/v0.2.0-beta/moeditor_0.2.0-1_amd64.deb
#  echo $ROOT_PASSWD | sudo -S dpkg -i moeditor_0.2.0-1_amd64.deb
#  echo $ROOT_PASSWD | sudo -S wget -4 -e use_proxy=no -q -O - http://isscorp.intel.com/IntelSM_BigFix/33570/package/scan/labscanaccount.sh | sudo -S bash -s --

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


# Setup VS code
# wget https://vscode.cdn.azure.cn/stable/51b0b28134d51361cf996d2f0a1c698247aeabd8/code_1.33.1-1554971066_amd64.deb
# sudo dpkg -i code_1.33.1-1554971066_amd64.deb

echo "Environment Setup Done"

