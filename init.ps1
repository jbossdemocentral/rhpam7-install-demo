
# wipe screen
Clear-Host

$PROJECT_HOME = $PSScriptRoot
$DEMO="Install Demo"
$AUTHORS="Red Hat"
$PROJECT="git@github.com:jbossdemocentral/rhdm7-install-demo.git"
$PRODUCT="Red Hat Decision Manager"
$TARGET="$PROJECT_HOME\target"
$JBOSS_HOME="$TARGET\jboss-eap-7.1"
$SERVER_DIR="$JBOSS_HOME\standalone\deployments\"
$SERVER_CONF="$JBOSS_HOME\standalone\configuration\"
$SERVER_BIN="$JBOSS_HOME\bin"
$SRC_DIR="$PROJECT_HOME\installs"
$SUPPORT_DIR="$PROJECT_HOME\support"
$PRJ_DIR="$PROJECT_HOME\projects"
$DM_DECISION_CENTRAL="rhdm-7.0.0.GA-decision-central-eap7-deployable.zip"
$DM_KIE_SERVER="rhdm-7.0.0.GA-kie-server-ee7.zip"
$EAP="jboss-eap-7.1.0.zip"
#$EAP_PATCH="jboss-eap-6.4.7-patch.zip"
$VERSION="7.0"

set NOPAUSE=true

Write-Host "#################################################################"
Write-Host "##                                                             ##"
Write-Host "##  Setting up the ${DEMO}       ##"
Write-Host "##                                                             ##"
Write-Host "##                                                             ##"
Write-Host "##     ####  #   # ####    #   #   #####    #####              ##"
Write-Host "##     #   # #   # #   #  # # # #     #     #   #              ##"
Write-Host "##     ####  ##### #   #  #  #  #   ###     #   #              ##"
Write-Host "##     # #   #   # #   #  #     #   #       #   #              ##"
Write-Host "##     #  #  #   # ####   #     #  #     #  #####              ##"
Write-Host "##                                                             ##"
Write-Host "##  brought to you by,                                         ##"
Write-Host "##             %AUTHORS%                                         ##"
Write-Host "##                                                             ##"
Write-Host "##                                                             ##"
Write-Host "##  %PROJECT%      ##"
Write-Host "##                                                             ##"
Write-Host "#################################################################`n"


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

If (Test-Path "$SRC_DIR\$DM_DECISION_CENTRAL") {
	Write-Host "Product sources are present...`n"
} Else {
	Write-Host "Need to download $DM_DECISION_CENTRAL package from the Customer Support Portal"
	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
	exit
}

If (Test-Path "$SRC_DIR\$DM_KIE_SERVER") {
	Write-Host "Product sources are present...`n"
} Else {
	Write-Host "Need to download $DM_KIE_SERVER package from the Customer Support Portal"
	Write-Host "and place it in the $SRC_DIR directory to proceed...`n"
	exit
}

#Test whether Java is available.
#if ((Get-Command "java.exe" -ErrorAction SilentlyContinue) -eq $null)
#{
#   Write-Host "The 'java' command is required but not available. Please install Java and add it to your PATH.`n"
#   exit
#}

#if ((Get-Command "javac.exe" -ErrorAction SilentlyContinue) -eq $null)
#{
#   Write-Host "The 'javac' command is required but not available. Please install Java and add it to your PATH.`n"
#   exit
#}

# Test whether 7Zip is available.
# We use 7Zip because it seems to be one of the few ways to extract the BRMS zip file without hitting the 260 character limit problem of the Windows API.
# This is definitely not ideal, but I can't unzip without problems when using the default Powershell unzip utilities.
# 7-Zip can be downloaded here: http://www.7-zip.org/download.html
if ((Get-Command "7z.exe" -ErrorAction SilentlyContinue) -eq $null)
{
   Write-Host "The '7z.exe' command is required but not available. Please install 7-Zip.`n"
	 Write-Host "7-Zip is used to overcome the Windows 260 character limit on paths while extracting the Red Hat Decision Manager ZIP file.`n"
	 Write-Host "7-Zip can be donwloaded here: http://www.7-zip.org/download.html`n"
	 Write-Host "Please make sure to add '7z.exe' to your 'PATH' after installation.`n"
   exit
}

# Remove the old installation if it exists
If (Test-Path "$JBOSS_HOME") {
	Write-Host "Removing existing installation.`n"
	# The "\\?\" prefix is a trick to get around the 256 path-length limit in Windows.
	# If we don't do this, the Remove-Item command fails when it tries to delete files with a name longer than 256 characters.
	Remove-Item "\\?\$JBOSS_HOME" -Force -Recurse
}

#Run installers.
Write-Host "Deploying JBoss EAP now..."
# Using 7-Zip. This currently seems to be the only way to overcome the Windows 260 character path limit.
$argList = "x -o$TARGET -y $SRC_DIR\$EAP"
$unzipProcess = (Start-Process -FilePath 7z.exe -ArgumentList $argList -Wait -PassThru -NoNewWindow)

If ($unzipProcess.ExitCode -ne 0) {
	Write-Error "Error occurred during JBoss EAP installation."
	exit
}


<#
Write-Host "Applying JBoss EAP patch now...`n"
Write-Host "The patch process will run in a separate window. Please wait for the 'Press any key to continue ...' message...`n"
$argList = '--command="patch apply ' + "$SRC_DIR\$EAP_PATCH" + ' --override-all"'
$patchProcess = (Start-Process -FilePath "$JBOSS_HOME\bin\jboss-cli.bat" -ArgumentList $argList -Wait -PassThru)
Write-Host "Process finished with return code: " $patchProcess.ExitCode
Write-Host ""

If ($patchProcess.ExitCode -ne 0) {
	Write-Error "Error occurred during JBoss EAP patch installation."
	exit
}

Write-Host "JBoss EAP patch applied succesfully!`n"
#>

Write-Host "Deploying Decision Manager Decision Central now..."
# Using 7-Zip. This currently seems to be the only way to overcome the Windows 260 character path limit.
$argList = "x -o$TARGET -y $SRC_DIR\$DM_DECISION_CENTRAL"
$unzipProcess = (Start-Process -FilePath 7z.exe -ArgumentList $argList -Wait -PassThru -NoNewWindow)

If ($unzipProcess.ExitCode -ne 0) {
	Write-Error "Error occurred during Decision Manager Decision Central installation."
	exit
}

Write-Host "Deploying Decision Manager Decision Server now..."
# Using 7-Zip. This currently seems to be the only way to overcome the Windows 260 character path limit.
$argList = "x -o$JBOSS_HOME\standalone\deployments -y $SRC_DIR\$DM_KIE_SERVER"
$unzipProcess = (Start-Process -FilePath 7z.exe -ArgumentList $argList -Wait -PassThru -NoNewWindow)

If ($unzipProcess.ExitCode -ne 0) {
	Write-Error "Error occurred during Decision Manager Decision Server installation."
	exit
}
New-Item -ItemType file $JBOSS_HOME\standalone\deployments\kie-server.war.dodeploy
Write-Host ""

Write-Host "- enabling demo accounts setup ...`n"
$argList1 = "-a -r ApplicationRealm -u dmAdmin -p 'redhatdm1!' -ro 'analyst,admin,manager,user,kie-server,kiemgmt,rest-all' --silent"
$argList2 = "-a -r ApplicationRealm -u kieserver -p 'kieserver1!' -ro 'kie-server' --silent"
try {
	Invoke-Expression "$JBOSS_HOME\bin\add-user.ps1 $argList1"
  Invoke-Expression "$JBOSS_HOME\bin\add-user.ps1 $argList2"
} catch {
	Write-Error "Error occurred during user account setup."
	exit
}

Write-Host "- setting up standalone.xml configuration adjustments...`n"
Copy-Item "$SUPPORT_DIR\standalone-full.xml" "$SERVER_CONF\standalone.xml" -force

Write-Host "- setup email task notification user...`n"
Copy-Item "$SUPPORT_DIR\userinfo.properties" "$SERVER_DIR\decision-central.war\WEB-INF\classes\" -force

Write-Host "============================================================================"
Write-Host "=                                                                          ="
Write-Host "=  You can now start the $PRODUCT with:                             ="
Write-Host "=                                                                          ="
Write-Host "=   $SERVER_BIN\standalone.ps1                          ="
Write-Host "=       or                                                                   ="
Write-Host "=   $SERVER_BIN\standalone.bat                          ="
Write-Host "=                                                                          ="
Write-Host "=  Login into business central at:                                         ="
Write-Host "=                                                                          ="
Write-Host "=    http://localhost:8080/decision-central  (u:dmAdmin / p:redhatdm1!)    ="
Write-Host "=                                                                          ="
Write-Host "=  See README.md for general details to run the various demo cases.        ="
Write-Host "=                                                                          ="
Write-Host "=  $PRODUCT $VERSION $DEMO Setup Complete.                  ="
Write-Host "=                                                                          ="
Write-Host "============================================================================"
