FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      autoconf \
      automake \
      build-essential \
      ca-certificates \
      file \
      gettext \
      intltool \
      libgtk2.0-dev \
      librsvg2-dev \
      pkg-config \
      wget && \
    rm -rf /var/lib/apt/lists/*

COPY . /app
WORKDIR /app/QCADesignerE

RUN chmod +x autogen.sh configure install-sh compile depcomp missing mkinstalldirs
RUN ./autogen.sh
RUN ./configure --prefix=/usr
RUN make -j"$(nproc)"
RUN make install DESTDIR=/app/AppDir

FROM builder AS appimage

RUN mkdir -p /app/AppDir/usr/share/icons/hicolor/48x48/apps \
             /app/AppDir/usr/share/icons/hicolor/scalable/apps \
             /app/AppDir/usr/share/applications \
             /app/AppDir/usr/share/metainfo \
             /app/AppDir/usr/share/appdata

RUN cp /app/QCADesignerE/pixmaps/QCADesignerE_0_48x48x24a.png \
       /app/AppDir/usr/share/icons/hicolor/48x48/apps/QCADesignerE.png && \
    cp /app/QCADesignerE/pixmaps/QCADesignerE.svg \
       /app/AppDir/usr/share/icons/hicolor/scalable/apps/QCADesignerE.svg

RUN printf '[Desktop Entry]\nName=QCADesignerE\nExec=QCADesigner %%f\nIcon=QCADesignerE\nType=Application\nCategories=Science;Engineering;\nComment=QCA circuit designer and simulator\nTerminal=false\nStartupNotify=true\n' \
    > /app/AppDir/usr/share/applications/io.github.Pratyay360.QCADesignerE.desktop

RUN cp /app/io.github.Pratyay360.QCADesignerE.metainfo.xml \
       /app/AppDir/usr/share/metainfo/io.github.Pratyay360.QCADesignerE.metainfo.xml && \
    cp /app/io.github.Pratyay360.QCADesignerE.metainfo.xml \
       /app/AppDir/usr/share/metainfo/io.github.Pratyay360.QCADesignerE.appdata.xml && \
    cp /app/io.github.Pratyay360.QCADesignerE.metainfo.xml \
       /app/AppDir/usr/share/appdata/io.github.Pratyay360.QCADesignerE.appdata.xml

# Download linuxdeploy and GTK plugin (x86_64)
RUN wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
         -O /usr/local/bin/linuxdeploy && \
    chmod +x /usr/local/bin/linuxdeploy

RUN wget -q https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh \
         -O /usr/local/bin/linuxdeploy-plugin-gtk.sh && \
    chmod +x /usr/local/bin/linuxdeploy-plugin-gtk.sh

WORKDIR /app

ENV APPIMAGE_EXTRACT_AND_RUN=1
ENV ARCH=x86_64
ENV GDK_MODULES=""
ENV LDAI_UPDATE_INFORMATION="gh-releases-zsync|Pratyay360|QCADesigner-E|latest|*x86_64.AppImage.zsync"
ENV UPDATE_INFORMATION="gh-releases-zsync|Pratyay360|QCADesigner-E|latest|*x86_64.AppImage.zsync"

RUN DEPLOY_GTK_VERSION=2 \
    OUTPUT=QCADesignerE-x86_64.AppImage \
    /usr/local/bin/linuxdeploy \
      --appdir AppDir \
      --executable AppDir/usr/bin/QCADesigner \
      --desktop-file AppDir/usr/share/applications/io.github.Pratyay360.QCADesignerE.desktop \
      --icon-file AppDir/usr/share/icons/hicolor/48x48/apps/QCADesignerE.png \
      --plugin gtk \
      --output appimage && \
    test -f /app/QCADesignerE-x86_64.AppImage && \
    test -f /app/QCADesignerE-x86_64.AppImage.zsync
