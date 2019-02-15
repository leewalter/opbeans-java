#Multi-Stage build

#Build application stage
#We need maven.
FROM maven:3.5.3-jdk-10
ARG JAVA_AGENT_BRANCH=master
ARG JAVA_AGENT_REPO=elastic/apm-agent-java

WORKDIR /usr/src/java-app

#build the application
ADD . /usr/src/java-code
WORKDIR /usr/src/java-code/opbeans

#Bring the latest frontend code
COPY --from=opbeans/opbeans-frontend:latest /app/build src/main/resources/public

RUN mvn -q -B package -DskipTests
RUN cp -v /usr/src/java-code/opbeans/target/*.jar /usr/src/java-app/app.jar

#fetch the agent
RUN curl -L "https://oss.sonatype.org/service/local/artifact/maven/redirect?r=snapshots&g=co.elastic.apm&a=elastic-apm-agent&v=LATEST" > /usr/src/java-app/elastic-apm-agent.jar

#Run application Stage
#We only need java

FROM openjdk:10

RUN export
WORKDIR /app
COPY --from=0 /usr/src/java-app/*.jar ./

CMD java -javaagent:/app/elastic-apm-agent.jar -Dspring.profiles.active=${OPBEANS_JAVA_PROFILE:-}\
                                        -Dserver.port=${OPBEANS_SERVER_PORT:-}\
                                        -Dserver.address=${OPBEANS_SERVER_ADDRESS:-0.0.0.0}\
                                        -Dspring.datasource.url=${DATABASE_URL:-}\
                                        -Dspring.datasource.driverClassName=${DATABASE_DRIVER:-}\
                                        -Dspring.jpa.database=${DATABASE_DIALECT:-}\
                                        -jar /app/app.jar
