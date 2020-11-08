@ECHO OFF
setlocal

set PROJECT_HOME=%~dp0
set DEMO=Install Demo
set AUTHORS=Red Hat
set PROJECT="git@github.com:jbossdemocentral/rhpam7-install-demo.git"
set PRODUCT=Red Hat Process Automation Manager
set JBOSS_HOME=%PROJECT_HOME%\target\jboss-eap-7.3
set SERVER_DIR=%JBOSS_HOME%\standalone\deployments
set SERVER_CONF=%JBOSS_HOME%\standalone\configuration\
set SERVER_BIN=%JBOSS_HOME%\bin
set SRC_DIR=%PROJECT_HOME%\installs
set SUPPORT_DIR=%PROJECT_HOME%\support
set PRJ_DIR=%PROJECT_HOME%\projects
set VERSION_EAP=7.3.0
set VERSION=7.9.0
set EAP=jboss-eap-%VERSION_EAP%.zip
set RHPAM=rhpam-%VERSION%-business-central-eap7-deployable.zip
set RHPAM_KIE_SERVER=rhpam-%VERSION%-kie-server-ee8.zip
set RHPAM_ADDONS=rhpam-%VERSION%-add-ons.zip
set RHPAM_CASE=rhpam-%VERSION%-case-mgmt-showcase-eap7-deployable.zip

REM wipe screen.
cls

echo.
echo ###################################################################
echo ##                                                               ##  
echo ##  Setting up the                                               ##
echo ##                                                               ##  
echo ##             ####  ##### ####     #   #  ###  #####            ##
echo ##             #   # #     #   #    #   # #   #   #              ##
echo ##             ####  ###   #   #    ##### #####   #              ##
echo ##             #  #  #     #   #    #   # #   #   #              ##
echo ##             #   # ##### ####     #   # #   #   #              ##
echo ##                                                               ##
echo ##           ####  ####   ###   #### #####  ####  ####           ##
echo ##           #   # #   # #   # #     #     #     #               ##
echo ##           ####  ####  #   # #     ###    ###   ###            ##
echo ##           #     #  #  #   # #     #         #     #           ##
echo ##           #     #   #  ###   #### ##### ####  ####            ##
echo ##                                                               ##
echo ##   ###  #   # #####  ###  #   #  ###  ##### #####  ###  #   #  ##
echo ##  #   # #   #   #   #   # ## ## #   #   #     #   #   # ##  #  ##
echo ##  ##### #   #   #   #   # # # # #####   #     #   #   # # # #  ##
echo ##  #   # #   #   #   #   # #   # #   #   #     #   #   # #  ##  ##
echo ##  #   # #####   #    ###  #   # #   #   #   #####  ###  #   #  ##
echo ##                                                               ##
echo ##           #   #  ###  #   #  ###  ##### ##### ####            ##
echo ##           ## ## #   # ##  # #   # #     #     #   #           ##
echo ##           # # # ##### # # # ##### #  ## ###   ####            ##
echo ##           #   # #   # #  ## #   # #   # #     #  #            ##
echo ##           #   # #   # #   # #   # ##### ##### #   #           ##
echo ##                                                               ##  
echo ##  brought to you by, %AUTHORS%                            ##
echo ##                                                               ##
echo ##  %PROJECT%      ##
echo ##                                                               ##   
echo ###################################################################
echo.

REM make some checks first before proceeding.	
if exist "%SUPPORT_DIR%" (
        echo Support dir is presented...
        echo.
) else (
        echo %SUPPORT_DIR% wasn't found. Please make sure to run this script inside the demo directory.
        echo.
        GOTO :EOF
)

if exist "%SRC_DIR%\%EAP%" (
        echo JBoss EAP sources are present...
        echo.
) else (
        echo Need to download %EAP% package from https://developers.redhat.com/products/eap/download
        echo and place it in the %SRC_DIR% directory to proceed...
        echo.
        GOTO :EOF
)

if exist "%SRC_DIR%\%RHPAM%" (
        echo Red Hat Process Automation Manager sources are present...
        echo.
) else (
        echo Need to download %RHPAM% package from https://developers.redhat.com/products/rhpam/download
        echo and place it in the %SRC_DIR% directory to proceed...
        echo.
        GOTO :EOF
)

if exist "%SRC_DIR%\%RHPAM_KIE_SERVER%" (
        echo Red Hat Process Automation Maanger Kie Server sources are present...
        echo.
) else (
        echo Need to download %RHPAM_KIE_SERVER% package from https://developers.redhat.com/products/rhpam/download
        echo and place it in the %SRC_DIR% directory to proceed...
        echo.
        GOTO :EOF
)

if exist "%SRC_DIR%\%RHPAM_ADDONS%" (
        echo Red Hat Process Automation Manager Case Management sources are present...
        echo.
) else (
        echo Need to download %RHPAM_ADDONS% package from https://developers.redhat.com/products/rhpam/download
        echo and place it in the %SRC_DIR% directory to proceed...
        echo.
        GOTO :EOF
)


REM Move the old instance, if it exists, to the OLD position.
if exist "%PROJECT_HOME%\target" (
         echo - removing existing install...
         echo.
        
         rmdir /s /q %PROJECT_HOME%\target
 )

echo Creating target directory...
echo.
mkdir %PROJECT_HOME%\target



REM Installation.
echo JBoss EAP installation running now...
echo.
cscript /nologo %SUPPORT_DIR%\unzip.vbs %SRC_DIR%\%EAP% %PROJECT_HOME%\target

if not "%ERRORLEVEL%" == "0" (
  echo.
	echo Error Occurred During JBoss EAP Installation!
	echo.
	GOTO :EOF
)

call set NOPAUSE=true

echo Red Hat Process Automation Manager installation running now...
echo.
cscript /nologo %SUPPORT_DIR%\unzip.vbs %SRC_DIR%\%RHPAM% %PROJECT_HOME%\target

if not "%ERRORLEVEL%" == "0" (
  echo.
	echo Error Occurred During Red Hat Process Automation Manager Installation!
	echo.
	GOTO :EOF
)

echo Red Hat Process Automation Manager Kie Server installation running now...
echo.
cscript /nologo %SUPPORT_DIR%\unzip.vbs %SRC_DIR%\%RHPAM_KIE_SERVER% %JBOSS_HOME%\standalone\deployments

if not "%ERRORLEVEL%" == "0" (
  echo.
	echo Error Occurred During Red Hat Process Automation Manager Kie Server Installation!
	echo.
	GOTO :EOF
)

REM Set deployment Kie Server.
echo. 2>%JBOSS_HOME%/standalone/deployments/kie-server.war.dodeploy

echo Red Hat Process Automation Manager Case Management installation running now...
echo.
cscript /nologo %SUPPORT_DIR%\unzip.vbs %SRC_DIR%\%RHPAM_ADDONS% %SRC_DIR%

if not "%ERRORLEVEL%" == "0" (
  echo.
	echo Error Occurred During Red Hat Process Automation Manager Case Management Extraction!
	echo.
	GOTO :EOF
)

cscript /nologo %SUPPORT_DIR%\unzip.vbs %SRC_DIR%\%RHPAM_CASE% %PROJECT_HOME%\target

if not "%ERRORLEVEL%" == "0" (
  echo.
	echo Error Occurred During Red Hat Process Automation Manager Case Management Extraction!
	echo.
	GOTO :EOF
)

REM Clean up case management archives.
del %SRC_DIR%\rhpam-7.1-*


REM Set deployment Case Management.
echo. 2>%JBOSS_HOME%/standalone/deployments/rhpam-case-mgmt-showcase.war.dodeploy


echo.
echo - enabling demo accounts role setup...
echo.
echo - User 'pamAdmin' password 'redhatpam1!' setup...
echo.
call %JBOSS_HOME%\bin\add-user.bat -a -r ApplicationRealm -u pamAdmin -p redhatpam1! -ro analyst,admin,manager,user,kie-server,kiemgmt,rest-all --silent
echo - User 'adminUser' password 'test1234!' setup...
echo.
call %JBOSS_HOME%\bin\add-user.bat -a -r ApplicationRealm -u adminUser -p test1234! -ro analyst,admin,manager,user,kie-server,kiemgmt,rest-all --silent
echo - Management user 'kieserver' password 'kieserver1!' setup...
echo.
call %JBOSS_HOME%\bin\add-user.bat -a -r ApplicationRealm -u kieserver -p kieserver1! -ro kie-server --silent
echo - Management user 'caseUser' password 'redhatpam1!' setup...
echo.
call %JBOSS_HOME%\bin\add-user.bat -a -r ApplicationRealm -u caseUser -p redhatpam1! -ro user --silent
echo - Management user 'caseManager' password 'redhatpam1!' setup...
echo.
call %JBOSS_HOME%\bin\add-user.bat -a -r ApplicationRealm -u caseManager -p redhatpam1! -ro user,manager --silent
echo - Management user 'caseSupplier' password 'redhatpam1!' setup...
echo.
call %JBOSS_HOME%\bin\add-user.bat -a -r ApplicationRealm -u caseSupplier -p redhatpam1! -ro user,supplier --silent

echo - setting up standalone.xml configuration adjustments...
echo.
xcopy /Y /Q "%SUPPORT_DIR%\standalone-full.xml" "%SERVER_CONF%\standalone.xml"
echo.

echo - setup email task notification users...
echo.
xcopy /Y /Q "%SUPPORT_DIR%\userinfo.properties" "%SERVER_DIR%\business-central.war\WEB-INF\classes\"

echo "=============================================================="
echo "=                                                            ="
echo "=  %PRODUCT% %VERSION% setup complete.  ="
echo "=                                                            ="
echo "=  Start %PRODUCT% with:            ="
echo "=                                                            ="
echo "=           %SERVER_BIN%/standalone.bat         ="
echo "=                                                            ="
echo "=  Log in to Red Hat Process Automation Manager to start     ="
echo "=  developing rules projects:                                ="
echo "=                                                            ="
echo "=  http://localhost:8080/business-central                    ="
echo "=                                                            ="
echo "=    Log in: [ u:pamAdmin / p:redhatpam1! ]                  ="
echo "=                                                            ="
echo "=  http://localhost:8080/rhpam-case-mgmt-showcase            ="
echo "=                                                            ="
echo "=    Log in: [ u:pamAdmin / p:redhatpam1! ]                  ="
echo "=                                                            ="
echo "=    Others:                                                 ="
echo "=            [ u:kieserver / p:kieserver1! ]                 ="
echo "=            [ u:caseuser / p:redhatpam1! ]                  ="
echo "=            [ u:casemanager / p:redhatpam1! ]               ="
echo "=            [ u:casesupplier / p:redhatpam1! ]              ="
echo "=                                                            ="
echo "=============================================================="
echo.

