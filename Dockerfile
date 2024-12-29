# Base de Ubuntu LTS con zsh
FROM cartagodocker/zsh:latest

# ----------------> VARIABLES
# Variables que únicamente se usarán en el DockerFile
# Ha tener en cuenta que las variables ARG no se pasan al contenedor y se borran al terminar la imagen sin crear capas adicionales, ni espacio en la imagen (Testear si pasan o no también al docker-compose)
ARG PROJECT=${PROJECT:-ionic-cover}
ARG CONTAINER_USER=${CONTAINER_USER:-container-user}
ARG CONTAINER_GROUP=container-group
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_HOME=/home/${CONTAINER_USER}
ARG USER_SHELL=/bin/zsh

# Versiones de instalación
ARG NODE_VERSION=22
ARG NPM_VERSION=11.0.0
ARG JAVA_VERSION=17
ARG GRADLE_VERSION=8.11.1
ARG ANDROID_API_VERSION=35
ARG ANDROID_BUILD_TOOLS_VERSION=34.0.0
ARG BUN_VERSION=1.1.38
ARG IONIC_CLI_VERSION=7.2.0
ARG ANGULAR_VERSION=19.0.6
ARG CAPACITOR_VERSION=6.2.0

# Definición de variables de entorno "home"
ARG GRADLE_HOME=/usr/local/gradle/gradle-${GRADLE_VERSION}/bin
ARG BUN_HOME=${USER_HOME}/.bun/bin
ARG FNM_HOME=/usr/local/fnm

ARG ANDROID_SDK_FOLDER=/usr/local/android
ARG SDKMANAGER_BIN="${ANDROID_SDK_FOLDER}/cmdline-tools/bin/sdkmanager"
ARG SDKMANAGER_ARGS="--sdk_root=${ANDROID_SDK_FOLDER}"

# Rutas de descarga de software no disponible vía repositorio
ARG NODE_URL=https://deb.nodesource.com/setup_${NODE_VERSION}.x
ARG BUN_URL=https://bun.sh/install
ARG ANDROID_SDK_URL=https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip
ARG GRADLE_URL=https://services.gradle.org/distributions/
ARG GRADLE_FILE=gradle-${GRADLE_VERSION}-bin.zip

# PATHS que se añadirán al PATH de entorno. Lo dejamos aquí para mayor visibilidad y facilidad de mantenimiento en distintas líneas
ARG CMDLINE_TOOLS=${ANDROID_SDK_FOLDER}/cmdline-tools/latest/bin
ARG PLATFORM_TOOLS=${ANDROID_SDK_FOLDER}/platform-tools
ARG BUILD_TOOLS=${ANDROID_SDK_FOLDER}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}

# Configurar variables de entorno necesarias para Java y Android
# A tener en cuenta que las variables de entorno se pasan al contenedor y se mantienen en la imagen
ENV DEBIAN_FRONTEND=noninteractive \
    JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64 \
    ANDROID_SDK_HOME=${ANDROID_SDK_FOLDER} \
    FNM_HOME=${FNM_HOME} \
    # Se crea para compatibilidad con posibles scripts antiguos que usen ANDROID_HOME con la misma ruta que ANDROID_SDK_HOME
    ANDROID_HOME=${ANDROID_SDK_FOLDER} \
    GRADLE_HOME=${GRADLE_HOME} \
    # Version de node para que fnm cargue en el .zshrc
    NODE_VERSION=${NODE_VERSION} \
    PROJECT=${PROJECT} \
    # PATH de entorno globales accesibles desde cualquier lugar, para poder usar los comandos instalados en dichas rutas
    PATH=$PATH:${CMDLINE_TOOLS}:${PLATFORM_TOOLS}:${BUILD_TOOLS}:${BUN_HOME}:${GRADLE_HOME}:${FNM_HOME}

# ----------------> CREAR USUARIO
# Primero eliminamos el usuario y grupo con el UID y GID 1000 si existen (En las últimas versiones de ubuntu hay un usuario "ubuntu" predefinido, pero queremos tenerlo con nuestro nombre especificado)
RUN getent passwd ${USER_UID} && userdel -r $(getent passwd ${USER_UID} | cut -d: -f1) || true && \
    getent group ${USER_GID} && groupdel $(getent group ${USER_GID} | cut -d: -f1) || true &&\
    # Crear el usuario container-user con el mismo UID y GID que previamente eliminamos, ahora con nuestro nombre especificado
    groupadd -g ${USER_GID} ${CONTAINER_GROUP} && \
    useradd -u ${USER_UID} -g ${CONTAINER_GROUP} -ms ${USER_SHELL} ${CONTAINER_USER}

# INSTALACIONES COMO USUARIO ROOT <----------------
# ----------------> ACTUALIZAR PAQUETES BASE Y HERRAMIENTAS ESENCIALES
# Actualizar paquetes base y herramientas esenciales
# Paquetes base y herramientas esenciales de Ubuntu
# Java, Fast node manager, Node y Bun
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg wget unzip build-essential git ca-certificates openjdk-${JAVA_VERSION}-jdk-headless \
    # Instalamos Fast node manager
    && curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir ${FNM_HOME} --skip-shell \
    && fnm completions --shell zsh > ${FNM_HOME}/_fnm \
    && fnm install ${NODE_VERSION} \
    && fnm default ${NODE_VERSION} \
    && eval $(fnm env) && fnm use ${NODE_VERSION} \
    && mkdir -p ${USER_HOME}/.local/share \
    && cp -r /root/.local/share/fnm ${USER_HOME}/.local/share/fnm \
    && chmod -R 755 ${FNM_HOME} \
    && chown -R ${USER_UID}:${USER_GID} ${FNM_HOME} \
    # Instalación de bun
    && curl -fsSL ${BUN_URL} | bash -s bun-v${BUN_VERSION} \
    && mv /root/.bun/bin/bun /usr/local/bin/ \
    && chmod a+x /usr/local/bin/bun \
    # Cambiar propietario de la carpeta home al haber instalado desde root
    && chown -R ${USER_UID}:${USER_GID} ${USER_HOME} \
    && chmod -R 755 ${USER_HOME} \
    # Limpiar cache y temporales
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* tmp/* /root/.bun/* /root/.cache

# ----------------> INSTALAR ANDROID SDK Y HERRAMIENTAS
RUN mkdir -p ${ANDROID_SDK_HOME} \
    && cd ${ANDROID_SDK_HOME} \
    && wget -O android.zip ${ANDROID_SDK_URL} \
    && unzip android.zip \
    && rm android.zip \
    && rm -rf ${ANDROID_SDK_HOME}/licenses \
    && chmod a+x -R ${ANDROID_SDK_HOME} \
    && chown -R ${UID}:${GID} ${ANDROID_SDK_HOME} \
    && touch ${ANDROID_SDK_HOME}/repositories.cfg  \
    && yes | ${SDKMANAGER_BIN} ${SDKMANAGER_ARGS} "platform-tools" "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    && yes | ${SDKMANAGER_BIN} ${SDKMANAGER_ARGS} "platforms;android-${ANDROID_API_VERSION}" \
    && yes | ${SDKMANAGER_BIN} ${SDKMANAGER_ARGS} "extras;google;google_play_services" "extras;android;m2repository" \
    && yes | ${SDKMANAGER_BIN} ${SDKMANAGER_ARGS} "add-ons;addon-google_apis-google-24" "skiaparser;3" "cmdline-tools;latest" \
    # Parche para arreglar problemas desde Android Build Tools 32.0
    && cd ${BUILD_TOOLS} \
    && cp d8 dx && cd lib && cp d8.jar dx.jar \
    && chmod -R 777 /usr/local/android

    # # ----------------> INSTALAR GRADLE
    RUN wget ${GRADLE_URL}${GRADLE_FILE} -P /tmp/gradle \
    && unzip /tmp/gradle/${GRADLE_FILE} -d /usr/local/gradle \
    && chmod a+x /usr/local/gradle \
    && rm -rf /tmp/gradle

# Añade texto necesario para el correcto funcionamiento en el .zshrc
# El script que lo permite esta en la imagen base de zsh (localizado en /usr/local/bin/add_text_to_zshrc)
RUN add_text_to_zshrc "$(printf '%s\n' \
    '# Asignamos el autocompletado para fnm' \
    'fpath=(${FNM_HOME} $fpath)' \
    'eval $(fnm env)' \
    'fnm use ${NODE_VERSION}' \
    'alias bunx="bun x"' \
    '# Autocompletado para angular' \
    'source <(ng completion script)')"

# INSTALACIONES COMO USUARIO DE CONTENEDOR <----------------
USER ${CONTAINER_USER}
# ----------------> INSTALAR Angular CLI y Ionic CLI
RUN eval $(fnm env) && fnm use ${NODE_VERSION} \
    && bun install -g npm@${NPM_VERSION} \
    @angular/cli@${ANGULAR_VERSION} \
    @ionic/cli@${IONIC_CLI_VERSION} \
    @capacitor/cli@${CAPACITOR_VERSION} \
    # Hace bun como gestor de paquetes por defecto de angular para aumentar la velocidad de transpilación de angular
    && ng config --global cli.packageManager bun
    # && ionic config set -g npmClient bun <- Todavia es incompatible con bun

# Configuración de inicio del contenedor
WORKDIR /app/${PROJECT}
# Realizamos la entrada al contenedor con el shell zsh
ENTRYPOINT ["zsh", "-ic"]
CMD ["tail -f /dev/null"]
