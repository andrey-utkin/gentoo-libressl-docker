# Setup based on instructions from
# https://github.com/gentoo/gentoo-docker-images
# See "Using the portage container in a multi-stage build"

# name the portage image
FROM gentoo/portage:20200412 as portage

# image is based on stage3-amd64
FROM gentoo/stage3-amd64-nomultilib:20200412

# copy the entire portage volume in
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

CMD /sbin/init

# All steps below based on instructions from
# https://wiki.gentoo.org/wiki/Project:LibreSSL
# See "Migration from openssl to libressl - Direction for users"

# No need to update world as we start up to date.

# diagnostic purposes
RUN emerge gentoolkit
RUN equery d openssl
RUN equery d libressl

# We begin by adding USE=libressl system wide and unmasking it for stable ebuilds.
RUN echo 'USE="${USE} libressl"' >> /etc/portage/make.conf
RUN echo 'CURL_SSL="libressl"' >> /etc/portage/make.conf
RUN mkdir -p /etc/portage/profile
RUN echo "-libressl" >> /etc/portage/profile/use.stable.mask
RUN echo "dev-libs/openssl" >> /etc/portage/package.mask
RUN echo "dev-libs/libressl" >> /etc/portage/package.accept_keywords 

# At this point we remove openssl and replace it by libressl.
# Let's first fetch the libressl tarball in case wget breaks!
RUN emerge -f libressl
RUN emerge -C openssl
RUN emerge -1q libressl

# We can now proceed to rebuild packages which need no further keywording/unmaskings.
RUN emerge -1q openssh wget python:2.7 python:3.6 python:3.7 iputils

# Finally, if emerge ends complaining existing preserved libs found, end the conversion by doing
RUN emerge -q @preserved-rebuild
