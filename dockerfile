[epayuser@bastion improved]$ cat DOCKERFILE
# Multi-stage build for better security and smaller image size
FROM registry.dev.sbiepay.sbi:8443/ubi9/openjdk-21:1.22-1.1749462973 AS base

# Set environment variables
ENV SPARK_VERSION=4.0.0
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/opt/spark
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH=$PATH:$SPARK_HOME/bin:$JAVA_HOME/bin

# Create non-root user for security
RUN groupadd -r spark && useradd -r -g spark spark

# Install necessary packages
# RUN microdnf update -y && \
#     microdnf install -y curl wget tar gzip && \
#     microdnf clean all

# Copy Spark distribution
COPY spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${SPARK_HOME}

# Set ownership to spark user
RUN chown -R spark:spark ${SPARK_HOME}

# Add necessary Hadoop/cloud storage connectors if not already bundled (example for S3)
# RUN curl -sL "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}.x/hadoop-aws-${HADOOP_VERSION}.x.jar" -o ${SPARK_HOME}/jars/hadoop-aws-${HADOOP_VERSION}.x.jar
# RUN curl -sL "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.xxx/aws-java-sdk-bundle-1.11.xxx.jar" -o ${SPARK_HOME}/jars/aws-java-sdk-bundle-1.11.xxx.jar

# Create necessary directories
RUN mkdir -p /opt/spark/logs /opt/spark/events /opt/spark/conf && \
    chown -R spark:spark /opt/spark/logs /opt/spark/events /opt/spark/conf

# Copy application JAR
COPY epay_operations_service-0.0.1.jar ${SPARK_HOME}/jars/
RUN chown spark:spark ${SPARK_HOME}/jars/epay_operations_service-0.0.1.jar

# Copy configuration files (if available)
COPY --chown=spark:spark spark-config/ ${SPARK_HOME}/conf/ 2>/dev/null || true

# Set proper permissions
RUN chmod +x ${SPARK_HOME}/bin/* && \
    chmod 755 ${SPARK_HOME}/jars/epay_operations_service-0.0.1.jar

# Switch to spark user
USER spark

# Set working directory
WORKDIR ${SPARK_HOME}

# Expose ports
EXPOSE 4040 8080 18080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Default command (can be overridden by Spark Operator)
ENTRYPOINT ["/opt/spark/bin/spark-submit"]

[epayuser@bastion improved]$
