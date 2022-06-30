FROM python:3.9

RUN apt-get update && apt-get install -y jq zip git
RUN pip3 install --upgrade pip3
RUN pip3 install awscli

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
