
# wipe screen
Clear-Host

$PROJECT_HOME = $PSScriptRoot
$DEMO="Install Demo"
$AUTHORS="Red Hat"
$PROJECT="git@github.com:jbossdemocentral/rhpam7-install-demo.git"
$PRODUCT="Red Hat Process Automation Manager"
$SRC_DIR="$PROJECT_HOME\installs"
$SUPPORT_DIR="$PROJECT_HOME\support"
$PAM_VERSION="7.0.0"
$PAM_BUSINESS_CENTRAL="rhpam-$PAM_VERSION-business-central-eap7-deployable.zip"
$PAM_KIE_SERVER="rhpam-$PAM_VERSION-kie-server-ee7.zip"
$PAM_ADDONS=rhpam-$PAM_VERSION-add-ons.zip
$EAP="jboss-eap-7.1.0.zip"
$VERSION="7.0"

set NOPAUSE=true

Write-Host "######################################################################"
Write-Host "##                                                                  ##"
Write-Host "##  Setting up the ${DEMO}            ##"
Write-Host "##                                                                  ##"
Write-Host "##                                                                  ##"
Write-Host "##     ####  #   # ####   ###   #   #   #####    #####              ##"
Write-Host "##     #   # #   # #   # #   # # # # #     #     #   #              ##"
Write-Host "##     ####  ##### ####  ##### #  #  #   ###     #   #              ##"
Write-Host "##     # #   #   # #     #   # #     #   #       #   #              ##"
Write-Host "##     #  #  #   # #     #   # #     #  #     #  #####              ##"
Write-Host "##                                                                  ##"
Write-Host "##  brought to you by,                                              ##"
Write-Host "##             %AUTHORS%                                             ##"
Write-Host "##                                                                  ##"
Write-Host "##                                                                  ##"
Write-Host "##  %PROJECT%           ##"
Write-Host "##                                                                  ##"
Write-Host "######################################################################`n"


If (Test-Path "$SRC_DIR\$EAP") {
	Write-Host "Product sources are present...`n"
} Else {
	Write-Host "Need to download $EAP package from the Customer Support Portal"
	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
	exit
}

#If (Test-Path "$SRC_DIR\$EAP_PATCH") {
#	Write-Host "Product patches are present...`n"
#} Else {
#	Write-Host "Need to download $EAP_PATCH package from the Customer Support Portal"
#	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
#	exit
#}

If (Test-Path "$SRC_DIR\$_CENTRAL") {
	Write-Host "Product sources are present...`n"
} Else {
	Write-Host "Need to download $PAM_BUSINESS_CENTRAL package from the Customer Support Portal"
	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
	exit
}

If (Test-Path "$SRC_DIR\$PAM_KIE_SERVER") {
	Write-Host "Product sources are present...`n"
} Else {
	Write-Host "Need to download $PAM_KIE_SERVER package from the Customer Support Portal"
	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
	exit
}

If (Test-Path "$SRC_DIR\$PAM_ADDONS") {
	Write-Host "Product sources are present...`n"
} Else {
	Write-Host "Need to download $PAM_ADDONS package from the Customer Support Portal"
	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
	exit
}

Copy-Item "$SUPPORT_DIR\docker\Dockerfile" "$PROJECT_HOME" -force
Copy-Item "$SUPPORT_DIR\docker\.dockerignore" "$PROJECT_HOME" -force

Write-Host "Starting Docker build.`n"

$argList = "build -t jbossdemocentral/rhpam7-install-demo $PROJECT_HOME"
$process = (Start-Process -FilePath docker.exe -ArgumentList $argList -Wait -PassThru -NoNewWindow)
Write-Host "`n"

If ($process.ExitCode -ne 0) {
	Write-Error "Error occurred during Docker build!"
	exit
}

Write-Host "Docker build finished.`n"

Remove-Item "$PROJECT_HOME\Dockerfile" -Force

Write-Host "=================================================================================="
Write-Host "=                                                                                ="
Write-Host "=  You can now start the $PRODUCT in a Docker container with:              ="
Write-Host "=                                                                                ="
Write-Host "=  docker run -it -p 8080:8080 -p 9990:9990 jbossdemocentral/rhpam7-install-demo ="
Write-Host "=                                                                                ="
Write-Host "=  Login into Business Central at:                                               ="
Write-Host "=                                                                                ="
Write-Host "=    http://localhost:8080/business-central  (u:dmAdmin / p:redhatdm1!)          ="
Write-Host "=                                                                                ="
Write-Host "=  See README.md for general details to run the various demo cases.              ="
Write-Host "=                                                                                ="
Write-Host "=  $PRODUCT $VERSION $DEMO Setup Complete.                        ="
Write-Host "=                                                                                ="
Write-Host "=================================================================================="
