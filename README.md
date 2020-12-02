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

**Warning** Docker images [futuregateway/fgapiserver:0.2][dkfgapiserver2] and [futuregateway/fgapiserver:0.3][dkfgapiserver3] (currenltly latest) by default has **PTV** authorization option switched on, set to `False` the corresponding configuration option `fgapisrv_lnkptvflag` to enable UGR.

[dkfgapiserver2]: https://hub.docker.com/layers/futuregateway/fgapiserver/0.3/images/sha256-42df212e875de8f3ee8056ed52be32b1668057effc16073ab138a3343f9838b5?context=explore
[dkfgapiserver3]: https://hub.docker.com/layers/futuregateway/fgapiserver/0.2/images/sha256-a30b934478cb35cc088816653a3d12bf62be6b85a324f23786e6cf17c806d7c3?context=explore
