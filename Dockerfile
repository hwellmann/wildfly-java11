FROM ubuntu:bionic

LABEL maintainer="Harald Wellmann <harald.wellmann@gmx.de>"

# Install packages necessary to run EAP
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install curl


RUN curl -O https://download.java.net/java/GA/jdk11/13/GPL/openjdk-11.0.1_linux-x64_bin.tar.gz && \
    tar xzv -C /opt -f openjdk-11.0.1_linux-x64_bin.tar.gz && \
    update-alternatives --install /usr/bin/java java /opt/jdk-11.0.1/bin/java 1 && \
    rm openjdk-11.0.1_linux-x64_bin.tar.gz

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)
RUN groupadd -r jboss -g 1000 && \ 
    useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

# Set the working directory to jboss' user home directory
WORKDIR /opt/jboss

# Set the JAVA_HOME variable to make it clear where Java is located
ENV JAVA_HOME /opt/jdk-11.0.1

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 15.0.0.Final
ENV WILDFLY_SHA1 a387f2ebf1b902fc09d9526d28b47027bc9efed9
ENV JBOSS_HOME /opt/jboss/wildfly

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Expose the ports we're interested in
EXPOSE 8080

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
