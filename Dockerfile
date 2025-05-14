FROM openjdk:17-alpine

LABEL author=amp-support@equinix.com

WORKDIR /app

# Install curl
RUN apk update && apk add --no-cache curl

# ARGs for application configurations
ARG APP_TAG
ENV spring.cloud.config.name=${APP_TAG}

ARG VAULT_URL
ENV spring.config.import=${VAULT_URL}

ARG APP_VAULT_PROFILE_NAME
ENV spring.profiles.active=${APP_VAULT_PROFILE_NAME}

# Download the OpenTelemetry Java agent
ARG OTEL_AGENT_URL="https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar"
RUN wget -O /app/opentelemetry-javaagent.jar ${OTEL_AGENT_URL}

# Add environment-specific attributes
ENV OTEL_RESOURCE_ATTRIBUTES=serviceName=clm-portal,env=${APP_TAG}

# OpenTelemetry environment variable
# 300318 - For Cloud grafana
# 300218 - For OnPrem grafana
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://sv2lxgraapqa005:30318

# Copy the application JAR file
COPY target/ClmPortal-0.0.1-SNAPSHOT.jar app.jar

# Set entrypoint to run the Java application with OpenTelemetry
ENTRYPOINT ["java", "-javaagent:/app/opentelemetry-javaagent.jar", "-jar", "app.jar"]
