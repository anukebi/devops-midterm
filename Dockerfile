FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY pom.xml mvnw checkstyle.xml ./
COPY .mvn .mvn
COPY src ./src
RUN chmod +x mvnw && ./mvnw clean package -DskipTests -Dcheckstyle.skip -q

FROM eclipse-temurin:21-jre-alpine
RUN apk update && apk upgrade --no-cache p11-kit p11-kit-trust
WORKDIR /app
COPY --from=build /app/target/cicd-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
