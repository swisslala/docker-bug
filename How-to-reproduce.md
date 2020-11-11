First ensure all images are cleared (reset docket or do a system wide prune)

### build 1 - prep
* run ./build-1.sh
- this should produce the 2 images we use in our org
`docker-test:builder`
- this image is used to run a bunch on ONBUILD cmd's and then we compile code inside the container and all compiled assets are ready for copy
`docker-test:base`
- this image is the final prod based image and no builds occur here, a simple copy from builder is all that occurs with some additional ONBUILD cmds

### build 2
* run ./buils-2.sh
- this is what our project dockerfiles look like, we can enforce some structure and compliance by using prebuilt builder and base images
- the final container result is
`docker-test:final`


Issues observed

1. Intermediate layers/images are left dangling. Since we use 2 FROM staements and the copy from is embedded in the base image, docker looses track of its dependencies.
 - run `./build-1.sh`
 - run `docker images`
 ```
 docker images
REPOSITORY          TAG                    IMAGE ID            CREATED             SIZE
docker-test         builder                640b0619ff56        2 minutes ago       142MB
docker-test         base                   eda9fe7c4b81        2 minutes ago       142MB
node                12.18.4-stretch-slim   544e10fd4863        8 weeks ago         142MB
```
- run `./build-2.sh`
```
docker images
REPOSITORY          TAG                    IMAGE ID            CREATED             SIZE
<none>              <none>                 cd621009f662        4 seconds ago       142MB
docker-test         final                  fe3d9acaeacb        4 seconds ago       142MB
docker-test         builder                640b0619ff56        3 minutes ago       142MB
docker-test         base                   eda9fe7c4b81        3 minutes ago       142MB
node                12.18.4-stretch-slim   544e10fd4863        8 weeks ago         142MB
```
* notice the <none> tagged image left lingering. This doesnt occur if you have multiple FROM statements in a single docker file

2. buildkit attempts to build in parallel and fails.
```
DOCKER_BUILDKIT=1 ./build-2.sh 
[+] Building 0.3s (6/6) FINISHED                                                                                                                                                     
 => [internal] load build definition from Dockerfile                                                                                                                            0.0s
 => => transferring dockerfile: 109B                                                                                                                                            0.0s
 => [internal] load .dockerignore                                                                                                                                               0.0s
 => => transferring context: 2B                                                                                                                                                 0.0s
 => [internal] load metadata for docker.io/library/docker-test:base                                                                                                             0.0s
 => [my-builder 1/1] FROM docker.io/library/docker-test:builder                                                                                                                 0.0s
 => => resolve docker.io/library/docker-test:builder                                                                                                                            0.0s
 => [stage-1 1/1] FROM docker.io/library/docker-test:base                                                                                                                       0.0s
 => ERROR [stage-1 2/1] COPY --from=my-builder ./compile.test ./                                                                                                                0.0s
------
 > [stage-1 2/1] COPY --from=my-builder ./compile.test ./:
------
failed to solve with frontend dockerfile.v0: failed to build LLB: failed to compute cache key: "/compile.test" not found: not found
```
* this is the same issue as above, buildkit parses the dockerfile and builds teh AST but misses the dependency.
- uncomment `COPY --from=my-builder ./compile.test /tmp` in the Dockerfile to force buildkit to set up a dependency