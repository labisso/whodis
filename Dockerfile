FROM jazzdd/alpine-flask:python3

# install the requirements. Make sure we do this first so that the layer
# will be cached and only regenerated when requirements.txt changes.
COPY requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt
RUN rm /tmp/requirements.txt

# deploy the app itself
COPY whodis /app/
