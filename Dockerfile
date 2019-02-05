#Multi-Stage build

#Build application stage
#We need maven.
FROM maven:3.5.3-jdk-10
ARG JAVA_AGENT_BRANCH=master
ARG JAVA_AGENT_REPO=elastic/apm-agent-java

WORKDIR /usr/src/java-app

#pull down the agent
WORKDIR /usr/src/java-agent-code
RUN curl -L https://oss.sonatype.org/service/local/artifact/maven/redirect?r=snapshots&g=co.elastic.apm&a=elastic-apm-agent&v=LATEST
# RUN mvn -q -B package -DskipTestss
# RUN export JAVA_AGENT_BUILT_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec) \
    # && cp -v /usr/src/java-agent-code/elastic-apm-agent/target/elastic-apm-agent-${JAVA_AGENT_BUILT_VERSION}.jar /usr/src/java-app/elastic-apm-agent.jar

#Bring the latest frontend code
COPY --from=opbeans/opbeans-frontend:latest /app/build src/main/resources/public

#build the application
ADD . /usr/src/java-code
WORKDIR /usr/src/java-code/opbeans

RUN mvn -q -B package -DskipTests
RUN cp -v /usr/src/java-code/opbeans/target/*.jar /usr/src/java-app/app.jar

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
