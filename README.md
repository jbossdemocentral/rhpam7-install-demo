Red Hat Process Automation Manager 7 Install Demo
=======================================
Project to automate the installation of this product without preconfiguration beyond a single admin user.

There are three options available to you for using this demo: local, OpenShift and Docker.

Software
--------
The following software is required to run this demo:
- [JBoss EAP 7.1 zip archive](https://developers.redhat.com/download-manager/file/jboss-eap-7.1.0.zip)
- [Red Hat Process Automation Manager: Business Central 7.0.0.ER2 deployable for EE7](https://upload.wikimedia.org/wikipedia/commons/6/67/Learning_Curve_--_Coming_Soon_Placeholder.png)
- [Red Hat Process Automation Manager: KIE-Server 7.0.0.ER2 deployable for EE7]((https://upload.wikimedia.org/wikipedia/commons/6/67/Learning_Curve_--_Coming_Soon_Placeholder.png))
- [7-Zip](http://www.7-zip.org/download.html) (Windows only): to overcome the Windows 260 character path length limit, we need 7-Zip to unzip the Process Automation Manager deployable.


Option 1 - Install on your machine
----------------------------------
1. [Download and unzip](https://github.com/jbossdemocentral/rhpam7-install-demo/archive/master.zip) or [clone this repo](https://github.com/jbossdemocentral/rhpam7-install-demo.git).

2. Add the EAP zip archive and Process Automation Manager deployables to the installs directory.

3. Run `init.sh` (Linux/macOS) or `init.ps1` (Windows) file.

4. Start the runtime: `./target/jboss-eap-7.1/bin/standalone.sh'` (Linux/macOS) or `.\target\jboss-eap-7.1\bin\standalone.ps1` (Windows)

5. Login to Business Central at: http://localhost:8080/business-central  (u:pamAdmin / p:redhatpam1!)

6. Enjoy the installed and configured Red Hat Process Automation Manager 7.


Option 2 - Run on OpenShift
-----------------------------------------
This demo can be installed on Red Hat OpenShift in various ways. We'll explain the different options provided.

All installation options require an `oc` client installation that is connected to a running OpenShift instance. More information on OpenShift and how to setup a local OpenShift development environment based on the Red Hat Container Development Kit can be found [here](https://developers.redhat.com/products/cdk/overview/).

---
**NOTE**

The Red Hat Process Automation Manager 7 - Business Central image requires a [Persistent Volume](https://docs.openshift.com/container-platform/3.7/architecture/additional_concepts/storage.html) which has both `ReadWriteOnce` (RWO) *and* `ReadWriteMany` (RWX) Access Types. If no PVs matching this description are available, deployment of that image will fail until a PV of that type is available.

---

### Automated installation
This installation option will install the Process Automation Manager 7 and Process Service in OpenShift using a single script, after which the demo project needs to be manually imported.

1. [Download and unzip](https://github.com/jbossdemocentral/rhpam7-install-demo/archive/master.zip) or [clone this repo](https://github.com/jbossdemocentral/rhpam7-install-demo.git).

2. Run the `init-openshift.sh` (Linux/macOS) or `init-openshift.ps1` (Windows) file. This will create a new project and application in OpenShift.

3. Login to your OpenShift console. For a local OpenShift installation this is usually: https://{host}:8443/console

4. Open the project "RHPAM7 Install Demo". Open the "Overview" screen. Wait until the 2 pods, "rhpam7-install-rhpamcentr" and "rhpam7-install-kieserver" have been deployed.

5. Open the "Applications -> Routes" screen. Click on the "Hostname" value next to "rhpam7-install-rhpamcentr". This opens the Business Central console.

6. Login to Business Central (u:pamAdmin, p:redhatpam1!)

7. Enjoy the installed and configured Red Hat Process Automation Manager 7.


### Scripted installation
This installation option will install the Process Automation Manager 7 and Process Service in OpenShift using the provided `provision.sh` (Linux/macOS) or `provision.ps1` (Windows) script, which gives the user a bit more control how to provision to OpenShift.

1. [Download and unzip.](https://github.com/jbossdemocentral/rhpam7-install-demo/archive/master.zip) or [clone this repo](https://github.com/jbossdemocentral/rhpam7-install-demo.git).

2. In the demo directory, go to `./support/openshift`. In that directory you will find the `provision.sh` (Linux/macOS) and `provision.ps1` (Windows) script.

3. Run `./provision.sh -h` (Linux/macOS) or `./provision.ps1 -h` (Windows) to inspect the installation options.

4. To provision the demo, with the OpenShift ImageStreams in the project's namespace, run `./provision.sh setup rhpam7-install --with-imagestreams` (Linux/macOS) or `./provision.sh -command setup -demo rhpam7-install -with-imagestreams` (Windows)

    ---
    **NOTE**

    The `with-imagestreams` parameter installs the Process Automation Manager 7 image streams and templates into the project namespace instead of the `openshift` namespace (for which you need admin rights). If you already have the required image-streams and templates installed in your OpenShift environment in the `openshift` namespace, you can omit the `with-imagestreams` from the setup command.

    ---

5. A second useful option is the `--pv-capacity` (Linux/macOS)/ `-pv-capacity` (Windows) option, which allows you to set the capacity of the _Persistent Volume_ used by the Business Central component. This is for example required when installing this demo in OpenShift Online, as the _Persistent Volume Claim_ needs to be set to `1Gi` instead of the default `512Mi`. So, to install this demo in OpenShift Online, you can use the following command: `./provision.sh setup rhpam7-install --pv-capacity 1Gi --with-imagestreams` (Linux/macOS) or `./provision.ps1 -command setup -demo rhpam7-install -pv-capacity 1Gi -with-imagestreams` (Windows).

6. After provisioning, follow the instructions from above "Option 2 - Automated installation, manual project import", starting at step 3.

7. To delete an already provisioned demo, run `./provision.sh delete rhpam7-install` (Linux/macOS) or `./provision.ps1 -command delete -demo rhpam7-install` (Windows).


Option 3 - Run in Docker
-----------------------------------------
The following steps can be used to configure and run the demo in a container

1. [Download and unzip](https://github.com/jbossdemocentral/rhpam7-install-demo/archive/master.zip) or [clone this repo](https://github.com/jbossdemocentral/rhpam7-install-demo.git).

2. Add the EAP zip archive and Process Automation Manager deployables to the installs directory.

3. Run the `init-docker.sh` (Linux/macOS) or `init-docker.ps1` (Windows) file.

4. Start the container: `docker run -it -p 8080:8080 -p 9990:9990 jbossdemocentral/rhpam7-install-demo`

5. Login to Business Central at: http://&lt;CONTAINER_HOST&gt;:8080/business-central  (u:pamAdmin / p:redhatpam1!)

7. Enjoy the installed and configured Red Hat Process Automation Manager 7.


Supporting Articles
-------------------
- [Getting Started with Red Hat Process Automation Manager 7](https://upload.wikimedia.org/wikipedia/commons/6/67/Learning_Curve_--_Coming_Soon_Placeholder.png)

Released versions
-----------------
See the tagged releases for the following versions of the product:

- v0.8 - Red Hat Process Automation Manager 7.0.0.ER2


![RHPAM 7](https://raw.githubusercontent.com/jbossdemocentral/rhpam7-install-demo/master/docs/demo-images/rhpam7.png)
