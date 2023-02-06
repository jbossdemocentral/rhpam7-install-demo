#!/bin/bash
DEMO="Install Demo"
PROJECT="git@github.com:jbossdemocentral/rhpam7-install-demo.git"
PRODUCT="Red Hat Process Automation Manager"
JBOSS_HOME=./target/jboss-eap-7.4
SERVER_DIR=$JBOSS_HOME/standalone/deployments
SERVER_CONF=$JBOSS_HOME/standalone/configuration/
SERVER_BIN=$JBOSS_HOME/bin
SRC_DIR=./installs
SUPPORT_DIR=./support
PRJ_DIR=./projects
VERSION_EAP=7.4.0
VERSION_EAP_PATCH=7.4.6
VERSION=7.13.0
EAP=jboss-eap-$VERSION_EAP.zip
EAP_PATCH=jboss-eap-$VERSION_EAP_PATCH-patch.zip
RHPAM=rhpam-$VERSION-business-central-eap7-deployable.zip
RHPAM_KIE_SERVER=rhpam-$VERSION-kie-server-ee8.zip
RHPAM_ADDONS=rhpam-$VERSION-add-ons.zip
RHPAM_CASE=rhpam-$VERSION-case-mgmt-showcase-eap7-deployable.zip
RHPAM_UPDATE=rhpam-$VERSION-update

# wipe screen.
clear

echo
echo "###################################################################"
echo "##                                                               ##"
echo "##  Setting up the                                               ##"
echo "##                                                               ##"
echo "##             ####  ##### ####     #   #  ###  #####            ##"
echo "##             #   # #     #   #    #   # #   #   #              ##"
echo "##             ####  ###   #   #    ##### #####   #              ##"
echo "##             #  #  #     #   #    #   # #   #   #              ##"
echo "##             #   # ##### ####     #   # #   #   #              ##"
echo "##                                                               ##"
echo "##           ####  ####   ###   #### #####  ####  ####           ##"
echo "##           #   # #   # #   # #     #     #     #               ##"
echo "##           ####  ####  #   # #     ###    ###   ###            ##"
echo "##           #     #  #  #   # #     #         #     #           ##"
echo "##           #     #   #  ###   #### ##### ####  ####            ##"
echo "##                                                               ##"
echo "##   ###  #   # #####  ###  #   #  ###  ##### #####  ###  #   #  ##"
echo "##  #   # #   #   #   #   # ## ## #   #   #     #   #   # ##  #  ##"
echo "##  ##### #   #   #   #   # # # # #####   #     #   #   # # # #  ##"
echo "##  #   # #   #   #   #   # #   # #   #   #     #   #   # #  ##  ##"
echo "##  #   # #####   #    ###  #   # #   #   #   #####  ###  #   #  ##"
echo "##                                                               ##"
echo "##           #   #  ###  #   #  ###  ##### ##### ####            ##"
echo "##           ## ## #   # ##  # #   # #     #     #   #           ##"
echo "##           # # # ##### # # # ##### #  ## ###   ####            ##"
echo "##           #   # #   # #  ## #   # #   # #     #  #            ##"
echo "##           #   # #   # #   # #   # ##### ##### #   #           ##"
echo "##                                                               ##"
echo "##                                                               ##"
echo "##  ${PROJECT}      ##"
echo "##                                                               ##"
echo "###################################################################"
echo

# Validate that the system is ready for installation.
echo "Testing Java runtime engine (JRE) availability..."
if type -p java; then
    echo "  - Java executable found in PATH"
    export _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo "  - Java executable found in JAVA_HOME"  
    export _java="$JAVA_HOME/bin/java"
else
    echo "No java runtine availabie!"
	echo "Please configure your system path and $JAVA_HOME environment before continuing."
	echo
	exit
fi

echo "Testing Java version..."
if [[ "$_java" ]]; then
    export _java_version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
	echo "  - JAVA is version ${_java_version}"
	# See: https://stackoverflow.com/a/7335524
	export _java_version_numeric=$(echo "$_java_version" | awk -F. '{printf("%03d%03d",$1,$2);}')
    if [ $_java_version_numeric -ge 001008 ] && [ $_java_version_numeric -le 011000 ]  ; then
        echo "  - Java version is compatible with RHPAM"
		echo
    else         
        echo "  - Java version is incompatible with RHPAM!"
		echo "    Please configure your Java environment before continuing with installation"
		echo "    More information at https://access.redhat.com/articles/3405381"
		echo
		exit
    fi
fi

# Verify that the support directory is available at the expected path
if [ -r $SUPPORT_DIR ] || [ -L $SUPPORT_DIR ]; then
        echo "Support dir is available..."
        echo
else
        echo "$SUPPORT_DIR wasn't found. Please make sure to run this script inside the demo directory."
        echo
        exit
fi

if [ -r $SRC_DIR/$EAP ] || [ -L $SRC_DIR/$EAP ]; then
	echo "EAP product sources are downloaded and present..."
else
	echo "Product sources for $EAP package not found."
	echo "Please follow the download instructions in README.md,"
	echo "found in the $SRC_DIR directory to proceed..."
	echo
	exit
fi

if [ -r $SRC_DIR/$EAP_PATCH ] || [ -L $SRC_DIR/$EAP_PATCH ]; then
	echo "EAP patch sources are downloaded and present..."
else
	echo "Product sources for $EAP_PATCH package not found."
	echo "Please follow the download instructions in README.md,"
	echo "found in the $SRC_DIR directory to proceed..."
	echo
	exit
fi

if [ -r $SRC_DIR/$RHPAM ] || [ -L $SRC_DIR/$RHPAM ]; then
	echo "RHPAM product sources are downloaded and present..."
else
	echo "Product sources for $RHPAM package not found."
	echo "Please follow the download instructions in README.md,"
	echo "found in the $SRC_DIR directory to proceed..."
	echo
	exit
fi

if [ -r $SRC_DIR/$RHPAM_KIE_SERVER ] || [ -L $SRC_DIR/$RHPAM_KIE_SERVER ]; then
	echo "Product Red Hat Process Automation Manager KIE Server sources are present..."
else
	echo "Product sources for $RHPAM_KIE_SERVER package not found."
	echo "Please follow the download instructions in README.md,"
	echo "found in the $SRC_DIR directory to proceed..."
	echo
	exit
fi

if [ -r $SRC_DIR/$RHPAM_ADDONS ] || [ -L $SRC_DIR/$RHPAM_ADDONS ]; then
	echo "Product Red Hat Process Automation Manager Case Management sources are present..."
	echo
else
	echo "Product sources for $RHPAM_ADDONS package not found."
	echo "Please follow the download instructions in README.md,"
	echo "found in the $SRC_DIR directory to proceed..."
	echo
	exit
fi

# Remove the old JBoss instance, if it exists.
if [ -x $JBOSS_HOME ]; then
		echo "Removing existing installation from $JBOSS_HOME..."
		echo
		rm -rf $JBOSS_HOME
fi

# JBoss EAP Installation.
echo "Extracting JBoss EAP ${VERSION_EAP}..."
echo
mkdir -p ./target
unzip -qo $SRC_DIR/$EAP -d target

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during JBoss EAP extraction!
	exit
fi

echo "Patching the JBoss EAP installation to ${VERSION_EAP_PATCH}..."
echo
$JBOSS_HOME/bin/jboss-cli.sh "patch apply $SRC_DIR/jboss-eap-7.4.6-patch.zip"
echo

if [ $? -ne 0 ]; then
	echo
	echo Error occurred while patching JBoss EAP!
	exit
fi

# RHPAM Installation.
echo "Extracting Red Hat Process Automation Manager..."
echo
unzip -qo $SRC_DIR/$RHPAM -d target

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during Red Hat Process Manager extraction!
	exit
fi

echo "Extracting Red Hat Process Automation Manager - Kie Server..."
echo
unzip -qo $SRC_DIR/$RHPAM_KIE_SERVER  -d $JBOSS_HOME/standalone/deployments
touch $JBOSS_HOME/standalone/deployments/kie-server.war.dodeploy

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during Red Hat Process Manager Kie Server installation!
	exit
fi

echo "Extracting Red Hat Process Automation Manager - Case Management Showcase..."
echo
unzip -qo $SRC_DIR/$RHPAM_ADDONS $RHPAM_CASE -d $SRC_DIR
unzip -qo $SRC_DIR/$RHPAM_CASE -d target
rm $SRC_DIR/$RHPAM_CASE
touch $JBOSS_HOME/standalone/deployments/rhpam-case-mgmt-showcase.war.dodeploy

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during Red Hat Process Manager Case Management installation!
	exit
fi

echo "  - setting up standalone.xml configuration adjustments..."
echo
mv $SERVER_CONF/standalone.xml $SERVER_CONF/standalone-original.xml
cp $SERVER_CONF/standalone-full.xml $SERVER_CONF/standalone.xml

echo "  - setting up data storage folders..."
echo
$JBOSS_HOME/bin/jboss-cli.sh --file=$SUPPORT_DIR/data_folders.cli
echo

echo "  - enabling the KIE Server to be managed by Business Central..."
echo
$JBOSS_HOME/bin/jboss-cli.sh --file=$SUPPORT_DIR/managed_kie.cli
echo

# Create our demo user accounts
echo "  - setting up demo user accounts and roles..."
echo
# Optional - uncomment the line below to use the file system instead of property files
# $JBOSS_HOME/bin/elytron-tool.sh filesystem-realm --users-file application-users.properties --roles-file application-roles.properties --output-location kie-fs-realm-users
$JBOSS_HOME/bin/jboss-cli.sh --file=$SUPPORT_DIR/user_data.cli
echo

# Setting up Setup LDAP based authentication in JBoss EAP 7.1 or later using Elytron 
# See https://access.redhat.com/solutions/3220741

# TODO

# Elytron Failover Realm allows to failover the Identity Lookup to another Identity Store in case of a failure
# See https://access.redhat.com/solutions/6290451

# TODO

echo "  - provisioning email task notification users..."
echo
cp $SUPPORT_DIR/userinfo.properties $SERVER_DIR/business-central.war/WEB-INF/classes/

echo "  - setup system property for jpa marshaller"
echo
$JBOSS_HOME/bin/jboss-cli.sh <<EOT
embed-server --std-out=echo
/system-property=org.kie.server.xstream.enabled.packages:add(value="org.drools.persistence.jpa.marshaller.*")
EOT
echo

# Add execute permissions to the standalone.sh script.
echo "  - making sure standalone.sh for server is executable..."
echo
chmod u+x $JBOSS_HOME/bin/standalone.sh

echo "=============================================================="
echo "=                                                            ="
echo "=  $PRODUCT $VERSION setup complete. ="
echo "=                                                            ="
echo "=  Start $PRODUCT with:            ="
echo "=                                                            ="
echo "=           $SERVER_BIN/standalone.sh         ="
echo "=                                                            ="
echo "=  Log in to Red Hat Process Automation Manager to start     ="
echo "=  developing rules projects:                                ="
echo "=                                                            ="
echo "=  http://localhost:8080/business-central                    ="
echo "=                                                            ="
echo "=    Log in: [ u:pamAdmin / p:redhatpam1! ]                  ="
echo "=                                                            ="
echo "=  http://localhost:8080/rhpam-case-mgmt-showcase            ="
echo "=  http://localhost:8080/kie-server/docs                     =" 
echo "=                                                            ="
echo "=    Others:                                                 ="
echo "=            [ u:kieserver / p:kieserver1! ]                 ="
echo "=            [ u:caseUser / p:redhatpam1! ]                  ="
echo "=            [ u:caseManager / p:redhatpam1! ]               ="
echo "=            [ u:caseSupplier / p:redhatpam1! ]              ="
echo "=                                                            ="
echo "=============================================================="
echo