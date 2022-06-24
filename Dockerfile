# FROM kun777/barn-ros-melodic-setup
# run gzserver and gzweb
FROM gazebo:libgazebo9-bionic

# WORKDIR /
# add ROS sources
# RUN apt update && apt install -y openssh-server x11-apps mesa-utils vim llvm-dev sudo autoconf
# RUN apt-get install -y libtool libtool-bin build-essential
# RUN mkdir /var/run/sshd
# RUN echo 'root:aquila' | chpasswd
# RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# RUN grep "^X11UseLocalhost" /etc/ssh/sshd_config || echo "X11UseLocalhost no" >> /etc/ssh/sshd_config

# # SSH login fix. Otherwise user is kicked off after login
# RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# #Rebuild MESA with llvmpipe (from https://turbovnc.org/Documentation/Mesa)
# RUN wget ftp://ftp.freedesktop.org/pub/mesa/mesa-18.3.1.tar.gz
# RUN tar -zxvf mesa-18.3.1.tar.gz
# RUN rm mesa-18.3.1.tar.gz
# WORKDIR /mesa-18.3.1
# RUN autoreconf -fiv
# RUN ./configure --enable-glx=gallium-xlib --disable-dri --disable-egl --disable-gbm --with-gallium-drivers=swrast --prefix=$HOME/mesa
# RUN make install

# #set up locales
# RUN apt install -y locales screen
# RUN locale-gen en_GB.UTF-8 && locale-gen en_US.UTF-8

# #INSTALL ADDITIONAL ROS PACKAGES BELOW HERE

# #clear apt caches to reduce image size
# RUN rm -rf /var/lib/apt/lists/*

# #configure system to use new mesa
# WORKDIR /
# RUN echo "export LD_LIBRARY_PATH=/root/mesa/lib" > opengl.sh

# ENV NOTVISIBLE "in users profile"
# RUN echo "export VISIBLE=now" >> /etc/profile

# # Start and expose the SSH service
# EXPOSE 22
# RUN service ssh restart

WORKDIR /
RUN apt update && apt install -y \
    curl \
    libtool \
    libtool-bin \
    build-essential \
    sudo

RUN apt update && apt install -y \
    libsdformat6 \
    gazebo9 \
    gazebo9-plugin-base \
    libignition-math4 \
    libignition-math4-dev \
    libsdformat6-dev \
    libgazebo9 \
    libgazebo9-dev
    
# Upgrade node
RUN curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
RUN apt update && apt install -y \
    libjansson-dev \
    nodejs \
    libboost-dev \
    imagemagick \
    libtinyxml-dev \
    mercurial \
    cmake
RUN apt-get update
RUN apt-get install -y nodejs

WORKDIR /
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN sudo apt update
RUN apt install -y ros-melodic-desktop-full
RUN apt update && apt -y install git apt-utils
RUN git clone https://github.com/kevinhou912/ROS-Jackal-Data_Collection-Local.git
RUN mv ./ROS-Jackal-Data_Collection-Local ./jackal_ws
WORKDIR /jackal_ws
RUN apt -y install python-rosdep python-rosinstall python-rosinstall-generator python-wstool build-essential
RUN rosdep init; rosdep update
RUN rosdep install -y --from-paths . --ignore-src --rosdistro=melodic
RUN ["/bin/bash", "-c", "source /opt/ros/melodic/setup.bash"]
RUN /bin/bash -c '. /opt/ros/melodic/setup.bash; cd /jackal_ws; catkin_make'


# setup gzweb
WORKDIR /
RUN mkdir /barn-challenge-web
WORKDIR /barn-challenge-web
RUN git clone https://github.com/osrf/gzweb
WORKDIR /barn-challenge-web/gzweb
RUN git checkout gzweb_1.4.1
COPY ./gzweb_new/gz3d/client/index.html /barn-challenge-web/gzweb/gz3d/client/index.html
RUN npm run deploy --- -m

WORKDIR /barn-challenge-web
COPY ./joy_redirector ./joy_redirector

# setup environment
EXPOSE 8080
EXPOSE 8081

WORKDIR /barn-challenge-web
COPY ./start_script.sh ./start_script.sh
ENTRYPOINT ["/bin/bash", "/barn-challenge-web/start_script.sh"]