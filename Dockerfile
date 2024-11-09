# Use an official OpenJDK image as the base image
FROM openjdk:17-jdk-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the generated jar file into the Docker image
COPY target/hello-spring-docker-0.0.1-SNAPSHOT.jar /app/hello-spring-docker.jar

# Expose port 8080 to the outside world
EXPOSE 8080

# Command to run the jar file
ENTRYPOINT ["java", "-jar", "hello-spring-docker.jar"]
