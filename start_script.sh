#!/bin/bash

source /opt/ros/melodic/setup.bash
source /jackal_ws/devel/setup.bash
roslaunch jackal_gazebo jackal_world.launch config:=front_laser gui:=false & 
sleep 10
cd /barn-challenge-web/joy_redirector
./joy_redirector & \
cd /barn-challenge-web/gzweb && npm start
