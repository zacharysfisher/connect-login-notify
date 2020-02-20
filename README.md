# jamf_connect_notify

## Overview
This page will explain how to configure Jamf Connect Login's Notify and Run Script mechanisms (Pluggable Authentication Module) to be used for user provisioning.  This page is geared towards Okta users ONLY.


## Contents
* Prestage Package Configuration
* Plist Configuration for Jamf Connect Login
* RunScript Configuration
* Prestage Settings
* Okta Configurations for Standard / Admin Users
* Deployment


    

## Prestage Package Configuration

<a href="Prestage Package Configuration"><img src="https://github.com/zacharysfisher/connect-login-notify/blob/master/images/package_prestage.png" align="right" height="350" width="500" ></a>
First we need to build our Pre-Stage package to look like the image to the right:
<br>
<br> 
As you can see, we are installing both Sync and Login to a temporary location which we will then all to install using the `installer` binary later in the process.  We are also installing out image files and the notify script location which will also be called later on in this provisioning process.Post Install Script should look like below:
The package also needs a post-install script that will install Login, Sync and activate the Notify and RunScript Mechanisms for us.  Please see below.
<br>
<br>
<br>


```
#!/bin/sh
## postinstall

# Install JCL + Sync
installer -pkg /tmp/Jamf\ Connect\ Login-1.9.0.pkg -target / 
installer -pkg /tmp/Jamf\ Connect\ Sync-1.1.0.pkg -target /

# Enable Notify - Run Script
/usr/local/bin/authchanger -reset -Okta —DefaultJCRight -preAuth JamfConnectLogin:RunScript,privileged JamfConnectLogin:Notify


exit 0		## Success
exit 1		## Failure
```

Once this package is ready for building, make sure that you sign the package and upload it to your distribution points for deployment.

## Plist Configuration for Jamf Connect Login
Below is an example Plist that we can use with a Custom Settings payload Configuration Profile:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AuthServer</key>
	<string>acme.okta.com</string>
	<key>HelpURL</key>
	<string>https://acme.okta.com</string>
	<key>LocalFallback</key>
	<true/>
	<key>LoginLogo</key>
	<string>/usr/local/images/company_logo.png</string>
	<key>OIDCIgnoreCookies</key>
	<true/>
	<key>OIDCRedirectURI</key>
	<string>https://127.0.0.1/jamfconnect</string>
	<key>AllowNetworkSelection</key>
	<true/>
	<key>CreateSyncPasswords</key>
	<true/>
	<key>ScriptPath</key>
	<string>/usr/local/bin/enrollment_script.sh</string>
	<key>EnableFDE</key>
	<true/>
</dict>
</plist>
```

Below is an explanation of keys being used

| Key                    | Description                                                            | Example         |
|------------------------|------------------------------------------------------------------------|-----------------|
| AuthServer  | Your Okta base URL for your organization | `<key>AuthServer</key>` `<string>acme.okta.com</string>` |
| HelpURL     | URL users are directed to when hitting help at login.  This can be a custom page or your okta homepage    | `<key>HelpURL</key>` `<string>https://acme.okta.com</string>` |
| LocalFallback       | Allows local authentication in case Okta is not reachable    | `<key>LocalFallback</key>` `<true/>` |
| LoginLogo     | Login Logo to be displayed at Jamf Connect Login screen | `<key>LoginLogo</key>` `<string>/path/to/image.png</string>` |
| OIDCIgnoreCookies     | Ignores any cookies stored by the loginwindow | `<key>OIDCIgnoreCookies</key>` `<true/>` |
| OIDCRedirectURI     | The redirect URI used by your Jamf Connect app in Okta.  "jamfconnect://127.0.0.1/jamfconnect" is recommended by default. | `<key>OIDCRedirectURI</key>` `<string>https://127.0.0.1/jamfconnect</string>` |
| AllowNetworkSelection     | Allows user to select Wi-Fi network at login window. | `<key>AllowNetworkSelection</key>` `<true/>` |
| CreateSyncPasswords     | Creates a keychain entry for Jamf Connect Sync (requires Sync to be installed already at time of login for this to function | `<key>CreateSyncPasswords</key>` `<true/>` |
| ScriptPath     | Specifies the path to the script or other executable run by the RunScript mechanism. | `<key>ScriptPath</key>` `<string>/path/to/script.sh</string>` |
| EnableFDE     | Enables Filevault and stores the FV Recovery key locally for Escrow to JAMF Pro (Requires Escrow Configuration Profile to send to JAMF Pro). | `<key>CEnableFDE</key>` `<true/>` |

**Please note**
For 10.15 and on, a PCCC Configuration profile is needed.  [PCCC Payload to allow EnableFDE](https://github.com/zacharysfisher/connect-login-notify/blob/master/images/PCCC_FDE.png)

## RunScript Configuration
JAMF has good instrutions on how to enable the RunScript mechanism for JAMF Login.  [RunScript Mechanism Documentation](https://docs.jamf.com/jamf-connect/1.17.0/administrator-guide/Login_Script.html)

You can also follow these instructions using the nano editor.
1. We have actually already enabled our workflow to enable this mechanism by using the `authchanger` command and to include `JamfConnectLogin:RunScript,privileged` in our postInstall script.
2. In this script we will tell Notify what to display and what JAMF Policies to run.  See below for an example script:

```
#!/bin/bash

###
###Notify Mechanism Enrollment Script
###

# Variables
jamfbinary="/usr/local/bin/jamf"

echo "Enrollment Beginning..." >> /tmp/output.txt

# Set a main image
# Image can be up to 660x105 it will scale up or down proportionally to fit

echo "Command: Image: /usr/local/images/TTG.png" >> /var/tmp/depnotify.log

# Set the Main Title at the top of the window

echo "Command: MainTitle: Welcome to your new Mac!" >> /var/tmp/depnotify.log

# Set the Body Text

echo "Command: MainText: We are setting up a few things for you automatically.\\nJust grab a coffee! It won't take long!." >> /var/tmp/depnotify.log

echo "Status: Preparing new machine" >> /var/tmp/depnotify.log 

echo "Command: Determinate: 9" >> /var/tmp/depnotify.log
sleep 3
echo "Status: Checking some Magic for you..." >> /var/tmp/depnotify.log 

#Checks for presence of JAMF Binary before continuing

while [ ! -f /usr/local/bin/jamf ]
do
	sleep 2
done

### Jamf Policy Triggers

sleep 3
echo "Command: Image: /usr/local/images/chrome.png" >> /var/tmp/depnotify.log
echo "Status: Installing Google Chrome" >> /var/tmp/depnotify.log 

${jamfbinary} policy -event "google_chrome"

sleep 3
echo "Command: Image: /usr/local/images/slack.png" >> /var/tmp/depnotify.log
echo "Status: Installing Slack" >> /var/tmp/depnotify.log 

${jamfbinary} policy -event "slack"

sleep 3
echo "Command: Image: /usr/local/images/CCloud.png" >> /var/tmp/depnotify.log
echo "Status: Installing Creative Cloud Launcher" >> /var/tmp/depnotify.log

${jamfbinary} policy -event "creativecloud"

sleep 3
echo "Command: Image: /usr/local/images/VLC.png" >> /var/tmp/depnotify.log
echo "Status: Installing VLC Media Player" >> /var/tmp/depnotify.log

${jamfbinary} policy -event "vlcplayer"

sleep 3
echo "Command: Image: /usr/local/images/printers.png" >> /var/tmp/depnotify.log
echo "Status: Installing Printer Software" >> /var/tmp/depnotify.log

${jamfbinary} policy -event "printers"

sleep 3
echo "Command: Image: /usr/local/images/security.png" >> /var/tmp/depnotify.log
echo "Status: Configuring Security Settings for your Computer" >> /var/tmp/depnotify.log

${jamfbinary} policy -event "security"

#sleep 3
#echo "Command: Image: /usr/local/images/Filevault.png" >> /var/tmp/depnotify.log
#echo "Status: Enabling FileVault Encryption" >> /var/tmp/depnotify.log
#
#${jamfbinary} policy -event "filevault"

###
### Welcome Screen
###

sleep 5
echo "Command: Image: /usr/local/images/logo.png" >> /var/tmp/depnotify.log
echo "Status: Almost done!" >> /var/tmp/depnotify.log 

###
### Clean Up
###

### Reset AuthChanger
#/usr/local/bin/authchanger -reset -Okta —DefaultJCRight

sleep 3
echo "Command: Quit" >> /var/tmp/depnotify.log

sleep 1
rm -rf /var/tmp/depnotify.log

```

This script displays different images, display text and runs the on-boarding JAMF Policies.  A better explaination of commands that can be run can be found here on JAMF's documentation page. [Notify Screen Mechanism](https://docs.jamf.com/jamf-connect/1.17.0/administrator-guide/Notify_Screen.html)


## Prestage Settings
When creating a Prestage Enrollment to work with there are a few settings and configuration profiles that need to be enabled so that Jamf Connect Login gets configured properly.

1. Configuration Profiles (PPPC for Filevault and Jamf Connect Login Settings) should be scoped to these new computers in the `Configuration Profiles` section of JAMF Pro as well as scoped to the Prestage Enrollment. [Configuration Profiles in Prestage Enrollment](https://github.com/zacharysfisher/connect-login-notify/blob/master/images/Config_Prestage_profiles.png)
2. Attach your Prestage package to the prestage enrollment.
3. Make sure that no account settings are enabled so that no accounts are created once computer gets enrolled.
4. The last step is to setup the General Settings tab with information specific to your deployment and select which Setup Assistant options you want to display to the user.

Once done, scope this enrollment to your devices.

## Okta Configuration
If you are using the Plist linked above, no additionaly configuration is needed to allow users to log into computers using their Okta accounts.  However if you wish to segregate users and allow certain users to become Admins and others Standard, you will need to add some keys to your Plist and take some additional configuration steps in Okta.  Below are the keys that need to be added to your plist:

| Key                    | Description                                                            | Example         |
|------------------------|------------------------------------------------------------------------|-----------------|
| OIDCAdminClientID  | OIDC ClientID for Okta Application that makes the user an admin user upon logging in. | `<key>OIDCAdminClientID</key>` `<string>0oa3qmcgyywWj1JR52p7</string>` |
| OIDCAccessClientID  | OIDC ClientID for Okta Application that makes the user a standard user upon logging in.    | `<key>OIDCAccessClientID</key>` `<string>0oa3qmdmdqJGOB1iG2p7</string>` |

## Authorization Rules ##
| Rule Domain | Description |                                 
|-------------|-------------|
| system.install.software | Checks when the user is installing new software (Pkg, bundled installers)   | 
| system.install.apple-software | Checks when user is installing Apple-provided software |
| system.preferences.network | Checked by the Admin framework when making changes to Network Preferences pane | 
| system.services.systemconfiguration.network | Checks when users edits Network Service settings |
| system.preferences.printing | Checked by the Admin frameowrk when making changes to Printers Preferences pane |
| system.print.operator | LPAdmin Operator Permissions |
| system.print.admin | Checks if user has Printer Admin rights |
| system.preferences.security | Checked by the Admin framework when making changes to the Security preference pane |
| system.preferences.security.remotepair | Used by Bezel Services to gate IR remote pairing. |
| com.apple.DiskManagement.reserveKEK | Used by diskmanagementd to allow use of the reserve KEK |
| system.services.directory.configure | For making Directory Services changes |
| system.preferences.accounts | Checked by the Admin framework when making changes to the Users & Groups preference pane |
| system.csfde.requestpassword | Used by CoreStorage Full Disk Encryption to request the user's password |
| system.preferences | Checked by the Admin framework when making changes to certain System Preferences |
| system.preferences.datetime | Checked by the Admin framework when making changes to the Date & Time preference pane |
| system.preferences.energysaver | Checked by the Admin framework when making changes to the Date Energy Saver pane |
| system.preferences.accessibility | Checked when making changes to the Accessibility Preferences |
| system.install.apple-config-data | Checked when installing Apple Config Data Updates |
| system.privilege.admin | checked when programs request to run a tool as root (e.g., some installers) |
| com.apple.desktopservices | For privileged file operations from within the Finder |
| system.preferences.startupdisk | Checked by the Admin framework when making changes to the Startup Disk preference pane |
| system.preferences.sharing | Checked by the Admin framework when making changes to the Sharing preference pane |


## Deployment
To deploy the authorization/sudo pam module to machines you need components.
1. A Jamf Pro policy that runs the script in this repository `jamfconnect_pam_authorizationWrite_v1.sh`.  This can be set to *recurring* or *ongoing* frequency depending on your environment.
2. A Jamf Pro Policy that installs auth_file (this has a list of all the authorization rewrites you want to make on the target systems). `authorization_list.txt` in this repository.  This policy needs to have a custom trigger of `authFile`, scoped to `All Computers`, and set to an `ongoing` frequency.
3. A Jamf Pro policy that installs Jamf Connect Login since that is needed for all of the authorizaiton calls.  In the script in this repository, it uses *Jamf Connect Login Trigger* as a trigger but this can be changed.
4. A Jamf Pro Configuration profile that pushes the PAM module settings to the client.  Please refer to the **Set Keys for the PAM Module** section for the keys to include.
5. An Okta app that the user must have to make any sudo/authorization requests on the mac.  Refer to **Create an Okta Application to handle Authentication** for configuration.
6. Depending if you use Jamf Connect Login for logging into Macs, you will have to edit the authchanger command or you will have undesirable results.
