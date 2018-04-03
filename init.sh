#!/bin/sh
DEMO="Install Demo"
AUTHORS="Red Hat"
PROJECT="git@github.com:jbossdemocentral/rhbam7-install-demo.git"
PRODUCT="Red Hat Business Automation Manager"
TARGET=./target
JBOSS_HOME=$TARGET/jboss-eap-7.1
SERVER_DIR=$JBOSS_HOME/standalone/deployments
SERVER_CONF=$JBOSS_HOME/standalone/configuration/
SERVER_BIN=$JBOSS_HOME/bin
SRC_DIR=./installs
SUPPORT_DIR=./support
BA_BUSINESS_CENTRAL=rhba-7.0.0.ER2-business-central-eap7-deployable.zip
BA_KIE_SERVER=rhba-7.0.0.ER2-kie-server-ee7.zip
EAP=jboss-eap-7.1.0.zip
#EAP_PATCH=jboss-eap-6.4.7-patch.zip
VERSION=7.0

# wipe screen.
clear

echo
echo "#################################################################"
echo "##                                                             ##"
echo "##  Setting up the ${DEMO}       ##"
echo "##                                                             ##"
echo "##                                                             ##"
echo "##     ####  #   # ####    #   #   #####    #####              ##"
echo "##     #   # #   # #   #  # # # #     #     #   #              ##"
echo "##     ####  ##### #   #  #  #  #   ###     #   #              ##"
echo "##     # #   #   # #   #  #     #   #       #   #              ##"
echo "##     #  #  #   # ####   #     #  #     #  #####              ##"
echo "##                                                             ##"
echo "##  brought to you by,                                         ##"
echo "##             ${AUTHORS}                                         ##"
echo "##                                                             ##"
echo "##                                                             ##"
echo "##  ${PROJECT}      ##"
echo "##                                                             ##"
echo "#################################################################"
echo

# make some checks first before proceeding.
if [ -r $SRC_DIR/$EAP ] || [ -L $SRC_DIR/$EAP ]; then
	 echo Product sources are present...
	 echo
else
	echo Need to download $EAP package from http://developers.redhat.com
	echo and place it in the $SRC_DIR directory to proceed...
	echo
	exit
fi

#if [ -r $SRC_DIR/$EAP_PATCH ] || [ -L $SRC_DIR/$EAP_PATCH ]; then
#	echo Product patches are present...
#	echo
#else
#	echo Need to download $EAP_PATCH package from the Customer Portal
#	echo and place it in the $SRC_DIR directory to proceed...
#	echo
#	exit
#fi

if [ -r $SRC_DIR/$BA_BUSINESS_CENTRAL ] || [ -L $SRC_DIR/$BA_BUSINESS_CENTRAL ]; then
		echo Product sources are present...
		echo
else
		echo Need to download $BA_BUSINESS_CENTRAL zip from http://developers.redhat.com
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

#if [ -r $SRC_DIR/$BA_MONITORINGL ] || [ -L $SRC_DIR/$BA_MONITORING ]; then
#		echo Product sources are present...
#		echo
#else
#		echo Need to download $BA_MONITORING zip from http://developers.redhat.com
#		echo and place it in the $SRC_DIR directory to proceed...
#		echo
#		exit
#fi

if [ -r $SRC_DIR/$BA_KIE_SERVER ] || [ -L $SRC_DIR/$BA_KIE_SERVER ]; then
		echo Product sources are present...
		echo
else
		echo Need to download $BA_KIE_SERVER zip from http://developers.redhat.com
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

# Remove the old JBoss instance, if it exists.
if [ -x $JBOSS_HOME ]; then
	echo "  - removing existing JBoss product..."
	echo
	rm -rf $JBOSS_HOME
fi

# Run installers.
echo "Provisioning JBoss EAP now..."
echo
unzip -qo $SRC_DIR/$EAP -d $TARGET

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during JBoss EAP installation!
	exit
fi

#echo
#echo "Applying JBoss EAP 6.4.7 patch now..."
#echo
#$JBOSS_HOME/bin/jboss-cli.sh --command="patch apply $SRC_DIR/$EAP_PATCH"
#
#if [ $? -ne 0 ]; then
#	echo
#	echo Error occurred during JBoss EAP patching!
#	exit
#fi

echo
echo "Deploying Red Hat Business Automation Manager: Business Central now..."
echo
unzip -qo $SRC_DIR/$BA_BUSINESS_CENTRAL -d $TARGET

if [ $? -ne 0 ]; then
	echo Error occurred during $PRODUCT installation
	exit
fi

echo
echo "Deploying Red Hat Business Automation Manager: Process Server now..."
echo
unzip -qo $SRC_DIR/$BA_KIE_SERVER -d $SERVER_DIR

if [ $? -ne 0 ]; then
	echo Error occurred during $PRODUCT installation
	exit
fi
touch $SERVER_DIR/kie-server.war.dodeploy



echo
echo "  - enabling demo accounts setup..."
echo
$JBOSS_HOME/bin/add-user.sh -a -r ApplicationRealm -u bamAdmin -p redhatbam1! -ro analyst,admin,manager,user,kie-server,kiemgmt,rest-all --silent
$JBOSS_HOME/bin/add-user.sh -a -r ApplicationRealm -u kieserver -p kieserver1! -ro kie-server --silent


#echo "  - setting up standalone.xml configuration adjustments..."
#echo
#cp $SUPPORT_DIR/standalone-full.xml $SERVER_CONF/standalone.xml

echo "  - setup email notification users..."
echo
cp $SUPPORT_DIR/userinfo.properties $SERVER_DIR/business-central.war/WEB-INF/classes/

# Add execute permissions to the standalone.sh script.
echo "  - making sure standalone.sh for server is executable..."
echo
chmod u+x $JBOSS_HOME/bin/standalone.sh

echo "You can now start the $PRODUCT with $SERVER_BIN/standalone.sh"
echo
echo "Login to http://localhost:8080/business-central   (u:bamAdmin / p:redhatbam1!)"
echo

echo "$PRODUCT $VERSION $DEMO Setup Complete."
echo
