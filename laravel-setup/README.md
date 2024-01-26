# Laravel setup notes

### Setting up inter-service communication

We don't need to expose a port in `php` service, as with docker compose all services are by default in the same network and can therefore communicate and discover one another. Because we don't need to access the `php` service from the host machine, we can skip mapping a port -> instead we've just changed the `./nginx/nginx.conf` file in line 12 to use the port expected by the php base image.

### To create a default project with laravel composer:

```bash
docker-compose run --rm composer create-project --prefer-dist laravel/laravel .
```

This will only execute the `composer` service from docker compose, with the set commands, which will create a new project in the `.` directory -> bear in mind that in the `composer.dockerfile` we've defined the workdir to be `/var/www/html`, which is mapped to `./src` dir in local machine.

### Bringing up the setup

```bash
docker compose up -d server php mysql
```

This was prior to adding `depends_on` to docker-compose - then we had to specify all the services we wanted to bring up.

```bash
docker compose up -d server   
```

If we want to build the custom images if there's any changes:

```bash
 docker compose up -d --build server
 ```

 ### To run the artisan and npm utility containers
 
 ```bash
 docker compose run --rm artisan migrate
 ```

 Note: We can override things from images in `docker-compose.yaml` files, such as workdir or entrypoint instructions.


 ### Making containers deployable

 Currently because of bind mounts we can't deploy the application without copying the `src` dir to any other machine. To fix that we added `COPY` commands to `php.dockerfile` and `nginx.dockerfile`. Because we are copyin the stuff in the `.dockerfile`, we could also leave out volumes for `server` and `php` services - they're still left in to override the image for development purposes to reflect any changes immediately


 ### Side notes:

 - Had to use `mariadb:10.5.8` for mysql because of Apple Silicon - should be a drop-in replacement (it works)
 - Had to update the `php.dockerfile` to use `php:8.3-fpm-alpine` image, otherwise I got some dumb php errors: `Parse error: syntax error, unexpected '|', expecting variable (T_VARIABLE) in...`
