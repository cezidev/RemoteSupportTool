#!/usr/bin/env bash
#
# Detect operating system and select the appropriate OpenJDK bundle.
# Copyright 2015-2019 OpenIndex.de
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# -----------------------------------------------------------------------
#
# OpenJDK binaries are provided by:
# https://www.bell-sw.com/java.html
# https://github.com/OpenIndex/openjdk-linux-x86
#
# -----------------------------------------------------------------------

LINUX_X86_JDK="https://github.com/OpenIndex/openjdk-linux-x86/releases/download/jdk-11.0.2%2B9/jdk-11.0.2+9-linux-x86.tar.gz"
LINUX_X86_64_JDK="https://github.com/bell-sw/Liberica/releases/download/11.0.2/bellsoft-jdk11.0.2-linux-amd64.tar.gz"
MACOS_X86_64_JDK="https://github.com/bell-sw/Liberica/releases/download/11.0.2/bellsoft-jdk11.0.2-macos-amd64.zip"
WINDOWS_X86_JDK="https://github.com/bell-sw/Liberica/releases/download/11.0.2/bellsoft-jdk11.0.2-windows-i586.zip"
WINDOWS_X86_64_JDK="https://github.com/bell-sw/Liberica/releases/download/11.0.2/bellsoft-jdk11.0.2-windows-amd64.zip"

MODULES="java.desktop,java.naming,jdk.crypto.ec"

SYSTEM="$( uname -s )"
SYSTEM_ARCH="$( arch )"
case "$SYSTEM" in

  Darwin)
    echo "Initializing macOS environment..."
    SYSTEM_JDK="$MACOS_X86_64_JDK"
    ;;

  Linux)
    case "$SYSTEM_ARCH" in
        i386 | i586 | i686)
          echo "Initializing Linux x86 environment..."
          SYSTEM_JDK="$LINUX_X86_JDK"
          ;;
        x86_64)
          echo "Initializing Linux x86_64 environment..."
          SYSTEM_JDK="$LINUX_X86_64_JDK"
          ;;
        *)
          echo "Unsupported Linux environment ($SYSTEM_ARCH)..."
          exit 1
          ;;
    esac
    ;;

  *)
    echo "Unsupported environment ($SYSTEM)..."
    exit 1
    ;;

esac


#
# Configure generated runtime environment.
#

function configure_runtime {
    echo "Configuring runtime environment..."

    runtimeDir="$1"
    if [[ ! -d "${runtimeDir}" ]]; then
        echo "WARNING: Can't find runtime environment at: ${runtimeDir}"
        exit 1
    fi

    securityConf="${runtimeDir}/conf/security/java.security"
    if [[ ! -f "${securityConf}" ]]; then
        echo "WARNING: Can't find security configuration at: ${securityConf}"
        exit 1
    fi

    # Due to a bug in OpenJDK 11.0.2 we need to disable TLSv1.3.
    # The bug was fixed in OpenJDK 12. And should be backported into OpenJDK 11.0.3.
    #
    # see https://sourceforge.net/p/hsqldb/bugs/1539/
    # see https://bugs.openjdk.java.net/browse/JDK-8212885
    # see https://bugs.openjdk.java.net/browse/JDK-8218093
    echo "Disabling TLSv1.3..."
    sed -i -e "s|^jdk.tls.disabledAlgorithms=|jdk.tls.disabledAlgorithms=TLSv1.3, |g" "${securityConf}"
}


#
# Extract a downloaded archive.
#

function extract_archive {
    archive="$1"
    if [[ "$archive" == *.zip ]]; then
        #echo "unzip $archive"
        unzip -q "$archive"
    else
        #echo "untar $archive"
        tar xfz "$archive"
    fi
}
