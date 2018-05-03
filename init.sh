#!/bin/sh
# fallback product versions
EAP_VERSION=7.1.0
PAM_VERSION=7.0.0.ER4
# optionally override default versions (any EAP 7.1.x + PAM 7.0.x will do)
while getopts ":e:p:" opt; do
  case $opt in
   e) EAP_VERSION=$OPTARG
      echo "Overriding EAP version with $EAP_VERSION" >&2
      ;;
   p) PAM_VERSION=$OPTARG
      echo "Overriding PAM version with $PAM_VERSION" >&2
      ;;
   \?) echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
DEMO="Install Demo"
AUTHORS="Red Hat"
PROJECT="git@github.com:jbossdemocentral/rhpam7-install-demo.git"
PRODUCT="Red Hat Process Automation Manager"
TARGET=./target
JBOSS_HOME=$TARGET/jboss-eap-7.1
SERVER_DIR=$JBOSS_HOME/standalone/deployments
SERVER_CONF=$JBOSS_HOME/standalone/configuration/
SERVER_BIN=$JBOSS_HOME/bin
SRC_DIR=./installs
SUPPORT_DIR=./support
PAM_BUSINESS_CENTRAL=rhpam-$PAM_VERSION-business-central-eap7-deployable.zip
PAM_KIE_SERVER=rhpam-$PAM_VERSION-kie-server-ee7.zip
PAM_ADDONS=rhpam-$PAM_VERSION-add-ons.zip
PAM_CASE_MGMT=rhpam-7.0-case-mgmt-showcase-eap7-deployable.zip
EAP=jboss-eap-$EAP_VERSION.zip
#EAP_PATCH=jboss-eap-6.4.7-patch.zip
VERSION=7.0

# wipe screen.
clear

echo
echo "######################################################################"
echo "##                                                                  ##"
echo "##  Setting up the ${DEMO}                                 ##"
echo "##                                                                  ##"
echo "##                                                                  ##"
echo "##     ####  #   # ####   ###   #   #   #####    #####              ##"
echo "##     #   # #   # #   # #   # # # # #     #     #   #              ##"
echo "##     ####  ##### ####  ##### #  #  #   ###     #   #              ##"
echo "##     # #   #   # #     #   # #     #   #       #   #              ##"
echo "##     #  #  #   # #     #   # #     #  #     #  #####              ##"
echo "##                                                                  ##"
echo "##  brought to you by,                                              ##"
echo "##             ${AUTHORS}                                              ##"
echo "##                                                                  ##"
echo "##                                                                  ##"
echo "##  ${PROJECT}         ##"
echo "##                                                                  ##"
echo "######################################################################"
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

if [ -r $SRC_DIR/$PAM_BUSINESS_CENTRAL ] || [ -L $SRC_DIR/$PAM_BUSINESS_CENTRAL ]; then
		echo Product sources are present...
		echo
else
		echo Need to download $PAM_BUSINESS_CENTRAL zip from http://developers.redhat.com
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

if [ -r $SRC_DIR/$PAM_KIE_SERVER ] || [ -L $SRC_DIR/$PAM_KIE_SERVER ]; then
		echo Product sources are present...
		echo
else
		echo Need to download $PAM_KIE_SERVER zip from http://developers.redhat.com
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

if [ -r $SRC_DIR/$PAM_ADDONS ] || [ -L $SRC_DIR/PAM_ADDONS ]; then
		echo Product sources are present...
		echo
else
		echo Need to download $PAM_ADDONS zip from http://developers.redhat.com
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
echo "Deploying Red Hat Process Automation Manager: Business Central now..."
echo
unzip -qo $SRC_DIR/$PAM_BUSINESS_CENTRAL -d $TARGET

if [ $? -ne 0 ]; then
	echo Error occurred during $PRODUCT installation
	exit
fi

echo
echo "Deploying Red Hat Process Automation Manager: Process Server now..."
echo
unzip -qo $SRC_DIR/$PAM_KIE_SERVER -d $SERVER_DIR

if [ $? -ne 0 ]; then
	echo Error occurred during $PRODUCT installation
	exit
fi
touch $SERVER_DIR/kie-server.war.dodeploy

echo
echo "Deploying Red Hat Process Automation Manager: Case Management Showcase now..."
echo
unzip -qo $SRC_DIR/$PAM_ADDONS $PAM_CASE_MGMT -d $TARGET
unzip -qo $TARGET/$PAM_CASE_MGMT -d $TARGET
rm $TARGET/$PAM_CASE_MGMT
if [ $? -ne 0 ]; then
	echo Error occurred during $PRODUCT installation
	exit
fi
touch $SERVER_DIR/rhpam-case-mgmt-showcase.war.dodeploy

echo
echo "  - enabling demo accounts setup..."
echo
$JBOSS_HOME/bin/add-user.sh -a -r ApplicationRealm -u pamAdmin -p redhatpam1! -ro analyst,admin,manager,user,kie-server,kiemgmt,rest-all --silent
$JBOSS_HOME/bin/add-user.sh -a -r ApplicationRealm -u kieserver -p kieserver1! -ro kie-server --silent


echo "  - setting up standalone.xml configuration adjustments..."
echo
cp $SUPPORT_DIR/standalone-full.xml $SERVER_CONF/standalone.xml

echo "  - setup email notification users..."
echo
cp $SUPPORT_DIR/userinfo.properties $SERVER_DIR/business-central.war/WEB-INF/classes/

# Add execute permissions to the standalone.sh script.
echo "  - making sure standalone.sh for server is executable..."
echo
chmod u+x $JBOSS_HOME/bin/standalone.sh

echo "You can now start the $PRODUCT with $SERVER_BIN/standalone.sh"
echo
echo "Login to http://localhost:8080/business-central   (u:pamAdmin / p:redhatpam1!)"
echo
echo "Login to http://localhost:8080/rhpam-case-mgmt-showcase   (u:pamAdmin / p:redhatpam1!)"
echo

echo "$PRODUCT $VERSION $DEMO Setup Complete."
echo
