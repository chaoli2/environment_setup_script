#! /bin/bash
set -o errexit #set +o errexit echo "Begin Environment Setup"

# Check OS and Kernel Version

basedir=$(cd `dirname $0`; pwd)
# Clean Existing Directories
rm -rf ~/workspace/libraries
rm -rf ~/catkin_ws

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

# Install OpenCL Driver
cd /tmp
wget registrationcenter-download.intel.com/akdlm/irc_nas/11396/SRB4.1_linux64.zip
unzip -o SRB4.1_linux64.zip
echo "intel" | sudo -S rpm -Uivh --nodeps --force --replacepkgs intel-opencl-r4.1-61547.x86_64.rpm
echo "intel" | sudo -S rpm -Uivh --nodeps --force --replacepkgs intel-opencl-cpu-r4.1-61547.x86_64.rpm
echo "intel" | sudo -S rpm -Uivh --nodeps --force --replacepkgs intel-opencl-devel-r4.1-61547.x86_64.rpm

echo "intel" | sudo -S apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev protobuf-compiler
echo "intel" | sudo -S apt-get install -y --no-install-recommends libboost-all-dev
echo "intel" | sudo -S apt-get install -y libopenblas-dev liblapack-dev libatlas-base-dev
echo "intel" | sudo -S apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev
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
echo "intel" | sudo -S ./install.sh --silent silent.cfg
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
echo "intel" | sudo -S ln -s /home/intel/code/clCaffe/ /opt/clCaffe
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

echo "Finish Environment Setup"
