FROM alpine:3.15
COPY --from=envoyproxy/envoy-contrib:v1.21.1 /usr/local/bin/envoy /usr/local/bin/envoy
COPY --from=envoyproxy/envoy-contrib:v1.21.1 /usr/local/bin/su-exec /usr/local/bin/su-exec
RUN apk add gcompat
