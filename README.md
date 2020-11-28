# shAPIServer

Bash implementation of the FutureGateway API Server, used to improve compatibility and ease the creation of executor interfaces.

## Use FutureGateway containers to test/use shAPIServer

The script assumes the commands launched from shAPIServer project directory

```bash
# fgdb
docker run -d --name fgsb_shAPIServer -p 3306:3306 futuregateway/fgdb:latest

# fgAPIServer
docker run -d --name fgapiserver -p 8080:80 -p 8443:443 -p 18888:8888 -p 18889:8889 --link fgsb_shAPIServer:fgdb -v $(pwd)/fgiosandbox:/app/fgiosandbox futuregateway/fgapiserver
```
