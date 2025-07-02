FROM openjdk:11-jdk-bullseye

ENV GO_VERSION=1.23.10
ENV GOMOBILE_COMMIT=latest
ENV NDK_LTS_VERSION=23.1.7779620
ENV SDK_TOOLS_VERSION=8092744
ENV ANDROID_PLATFORM_VERSION=31

ENV ANDROID_HOME="/home/circleci/android-sdk"
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV CMDLINE_TOOLS_ROOT="${ANDROID_HOME}/cmdline-tools/latest/bin"
ENV ADB_INSTALL_TIMEOUT=120
ENV PATH="${ANDROID_HOME}/emulator:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/platform-tools/bin:${PATH}"
ENV ANDROID_NDK_HOME="/home/circleci/android-sdk/ndk/${NDK_LTS_VERSION}"
ENV ANDROID_NDK_ROOT="${ANDROID_NDK_HOME}"

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
        mkdir ${ANDROID_HOME}/platforms && \
        mkdir ${ANDROID_HOME}/ndk && \
        wget -O /tmp/cmdline-tools.zip -t 5 --no-verbose \
        "https://dl.google.com/android/repository/commandlinetools-linux-${SDK_TOOLS_VERSION}_latest.zip" && \
        unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
        rm /tmp/cmdline-tools.zip && \
        mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "build-tools;${ANDROID_PLATFORM_VERSION}.0.0" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "platforms;android-${ANDROID_PLATFORM_VERSION}" && \
    echo y | ${CMDLINE_TOOLS_ROOT}/sdkmanager "ndk;${NDK_LTS_VERSION}"

ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

# Install packages needed for CGO
RUN apt-get update && apt-get install -y --no-install-recommends \
                g++ \
                libc6-dev && \
        rm -rf /var/lib/apt/lists/* && \
        curl -sSL "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -xz -C /usr/local/ && \
        mkdir -p $GOPATH/bin && \
    go install "golang.org/x/mobile/cmd/gomobile@${GOMOBILE_COMMIT}" && \
    gomobile init && \
    mkdir -p /tmp/gomobile-deps && \
    cd /tmp/gomobile-deps && \
    go mod init gomobile-deps && \
    go get golang.org/x/mobile/bind && \
    cd / && rm -rf /tmp/gomobile-deps && \
    mkdir /module

VOLUME "/module"
WORKDIR "/module"

ENTRYPOINT ["gomobile"]
