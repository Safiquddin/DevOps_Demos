FROM jenkins/jenkins

USER root

RUN curl -O https://bootstrap.pypa.io/get-pip.py  && \
    python get-pip.py && \
    pip install ansible --upgrade

USER jenkins


#on ubuntu
 RUN apt-get update && \                            
     apt-get install python3 python3-pip -y && \     
	 pip3 install ansible --upgrade                               