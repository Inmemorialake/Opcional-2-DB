FROM postgres:15

ENV POSTGRES_DB=Opcional2DB
ENV POSTGRES_USER=Inmemorialake
ENV POSTGRES_PASSWORD=NoPuedoPerderEsteOpcional

COPY ./*.sql /docker-entrypoint-initdb.d/

EXPOSE 5432