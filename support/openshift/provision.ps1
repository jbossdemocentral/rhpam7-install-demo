[CmdletBinding()]
param (
    [string]$command = "",
    [string]$demo = "",
    [string]$user = "",
    [string]${project-suffix} = "",
    [string]${run-verify} = "",
    [switch]${with-imagestreams} = $true,
    [string]${pv-capacity} = "512Mi",
    [switch]$h = $false,
    [switch]$help = $false
)

#TODO Implement validation of parameters like in the bash script, for example to verify correctness of the username.

if ((Get-Command "oc" -ErrorAction SilentlyContinue) -eq $null)
{
   Write-Output "The oc client tools need to be installed to connect to OpenShift."
   Write-Output "Download it from https://www.openshift.org/download.html and confirm that ""oc version"" runs.`n"
   exit
}

$scriptName = $myInvocation.MyCommand.Name

################################################################################
# Provisioning script to deploy the demo on an OpenShift environment           #
################################################################################

Function Usage() {
  Write-Output ""
  Write-Output "Usage:"
  Write-Output " $scriptName -command [command] -demo [demo-name] [options]"
  Write-Output " $scriptName -help"
  Write-Output ""
  Write-Output "Example:"
  Write-Output " $scriptName -command setup -demo rhpam7-install -project-suffix s40d"
  Write-Output ""
  Write-Output "COMMANDS:"
  Write-Output "   setup                    Set up the demo projects and deploy demo apps"
  Write-Output "   deploy                   Deploy demo apps"
  Write-Output "   delete                   Clean up and remove demo projects and objects"
  Write-Output "   verify                   Verify the demo is deployed correctly"
  Write-Output "   idle                     Make all demo services idle"
  Write-Output ""
  Write-Output "DEMOS:"
  Write-Output "   rhpam7-install            Red Hat Process Automation Manager Install demo"
  Write-Output ""
  Write-Output "OPTIONS:"
  Write-Output "   -user [username]         The admin user for the demo projects. mandatory if logged in as system:admin"
  Write-Output "   -project-suffix [suffix] Suffix to be added to demo project names e.g. ci-SUFFIX. If empty, user will be used as suffix."
  Write-Output "   -run-verify              Run verify after provisioning"
  Write-Output "   -with-imagestreams       Creates the image streams in the project. Useful when required ImageStreams are not available in the 'openshift' namespace and cannot be provisioned in that 'namespace'."
  Write-Output "   -pv-capacity [capacity]  Capacity of the persistent volume. Defaults to 512Mi as set by the Red Hat Process Automation Manager OpenShift template."
  Write-Output ""
}

$ARG_USERNAME=$user
$ARG_PROJECT_SUFFIX=${project-suffix}
$ARG_COMMAND=$command
$ARG_RUN_VERIFY=${run-verify}
$ARG_WITH_IMAGESTREAMS=${with-imagestreams}
$ARG_PV_CAPACITY=${pv-capacity}
$ARG_DEMO=$demo

if ($h -Or $help) {
  Usage
  exit
}

$commands = "info","setup","deploy","delete","verify","idle"
if (!$commands.Contains($ARG_COMMAND)) {
  Write-Output "Error: Unrecognized command: $ARG_COMMAND"
  Write-Output "Please run '$scriptName -help' to see the list of accepted commands and options."
  exit
}

################################################################################
# Configuration                                                                #
################################################################################

$LOGGEDIN_USER=Invoke-Expression "oc whoami"
if (-not ([string]::IsNullOrEmpty($ARG_USERNAME)))
{
  $OPENSHIFT_USER = $ARG_USERNAME
} else {
  $OPENSHIFT_USER = $LOGGEDIN_USER
}

if (-not ([string]::IsNullOrEmpty($ARG_PROJECT_SUFFIX)))
{
  $PRJ_SUFFIX = $ARG_PROJECT_SUFFIX
} else {
  $PRJ_SUFFIX =  %{$OPENSHIFT_USER -creplace "[^-a-z0-9]","-"}
}

$PRJ=@("rhpam7-install-$PRJ_SUFFIX","RHPAM7 Install Demo","Red Hat Process Automation Manager 7 Install Demo")

$SCRIPT_DIR= Split-Path $myInvocation.MyCommand.Path

# KIE Parameters
$KIE_ADMIN_USER="pamAdmin"
$KIE_ADMIN_PWD="redhatpam1!"
$KIE_SERVER_CONTROLLER_USER="kieserver"
$KIE_SERVER_CONTROLLER_PWD="kieserver1!"
$KIE_SERVER_USER="kieserver"
$KIE_SERVER_PWD="kieserver1!"

# Version Configuration Parameters
$OPENSHIFT_PAM7_TEMPLATES_TAG="7.13.0.GA"
$IMAGE_STREAM_TAG="7.13.0"
$PAM7_VERSION="713"


################################################################################
# DEMO MATRIX                                                                  #
################################################################################

switch ( $ARG_DEMO )
{
  "rhpam7-install" {
    $DEMO_NAME=$($PRJ[2])
  }
  default {
    Write-Output "Error: Invalid demo name: '$ARG_DEMO'"
    Usage
    exit
  }
}

################################################################################
# Functions                                                                    #
################################################################################

Function Write-Output-Header($echo) {
  Write-Output ""
  Write-Output "########################################################################"
  Write-Output "$echo"
  Write-Output "########################################################################"
}

Function Call-Oc($command, [bool]$out, $errorMessage, [bool]$doexit) {
  try {
    if ($out) {
      oc $command.split()
    } else {
      oc $command.split() | out-null
    }
    if ($lastexitcode) {
      throw $er
    }
  } catch {
    Write-Error "$errorMessage"
    if ($doexit) {
      exit 255
    }
  }
}

Function Print-Info() {
  Write-Output-Header "Configuration"

  Invoke-Expression "oc version" | select -last 2| select -first 1 | %{$_ -cmatch ".*https://(?<url>.*)"}
  $OPENSHIFT_MASTER=$matches['url']

  Write-Output "Demo name:        $ARG_DEMO"
  Write-Output "Project name:     $($PRJ[0])"
  Write-Output "OpenShift master: $OPENSHIFT_MASTER"
  Write-Output "Current user:     $LOGGEDIN_USER"
  Write-Output "Project suffix:   $PRJ_SUFFIX"
}

Function Pre-Condition-Check() {
  Write-Output-Header "Checking pre-conditions"
}

# waits while the condition is true until it becomes false or it times out
Function Wait-While-Empty($name, $timeout, $condition) {
  #TODO: Implement
}

<#
function wait_while_empty() {
  local _NAME=$1
  local _TIMEOUT=$(($2/5))
  local _CONDITION=$3

  echo "Waiting for $_NAME to be ready..."
  local x=1
  while [ -z "$(eval ${_CONDITION})" ]
  do
    echo "."
    sleep 5
    x=$(( $x + 1 ))
    if [ $x -gt $_TIMEOUT ]
    then
      echo "$_NAME still not ready, I GIVE UP!"
      exit 255
    fi
  done

  echo "$_NAME is ready."
}
#>

Function Create-Projects() {
    Write-Output-Header "Creating project..."

    Write-Output-Header "Creating project $($PRJ[0])"
    $argList = "new-project ""$($PRJ[0])"" --display-name=""$($PRJ[1])"" --description=""$($PRJ[2])"""

    Call-Oc $argList $False "Error occurred during project creation." $True
}

Function Import-ImageStreams-And-Templates() {
  Write-Output-Header "Importing Image Streams"
  Call-Oc "create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/rhpam$PAM7_VERSION-image-streams.yaml" $True "Error importing Image Streams" $True

  Write-Output ""
  Write-Output "Fetching ImageStreams from registry."

  Start-Sleep -s 10

  #  Explicitly import the images. This is to overcome a problem where the image import gets a 500 error from registry.redhat.io when we deploy multiple containers at once.
  Call-Oc "import-image rhpam-businesscentral-rhel8:$IMAGE_STREAM_TAG —confirm -n $($PRJ[0])" $True "Error fetching Image Streams."
  Call-Oc "import-image rhpam-kieserver-rhel8:$IMAGE_STREAM_TAG —confirm -n $($PRJ[0])" $True "Error fetching Image Streams."

  #Write-Output-Header "Patching the ImageStreams"
  #oc patch is/rhpam74-businesscentral-openshift --type='json' -p "[{'op': 'replace', 'path': '/spec/tags/0/from/name', 'value': 'registry.access.redhat.com/rhpam-7/rhpam74-businesscentral-openshift:1.0'}]"
  #oc patch is/rhpam74-kieserver-openshift --type='json' -p "[{'op': 'replace', 'path': '/spec/tags/0/from/name', 'value': 'registry.access.redhat.com/rhpam-7/rhpam74-kieserver-openshift:1.0'}]"

  Write-Output-Header "Importing Templates"
  Call-Oc "create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/templates/rhpam$PAM7_VERSION-authoring.yaml" $True "Error importing Template" $True
}

Function Create-Rhn-Secret-For-Pull() {

  Write-Output ""
  Write-Output "########################################## Login Required ##########################################"
  Write-Output "# The new Red Hat Image Registry requires users to login with their Red Hat Network (RHN) account. #"
  Write-Output "# If you do not have an RHN account yet, you can create one at https://developers.redhat.com       #"
  Write-Output "####################################################################################################"
  Write-Output ""

  $RHN_USERNAME = Read-Host "Enter RHN username"
  $RHN_PASSWORD_SECURED = Read-Host "Enter RHN password" -AsSecureString
  $RHN_EMAIL = Read-Host "Enter e-mail address"

  if ($PSVersionTable.PSVersion.Major -ge 7 ) {
      $RHN_PASSWORD = ConvertFrom-SecureString -SecureString $RHN_PASSWORD_SECURED -AsPlainText
  }
  else {
      $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($RHN_PASSWORD_SECURED)
      $RHN_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  }

  oc create secret docker-registry red-hat-container-registry --docker-server=registry.redhat.io --docker-username=$RHN_USERNAME --docker-password=$RHN_PASSWORD --docker-email=$RHN_EMAIL
  oc secrets link builder red-hat-container-registry --for=pull
}

Function Import-Secrets-And-Service-Account() {
  Write-Output-Header "Importing secrets and service account."
  oc process -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/example-app-secret-template.yaml | oc create -f -
  oc process -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/example-app-secret-template.yaml -p SECRET_NAME=kieserver-app-secret | oc create -f -

  Call-Oc "create serviceaccount businesscentral-service-account" $True "Error creating service account." $True
  Call-Oc "create serviceaccount kieserver-service-account" $True "Error creating service account." $True
  Call-Oc "secrets link --for=mount businesscentral-service-account businesscentral-app-secret" $True "Error linking businesscentral-service-account to secret"
  Call-Oc "secrets link --for=mount kieserver-service-account kieserver-app-secret" $True "Error linking kieserver-service-account to secret"

  oc create -f $SCRIPT_DIR/credentials.yaml
}

Function Create-Application() {
  Write-Output-Header "Creating Process Automation Manager 7 Application config."

  $IMAGE_STREAM_NAMESPACE="openshift"

  if ($ARG_WITH_IMAGESTREAMS) {
    $IMAGE_STREAM_NAMESPACE=$($PRJ[0])
  }

  $argList = "new-app --template=rhpam$PAM7_VERSION-authoring"`
      + " -p APPLICATION_NAME=""$ARG_DEMO""" `
      + " -p IMAGE_STREAM_NAMESPACE=""$IMAGE_STREAM_NAMESPACE""" `
      + " -p CREDENTIALS_SECRET=""rhpam-credentials""" `
      + " -p BUSINESS_CENTRAL_HTTPS_SECRET=""businesscentral-app-secret""" `
      + " -p KIE_SERVER_HTTPS_SECRET=""kieserver-app-secret""" `
      + " -p BUSINESS_CENTRAL_MEMORY_LIMIT=""3Gi"""

  Call-Oc $argList $True "Error creating application." $True

  # Disable the OpenShift Startup Strategy and revert to the old Controller Strategy
  oc set env dc/$ARG_DEMO-rhpamcentr KIE_WORKBENCH_CONTROLLER_OPENSHIFT_ENABLED=false
  oc set env dc/$ARG_DEMO-kieserver KIE_SERVER_STARTUP_STRATEGY=ControllerBasedStartupStrategy KIE_SERVER_CONTROLLER_USER=$KIE_SERVER_CONTROLLER_USER KIE_SERVER_CONTROLLER_PWD=$KIE_SERVER_CONTROLLER_PWD KIE_SERVER_CONTROLLER_SERVICE=$ARG_DEMO-rhpamcentr KIE_SERVER_CONTROLLER_PROTOCOL=ws KIE_SERVER_ROUTE_NAME=insecure-$ARG_DEMO-kieserver
}

Function Build-And-Deploy() {
  Write-Output-Header "Starting OpenShift build and deploy..."
  #TODO: Implement function
  #oc start-build $ARG_DEMO-buscentr
}

Function Verify-Build-And-Deployments() {
  #TODO: Implement function.
  Write-Output-Header "Verifying build and deployments"
  # verify builds
  # We don't have any builds, so can skip this.
  #local _BUILDS_FAILED=false
  #for buildconfig in optaplanner-employee-rostering
  #do
  #  if [ -n "$(oc get builds -n $PRJ | grep $buildconfig | grep Failed)" ] && [ -z "$(oc get builds -n $PRJ | grep $buildconfig | grep Complete)" ]; then
  #    _BUILDS_FAILED=true
  #    echo "WARNING: Build $project/$buildconfig has failed..."
  #  fi
  #done

  # Verify deployments
  Verify-Deployments-In-Projects @($($PRJ[0]))
}

Function Verify-Deployments-In-Projects($projects) {
  Foreach ($project in $projects)
  {
      #TODO Implement function

      $argList1 = "get dc -l comp-type=database -n $project -o=custom-columns=:.metadata.name 2>/dev/null"
      $argList2 = "get dc -l comp-type!=database -n $project -o=custom-columns=:.metadata.name 2>/dev/null"

      $deployments=@($(Invoke-Expression "oc $argList1" 2>/dev/null))
      $deployments+=$(Invoke-Expression "oc $argList2" 2>/dev/null)
      Write-Output "Deployments: $deployments"

      Foreach($dc in $deployments) {
        if (!([string]::IsNullOrEmpty($dc))) {
          $dc_status=$(Invoke-Expression "oc get dc $dc -n $project -o=custom-columns=:.spec.replicas,:.status.availableReplicas")
          Write-Output "DC Status for $dc is: $dc_status"
        }
      }
  }
}

<#
function verify_deployments_in_projects() {
  for project in "$@"
  do
    local deployments="$(oc get dc -l comp-type=database -n $project -o=custom-columns=:.metadata.name 2>/dev/null) $(oc get dc -l comp-type!=database -n $project -o=custom-columns=:.metadata.name 2>/dev/null)"
    for dc in $deployments; do
      dc_status=$(oc get dc $dc -n $project -o=custom-columns=:.spec.replicas,:.status.availableReplicas)
      dc_replicas=$(echo $dc_status | sed "s/^\([0-9]\+\) \([0-9]\+\)$/\1/")
      dc_available=$(echo $dc_status | sed "s/^\([0-9]\+\) \([0-9]\+\)$/\2/")

      if [ "$dc_available" -lt "$dc_replicas" ] ; then
        echo "WARNING: Deployment $project/$dc: FAILED"
        echo
        echo "Starting a new deployment for $project/$dc ..."
        echo
        oc rollout cancel dc/$dc -n $project >/dev/null
        sleep 5
        oc rollout latest dc/$dc -n $project
        oc rollout status dc/$dc -n $project
      else
        echo "Deployment $project/$dc: OK"
      fi
    done
  done
}
#>

Function Make-Idle() {
  Write-Output-Header "Idling Services"
  $argList = "idle -n $($PRJ[0]) --all"
  try {
    Call-Oc $argList $True "Error idling service." $True
  } catch {
    Write-Error "Error occurred during project idling."
    exit
  }

}

# GPTE convention
Function Set-Default-Project() {
  if ($LOGGEDIN_USER.equals("system:admin")) {
    Call-Oc "project default" $True "Error setting default project" $True
  }
}

################################################################################
# Main deployment                                                              #
################################################################################

if ( ($LOGGEDIN_USER.equals("system:admin")) -And ([string]::IsNullOrEmpty($ARG_USERNAME)) ) {
  # for verify and delete, -project-suffix is enough
  if ($ARG_COMMAND.equals("delete") -Or $ARG_COMMAND.equals("verify") -And ([string]::IsNullOrEmpty($ARG_PROJECT_SUFFIX)))   {
    Write-Output "-user or -project-suffix must be provided when running $ARG_COMMAND as 'system:admin'"
    exit 255
  } elseif (!($ARG_COMMAND.equals("delete")) -And !($ARG_COMMAND.equals("verify"))) {
    Write-Output "-user must be provided when running $ARG_COMMAND as 'system:admin'"
    exit 255
  }
}

$START = [int](Get-Date -UFormat %s)

Write-Output-Header "$DEMO_NAME $(Get-Date)"

switch ( $ARG_COMMAND )
{
  "info" {
    Write-Output "Printing information $DEMO_NAME ($ARG_DEMO)..."
    Print-Info
  }
  "delete" {
    Write-Output "Delete $DEMO_NAME ($ARG_DEMO)..."
    $argList = "delete project $($PRJ[0])"
    try {
    	Invoke-Expression "oc $argList"
    } catch {
    	Write-Error "Error occurred during project deletion."
    	exit
    }
  }
  "verify" {
    # TODO: Implement verification.
    Write-Output "Verification has not yet been implemented..."
    #Write-Output "Verifying $DEMO_NAME ($ARG_DEMO)..."
    #Print-Info
    #Verify-Build-And-Deployments
  }
  "idle" {
    Write-Output "Idling $DEMO_NAME ($ARG_DEMO)..."
    Print-Info
    Make-Idle
  }
  "setup" {
    echo "Setting up and deploying $DEMO_NAME ($ARG_DEMO)..."

    Print-Info
    #Pre-Condition-Check
    Create-Projects
    Create-Rhn-Secret-For-Pull
    if ($ARG_WITH_IMAGESTREAMS) {
      Import-ImageStreams-And-Templates
    }

    Import-Secrets-And-Service-Account

    Create-Application

    if ($ARG_RUN_VERIFY) {
      # TODO: Implement verification.
      Write-Output "Verification has not yet been implemented..."
      #Write-Output "Waiting for deployments to finish..."
      #Start-Sleep -s 30
      #Verify-Build-And-Deployments
    }

    #if [ "$ARG_RUN_VERIFY" = true ] ; then
    #    echo "Waiting for deployments to finish..."
    #  sleep 30
    #  verify_build_and_deployments
    #fi
  }
  default {
    Write-Output "Invalid command specified: '$ARG_COMMAND'"
    Usage
  }
}
#pushd ~ >/dev/null
<#
START=`date +%s`

echo_header "$DEMO_NAME ($(date))"

case "$ARG_COMMAND" in
    info)
      echo "Printing information $DEMO_NAME ($ARG_DEMO)..."
      print_info
      ;;
    delete)
        echo "Delete $DEMO_NAME ($ARG_DEMO)..."
        oc delete project ${PRJ[0]}
        ;;

    verify)
        echo "Verifying $DEMO_NAME ($ARG_DEMO)..."
        print_info
        verify_build_and_deployments
        ;;

    idle)
        echo "Idling $DEMO_NAME ($ARG_DEMO)..."
        print_info
        make_idle
        ;;

    setup)
        echo "Setting up and deploying $DEMO_NAME ($ARG_DEMO)..."

        print_info
        #pre_condition_check
        create_projects
        if [ "$ARG_WITH_IMAGESTREAMS" = true ] ; then
           import_imagestreams_and_templates
        fi
	      import_secrets_and_service_account

        create_application

        if [ "$ARG_RUN_VERIFY" = true ] ; then
          echo "Waiting for deployments to finish..."
          sleep 30
          verify_build_and_deployments
        fi
        ;;

    deploy)
        echo "Deploying $DEMO_NAME ($ARG_DEMO)..."

        print_info

        build_and_deploy

        if [ "$ARG_RUN_VERIFY" = true ] ; then
          echo "Waiting for deployments to finish..."
          sleep 30
          verify_build_and_deployments
        fi
        ;;

    *)
        echo "Invalid command specified: '$ARG_COMMAND'"
        usage
        ;;
esac
#>

Set-Default-Project

$END = [int](Get-Date -UFormat %s)
Write-Output ""
Write-Output "Provisioning done! (Completed in $([int]( ($END - $START)/60 )) min $(( ($END - $START)%60 )) sec)"
