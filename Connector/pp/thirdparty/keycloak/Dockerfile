FROM quay.io/keycloak/keycloak:14.0.0
#FROM jboss/keycloak:latest 

USER jboss 

RUN sed -i -e 's/<web-context>auth<\/web-context>/<web-context>third-party\/keycloak\/auth<\/web-context>/' $JBOSS_HOME/standalone/configuration/standalone-ha.xml 
