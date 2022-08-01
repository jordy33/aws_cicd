FROM ubuntu:20.04
MAINTAINER JorgeMacias
ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="America/Mexico_City"
RUN apt update
RUN apt -y install tzdata
RUN ln -fs /usr/share/zoneinfo/America/Mexico_City /etc/localtime
RUN apt --no-install-recommends -y install python3.9
RUN apt -y install python3.9-venv
RUN apt -y install git
RUN cd /home
RUN git clone https://github.com/jordy33/django-markdown-editor.git /home/django-markdown-editor
RUN ls /home
RUN echo martor >> /home/django-markdown-editor/requirements.txt
RUN echo gunicorn >> /home/django-markdown-editor/requirements.txt
RUN python3.9 -m venv /home/django-markdown-editor/venv
RUN ls /home/django-markdown-editor/*
RUN /home/django-markdown-editor/venv/bin/pip install -r /home/django-markdown-editor/requirements.txt
EXPOSE 80
CMD /home/django-markdown-editor/venv/bin/python3.9 /home/django-markdown-editor/martor_demo/manage.py  runserver 0.0.0.0:80
