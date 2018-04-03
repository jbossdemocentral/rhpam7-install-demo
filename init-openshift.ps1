if ((Get-Command "oc" -ErrorAction SilentlyContinue) -eq $null)
{
   Write-Output "The oc client tools need to be installed to connect to OpenShift."
   Write-Output "Download it from https://www.openshift.org/download.html and confirm that ""oc version"" runs.`n"
   exit
}

Function Write-Host-Header($echo) {
  Write-Output ""
  Write-Output "########################################################################"
  Write-Output "$echo"
  Write-Output "########################################################################"
}

$PRJ_DEMO="rhdm7-install"
$PRJ_DEMO_NAME=((./support/openshift/provision.ps1 info $PRJ_DEMO 2>&1 | Select-String -Pattern "Project name") -split "\s+")[2]

# Check if the project exists
#oc get project $PRJ_DEMO_NAME > $null 2>&1
oc get project $PRJ_DEMO_NAME > $null 2>&1
$PRJ_EXISTS=$?

if ($PRJ_EXISTS) {
  Write-Output "$PRJ_DEMO_NAME already exists. Deleting project."
  ./support/openshift/provision.ps1 -command delete -demo $PRJ_DEMO

  # Wait until the project has been removed.
  Write-Output "Waiting for OpenShift to clean deleted project."
  Start-Sleep -s 20
}

Write-Output "Provisioning Red Hat Decision Manager 7 Install Demo."
./support/openshift/provision.ps1 -command setup -demo $PRJ_DEMO -with-imagestreams
Write-Output "Setup completed."
