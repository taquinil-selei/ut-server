# UT2004 dedicated server on the OldUnreal 3374 patch (native 64-bit Linux).
# The image holds only the engine patch. Game content (maps, textures, sounds...)
# is licensed material and is mounted at /game, never baked into the image.
FROM debian:bookworm-slim

ARG OLDUNREAL_URL=https://github.com/OldUnreal/UT2004Patches/releases/download/3374-preview-23/OldUnreal-UT2004Patch3374-Linux-094b94dc.tar.bz2
ARG OLDUNREAL_SHA256=179ea43c8831bff147005850cd373c0ec2b70dcf6f841c2109c1525ef11ad4d3

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl bzip2 libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /opt/oldunreal-patch.tar.bz2 "$OLDUNREAL_URL" \
    && echo "$OLDUNREAL_SHA256  /opt/oldunreal-patch.tar.bz2" | sha256sum -c - \
    && echo "$OLDUNREAL_SHA256" > /opt/oldunreal-patch.id

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME /game
EXPOSE 7777/udp 7778/udp 7787/udp
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
