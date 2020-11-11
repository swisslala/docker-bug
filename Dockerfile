FROM docker-test:builder as my-builder
FROM docker-test:base
# above, docer-test:base has a copy --from=my-builder baked in

#below is neede to force buildkit to recognize the dependency
#COPY --from=my-builder ./compile.test /tmp