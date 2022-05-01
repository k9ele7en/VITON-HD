FROM pytorch/pytorch:1.11.0-cuda11.3-cudnn8-runtime
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get install libgomp1 ffmpeg libsm6 libxext6 python3-opencv -y

COPY requirements.txt .
RUN pip3 install -r requirements.txt

CMD ["bash"]

# docker build -t viton-hd-docker:v1 .
# sudo docker run --gpus=all --shm-size 4G -v /home/code/VITON-HD:/mnt -itd viton-hd-docker:v1 bash
