#!/bin/sh
. init-properties.sh

# wipe screen.
clear

echo
echo "######################################################################"
echo "##                                                                  ##"
echo "##  Setting up the ${DEMO}                                    ##"
echo "##                                                                  ##"
echo "##                                                                  ##"
echo "##     ####  #   # ####   ###   #   #   #####    #   #              ##"
echo "##     #   # #   # #   # #   # # # # #     #      # #               ##"
echo "##     ####  ##### ####  ##### #  #  #   ###       #                ##"
echo "##     # #   #   # #     #   # #     #   #        # #               ##"
echo "##     #  #  #   # #     #   # #     #  #     #  #   #              ##"
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

cp support/docker/Dockerfile .
cp support/docker/.dockerignore .

echo Starting Docker build.
echo

docker build --no-cache -t jbossdemocentral/rhpam7-mortgage-demo --build-arg PAM_VERSION=$PAM_VERSION --build-arg PAM_BUSINESS_CENTRAL=$PAM_BUSINESS_CENTRAL --build-arg PAM_KIE_SERVER=$PAM_KIE_SERVER --build-arg EAP=$EAP --build-arg PAM_ADDONS=$PAM_ADDONS --build-arg PAM_CASE_MGMT=$PAM_CASE_MGMT --build-arg JBOSS_EAP=$JBOSS_EAP .

if [ $? -ne 0 ]; then
        echo
        echo Error occurred during Docker build!
        echo Consult the Docker build output for more information.
        exit
fi

echo Docker build finished.
echo

rm Dockerfile

echo
echo "=================================================================================="
echo "=                                                                                ="
echo "=  You can now start the $PRODUCT in a Docker container with: ="
echo "=                                                                                ="
echo "=  docker run -it -p 8080:8080 -p 9990:9990 jbossdemocentral/rhpam7-install-demo ="
echo "=                                                                                ="
echo "=  Login into Business Central at:                                               ="
echo "=                                                                                ="
echo "=    http://localhost:8080/business-central  (u:pamAdmin / p:redhatpam1!)        ="
echo "=                                                                                ="
echo "=  Login into Case Management Showcase Application at:                           ="
echo "=                                                                                ="
echo "=    http://localhost:8080/rhpam-case-mgmt-showcase  (u:pamAdmin / p:redhatpam1!)="
echo "=                                                                                ="
echo "=                                                                                ="
echo "=  $PRODUCT $VERSION $DEMO Setup Complete.                  ="
echo "=                                                                                ="
echo "=================================================================================="
