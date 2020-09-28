#!/bin/sh
#!/bin/bash
set -e

command -v oc >/dev/null 2>&1 || {
  echo >&2 "The oc client tools need to be installed to connect to OpenShift.";
  echo >&2 "Download it from https://www.openshift.org/download.html and confirm that \"oc version\" runs.";
  exit 1;
}

################################################################################
# Provisioning script to deploy the demo on an OpenShift environment           #
################################################################################
function usage() {
    echo
    echo "Usage:"
    echo " $0 [command] [demo-name] [options]"
    echo " $0 --help"
    echo
    echo "Example:"
    echo " $0 setup rhpam7-install --project-suffix s40d"
    echo
    echo "COMMANDS:"
    echo "   setup                    Set up the demo projects and deploy demo apps"
    echo "   deploy                   Deploy demo apps"
    echo "   delete                   Clean up and remove demo projects and objects"
    echo "   verify                   Verify the demo is deployed correctly"
    echo "   idle                     Make all demo services idle"
    echo
    echo "DEMOS:"
    echo "   rhpam7-install            Red Hat Process Automation Install demo"
    echo
    echo "OPTIONS:"
    echo "   --user [username]         The admin user for the demo projects. mandatory if logged in as system:admin"
    echo "   --project-suffix [suffix] Suffix to be added to demo project names e.g. ci-SUFFIX. If empty, user will be used as suffix."
    echo "   --run-verify              Run verify after provisioning"
    echo "   --with-imagestreams       Creates the image streams in the project. Useful when required ImageStreams are not available in the 'openshift' namespace and cannot be provisioned in that 'namespace'."
    echo "   --pv-capacity [capacity]  Capacity of the persistent volume. Defaults to 512Mi as set by the Red Hat Process Automation Manager OpenShift template."
    # TODO support --maven-mirror-url
    echo
}

ARG_USERNAME=
ARG_PROJECT_SUFFIX=
ARG_COMMAND=
ARG_RUN_VERIFY=false
ARG_WITH_IMAGESTREAMS=false
ARG_PV_CAPACITY=512Mi
ARG_DEMO=

while :; do
    case $1 in
        info)
          ARG_COMMAND=info
          if [ -n "$2" ]; then
              ARG_DEMO=$2
              shift
          fi
          ;;
        setup)
            ARG_COMMAND=setup
            if [ -n "$2" ]; then
                ARG_DEMO=$2
                shift
            fi
            ;;
        deploy)
            ARG_COMMAND=deploy
            if [ -n "$2" ]; then
                ARG_DEMO=$2
                shift
            fi
            ;;
        delete)
            ARG_COMMAND=delete
            if [ -n "$2" ]; then
                ARG_DEMO=$2
                shift
            fi
            ;;
        verify)
            ARG_COMMAND=verify
            if [ -n "$2" ]; then
                ARG_DEMO=$2
                shift
            fi
            ;;
        idle)
            ARG_COMMAND=idle
            if [ -n "$2" ]; then
                ARG_DEMO=$2
                shift
            fi
            ;;
        --user)
            if [ -n "$2" ]; then
                ARG_USERNAME=$2
                shift
            else
                printf 'ERROR: "--user" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        --project-suffix)
            if [ -n "$2" ]; then
                ARG_PROJECT_SUFFIX=$2
                shift
            else
                printf 'ERROR: "--project-suffix" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        --run-verify)
            ARG_RUN_VERIFY=true
            ;;
        --with-imagestreams)
            ARG_WITH_IMAGESTREAMS=true
            ;;
        --pv-capacity)
            if [ -n "$2" ]; then
                ARG_PV_CAPACITY=$2
                shift
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            shift
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done


################################################################################
# Configuration                                                                #
################################################################################
LOGGEDIN_USER=$(oc whoami)
OPENSHIFT_USER=${ARG_USERNAME:-$LOGGEDIN_USER}

# Project name needs to be unique across OpenShift Online
PRJ_SUFFIX=${ARG_PROJECT_SUFFIX:-`echo $OPENSHIFT_USER | sed -e 's/[^-a-z0-9]/-/g'`}
PRJ=("rhpam7-install-$PRJ_SUFFIX" "RHPAM7 Install Demo" "Red Hat Process Automation Manager 7 Install Demo")

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# KIE Parameters
KIE_ADMIN_USER=pamAdmin
KIE_ADMIN_PWD=redhatpam1!
KIE_SERVER_CONTROLLER_USER=kieserver
KIE_SERVER_CONTROLLER_PWD=kieserver1!
KIE_SERVER_USER=kieserver
KIE_SERVER_PWD=kieserver1!

# Version Configuration Parameters
OPENSHIFT_PAM7_TEMPLATES_TAG=7.8.0.GA
IMAGE_STREAM_TAG=7.8.0
PAM7_VERSION=78


################################################################################
# DEMO MATRIX                                                                  #
################################################################################
case $ARG_DEMO in
    rhpam7-install)
      DEMO_NAME=${PRJ[2]}
	    ;;
    *)
      echo "ERROR: Invalid demo name: \"$ARG_DEMO\""
      usage
      exit 255
      ;;
esac


################################################################################
# Functions                                                                    #
################################################################################

function echo_header() {
  echo
  echo "########################################################################"
  echo $1
  echo "########################################################################"
}

function print_info() {
  echo_header "Configuration"

  #OPENSHIFT_MASTER=$(oc status | head -1 | sed 's#.*\(https://[^ ]*\)#\1#g') # must run after projects are created
  OPENSHIFT_MASTER=$(oc version | tail -3 | head -1 | sed 's#.*\(https://[^ ]*\)#\1#g')

  echo "Demo name:           $ARG_DEMO"
  echo "Project name:        ${PRJ[0]}"
  echo "OpenShift master:    $OPENSHIFT_MASTER"
  echo "Current user:        $LOGGEDIN_USER"
  echo "Project suffix:      $PRJ_SUFFIX"
}

function pre_condition_check() {
  echo_header "Checking pre-conditions"
}

# waits while the condition is true until it becomes false or it times out
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

# Create Project
function create_projects() {
  echo_header "Creating project..."

  echo "Creating project ${PRJ[0]}"
  oc new-project "${PRJ[0]}" --display-name="${PRJ[1]}" --description="${PRJ[2]}" >/dev/null
}

function import_imagestreams_and_templates() {
  echo_header "Importing Image Streams"
  oc create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/rhpam$PAM7_VERSION-image-streams.yaml

  echo ""
  echo "Fetching ImageStreams from registry."
  #Instead of sleeping 10 seconds, run a little annimation for 10 seconds
  runSpinner 10

  #  Explicitly import the images. This is to overcome a problem where the image import gets a 500 error from registry.redhat.io when we deploy multiple containers at once.
  oc import-image rhpam-businesscentral-rhel8:$IMAGE_STREAM_TAG —confirm -n ${PRJ[0]}
  oc import-image rhpam-kieserver-rhel8:$IMAGE_STREAM_TAG —confirm -n ${PRJ[0]}

  #  echo_header "Patching the ImageStreams"
  #  oc patch is/rhpam74-businesscentral-openshift --type='json' -p '[{"op": "replace", "path": "/spec/tags/0/from/name", "value": "registry.access.redhat.com/rhpam-7/rhpam74-businesscentral-openshift:1.0"}]'
  #  oc patch is/rhpam74-kieserver-openshift --type='json' -p '[{"op": "replace", "path": "/spec/tags/0/from/name", "value": "registry.access.redhat.com/rhpam-7/rhpam74-kieserver-openshift:1.0"}]'

  echo_header "Importing Templates"
  oc create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/templates/rhpam$PAM7_VERSION-authoring.yaml
}

#Runs a spinner for the time passed to the function.
function runSpinner() {
  sleeptime=0.5
  maxCount=$( bc <<< "$1 / $sleeptime")
  counter=0
  i=1
  sp="/-\|"
  while [ $counter -lt $maxCount ]
  do
    printf "\b${sp:i++%${#sp}:1}"
    sleep $sleeptime
    let counter=counter+1
  done
}

function createRhnSecretForPull() {

  echo ""
  echo "########################################## Login Required ##########################################"
  echo "# The new Red Hat Image Registry requires users to login with their Red Hat Network (RHN) account. #"
  echo "# If you do not have an RHN account yet, you can create one at https://developers.redhat.com       #"
  echo "####################################################################################################"
  echo ""

  echo "Enter RHN username:"
  read RHN_USERNAME

  echo "Enter RHN password:"
  read -s RHN_PASSWORD

  echo "Enter e-mail address:"
  read RHN_EMAIL

  oc create secret docker-registry red-hat-container-registry \
    --docker-server=registry.redhat.io \
    --docker-username="$RHN_USERNAME" \
    --docker-password="$RHN_PASSWORD" \
    --docker-email="$RHN_EMAIL"

    oc secrets link builder red-hat-container-registry --for=pull
}

function import_secrets_and_service_account() {
  echo_header "Importing secrets and service account."
  oc process -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/example-app-secret-template.yaml | oc create -f -
  oc process -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/example-app-secret-template.yaml -p SECRET_NAME=kieserver-app-secret | oc create -f -

  oc create serviceaccount businesscentral-service-account
  oc create serviceaccount kieserver-service-account
  oc secrets link --for=mount businesscentral-service-account businesscentral-app-secret
  oc secrets link --for=mount kieserver-service-account kieserver-app-secret

  oc create -f $SCRIPT_DIR/credentials.yaml
}

function create_application() {
  echo_header "Creating Process Automation Manager 7 Application config."

  IMAGE_STREAM_NAMESPACE="openshift"

  if [ "$ARG_WITH_IMAGESTREAMS" = true ] ; then
    IMAGE_STREAM_NAMESPACE=${PRJ[0]}
  fi

  oc new-app --template=rhpam$PAM7_VERSION-authoring \
			-p APPLICATION_NAME="$ARG_DEMO" \
			-p IMAGE_STREAM_NAMESPACE="$IMAGE_STREAM_NAMESPACE" \
			-p CREDENTIALS_SECRET="rhpam-credentials" \
      -p BUSINESS_CENTRAL_HTTPS_SECRET="businesscentral-app-secret" \
      -p KIE_SERVER_HTTPS_SECRET="kieserver-app-secret" \
			-p BUSINESS_CENTRAL_MEMORY_LIMIT="2Gi"

  # Disable the OpenShift Startup Strategy and revert to the old Controller Strategy
  oc set env dc/$ARG_DEMO-rhpamcentr KIE_WORKBENCH_CONTROLLER_OPENSHIFT_ENABLED=false
  oc set env dc/$ARG_DEMO-kieserver KIE_SERVER_STARTUP_STRATEGY=ControllerBasedStartupStrategy KIE_SERVER_CONTROLLER_USER=$KIE_SERVER_CONTROLLER_USER KIE_SERVER_CONTROLLER_PWD=$KIE_SERVER_CONTROLLER_PWD KIE_SERVER_CONTROLLER_SERVICE=$ARG_DEMO-rhpamcentr KIE_SERVER_CONTROLLER_PROTOCOL=ws KIE_SERVER_ROUTE_NAME=insecure-$ARG_DEMO-kieserver

}

function build_and_deploy() {
  echo_header "Starting OpenShift build and deploy..."
  #TODO: Implement function
  #oc start-build $ARG_DEMO-buscentr
}


function verify_build_and_deployments() {
  echo_header "Verifying build and deployments"

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

  # verify deployments
  verify_deployments_in_projects ${PRJ[0]}
}

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

function make_idle() {
  echo_header "Idling Services"
  oc idle -n ${PRJ[0]} --all
}

# GPTE convention
function set_default_project() {
  if [ $LOGGEDIN_USER == 'system:admin' ] ; then
    oc project default >/dev/null
  fi
}


################################################################################
# Main deployment                                                              #
################################################################################

if [ "$LOGGEDIN_USER" == 'system:admin' ] && [ -z "$ARG_USERNAME" ] ; then
  # for verify and delete, --project-suffix is enough
  if [ "$ARG_COMMAND" == "delete" ] || [ "$ARG_COMMAND" == "verify" ] && [ -z "$ARG_PROJECT_SUFFIX" ]; then
    echo "--user or --project-suffix must be provided when running $ARG_COMMAND as 'system:admin'"
    exit 255
  # deploy command
  elif [ "$ARG_COMMAND" != "delete" ] && [ "$ARG_COMMAND" != "verify" ] ; then
    echo "--user must be provided when running $ARG_COMMAND as 'system:admin'"
    exit 255
  fi
fi

#pushd ~ >/dev/null
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
        createRhnSecretForPull
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

set_default_project
#popd >/dev/null

END=`date +%s`
echo
echo "Provisioning done! (Completed in $(( ($END - $START)/60 )) min $(( ($END - $START)%60 )) sec)"
