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

<a href="Prestage Package Configuration"><img src="https://github.com/zacharysfisher/connect-login-notify/blob/master/images/package_prestage.png" align="right" height="350" width="450" ></a>
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
/usr/local/bin/authchanger -reset -Okta -postAuth JamfConnectLogin:Notify JamfConnectLogin:RunScript,privileged


exit 0		## Success
exit 1		## Failure
```

Once this package is ready for building, make sure that you `sign` the package and upload it to your distribution points for deployment.

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
For 10.15 and on, a PCCC Configuration profile is needed.  ![PCCC Payload to allow EnableFDE](https://github.com/zacharysfisher/connect-login-notify/blob/master/images/PCCC_FDE.png)

## RunScript Configuration
JAMF has good instrutions on how to enable the RunScript mechanism for JAMF Login.  [RunScript Mechanism Documentation](https://www.jamf.com/resources/product-documentation/jamf-connect-administrators-guide/)

You can also follow these instructions using the nano editor.
1. We have actually already enabled our workflow to enable this mechanism by using the `authchanger` command and to include `JamfConnectLogin:RunScript,privileged` in our postInstall script.
2. In this script we will tell Notify what to display and what JAMF Policies to run.  See the script in this repo for an example script that is modelled after information that JAMF provides.  I have also attached a script that renames computers based on a users first name and last name from their Okta Profile.



This script displays different images, display text and runs the on-boarding JAMF Policies.  A better explaination of commands that can be run can be found here on JAMF's documentation page. [Notify Screen Mechanism](https://www.jamf.com/resources/product-documentation/jamf-connect-administrators-guide/)


## Prestage Settings
When creating a Prestage Enrollment to work with there are a few settings and configuration profiles that need to be enabled so that Jamf Connect Login gets configured properly.

1. Configuration Profiles (PPPC for Filevault and Jamf Connect Login Settings) should be scoped to these new computers in the `Configuration Profiles` section of JAMF Pro as well as scoped to the Prestage Enrollment. <a href="Configuration Profiles in Prestage Enrollment"><img src="https://github.com/zacharysfisher/connect-login-notify/blob/master/images/Config_Prestage_profiles.png" height="350" width="250" ></a>
2. Attach your Prestage package to the prestage enrollment.
3. For Account Settings, in Prestage Enrollment.  Make you select to create an Admin Account.  Here you can hoose tho keep the account hidden as well as skipping user creaiton, which is something we want Jamf Connect Login to handle.  ![Account Settings](https://github.com/zacharysfisher/connect-login-notify/blob/master/images/prestage_account_settings.png)
4. The last step is to setup the General Settings tab with information specific to your deployment and select which Setup Assistant options you want to display to the user.

Once done, scope this enrollment to your devices.

## Okta Configurations for Standard / Admin Users
If you are using the Plist linked above, no additionaly configuration is needed to allow users to log into computers using their Okta accounts.  However if you wish to segregate users and allow certain users to become Admins and others Standard, you will need to add some keys to your Plist and take some additional configuration steps in Okta.  Below are the keys that need to be added to your plist:

| Key                    | Description                                                            | Example         |
|------------------------|------------------------------------------------------------------------|-----------------|
| OIDCAdminClientID  | OIDC ClientID for Okta Application that makes the user an admin user upon logging in. | `<key>OIDCAdminClientID</key>` `<string>0oa3qmcgyywWj1JR52p7</string>` |
| OIDCAccessClientID  | OIDC ClientID for Okta Application that makes the user a standard user upon logging in.    | `<key>OIDCAccessClientID</key>` `<string>0oa3qmdmdqJGOB1iG2p7</string>` |


## Deployment

1) Upload your prestage package to your specified Distribution point.  As of a recent relase of JAMF Pro this no longer needs to be a Cloud Distribution point but it does require HTTPS.  In addition to this, make sure that your PKG is signed.
2) Double check that your configuration profiles are scopes to proper machines in the Configuration Profiles section of JAMF Pro and the same configuration profiles are selected for prestage enrollment deployment.  
3) If you are going to use the rename script that is in this Repo, make sure it is being called during notify.  Make sure that the Okta API key it uses is a Read Only key.
4) Double check your Prestage settings to make sure that account creation is skipped and that the Prestage is assigned to the proper devices.
