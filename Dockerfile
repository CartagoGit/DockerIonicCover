# Base de Ubuntu LTS con zsh
FROM cartagodocker/angular:latest

# ----------------> VARIABLES
# Variables que únicamente se usarán en el DockerFile
# Ha tener en cuenta que las variables ARG no se pasan al contenedor y se borran al terminar la imagen sin crear capas adicionales, ni espacio en la imagen 

# Versiones de instalación
ARG JAVA_VERSION=17
ARG GRADLE_VERSION=8.11.1
ARG ANDROID_API_VERSION=35
ARG ANDROID_BUILD_TOOLS_VERSION=34.0.0
ARG IONIC_CLI_VERSION=7.2.0
ARG CAPACITOR_VERSION=6.2.0

# Definición de variables de entorno "home"
ARG GRADLE_HOME=/usr/local/gradle/gradle-${GRADLE_VERSION}/bin

ARG ANDROID_SDK_FOLDER=/usr/local/android
ARG SDKMANAGER_BIN="${ANDROID_SDK_FOLDER}/cmdline-tools/bin/sdkmanager"
ARG SDKMANAGER_ARGS="--sdk_root=${ANDROID_SDK_FOLDER}"

# Rutas de descarga de software no disponible vía repositorio
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
    # Se crea para compatibilidad con posibles scripts antiguos que usen ANDROID_HOME con la misma ruta que ANDROID_SDK_HOME
    ANDROID_HOME=${ANDROID_SDK_FOLDER} \
    GRADLE_HOME=${GRADLE_HOME} \
    # PATH de entorno globales accesibles desde cualquier lugar, para poder usar los comandos instalados en dichas rutas
    PATH=${CMDLINE_TOOLS}:${PLATFORM_TOOLS}:${BUILD_TOOLS}:${GRADLE_HOME}:$PATH


# INSTALACIONES COMO USUARIO ROOT <----------------
# ----------------> ACTUALIZAR PAQUETES BASE Y HERRAMIENTAS ESENCIALES
# Actualizar paquetes base y herramientas esenciales
# Paquetes base y herramientas esenciales de Ubuntu
# Java, y herramientas necesarias
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-${JAVA_VERSION}-jdk-headless \
# ----------------> INSTALAR ANDROID SDK Y HERRAMIENTAS
    && mkdir -p ${ANDROID_SDK_HOME} \
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
    && chmod -R 777 /usr/local/android \
# # ----------------> INSTALAR GRADLE
    && wget ${GRADLE_URL}${GRADLE_FILE} -P /tmp/gradle \
    && unzip /tmp/gradle/${GRADLE_FILE} -d /usr/local/gradle \
    && chmod a+x /usr/local/gradle \
# ----------------> INSTALAR Angular CLI y Ionic CLI
    && bun install -g \
    @ionic/cli@${IONIC_CLI_VERSION} \
    @capacitor/cli@${CAPACITOR_VERSION} \
    # ionic config set -g npmClient bun <- Todavia es incompatible con bun \
    # Limpiar cache y temporales
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* || true


