FROM postgres:11.4-alpine
WORKDIR /sql
COPY sql/.pgpass /sql/.pgpass
RUN chmod 600 .pgpass