# Opcional 2 DB

Este es el codigo que se me pidio en la parte practica del opcional 2 de la clase de Base de Datos.

## Instrucciones para correr el proyecto

1. Primero que nada clonar el repositorio (si quieres tenerlo en local)
2. Tener Docker instalado en tu maquina
3. Abrir una terminal en la carpeta raiz del proyecto
4. Correr el siguiente comando para levantar los contenedores de Docker:

    ``` bash
    docker build -t inmemorialake/opcionaldb ./
    docker run -p 5432:5432 --name opcionaldb inmemorialake/opcionaldb:latest
    ```

>O al menos asi lo hice yo, si quieres usar otro metodo para correr los contenedores de Docker, adelante, pero pues ya me tomé la molestia de hacer el Dockerfile.

5. Esperar a que se levanten los contenedores y la base de datos este lista para aceptar conexiones.
6. Conectarse a la base de datos como prefieras (yo lo hago desde VSCode con la extension de PostgreSQL).

## Sustentación (Video de Youtube)

No sé por qué alguien quisiera verme a mí explicando este proyecto, pero si es así, aquí está el link al video de la sustentación:

[Video Sustentación Opcional 2 en Youtube](https://youtu.be/QtPoyjhvrCs)
