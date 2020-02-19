# jamf_connect_notify

## Overview
This page will explain how to configure Jamf Connect Login's Notify and Run Script mechanisms (Pluggable Authentication Module) to be used for user provisioning.


## Contents
* Prestage Package Configuration
* Prestage Settings
* RunScript Configuration
* Okta Configurations for Standard / Admin Users
* Plist Configuration for Jamf Connect Login
* Deployment


    

## Prestage Package Configuration
First we need to build our Pre-Stage package to look like the image below:
![Prestage Package Configuration](https://github.com/zacharysfisher/connect-login-notify/blob/master/images/package_prestage.png).  As you can see, we are installing both Sync and Login to a temporary location which we will then all to install using the `installer` binary later in the process.  We are also installing out image files and the notify script location which will also be called later on in this provisioning process.
2. Click Add Application and click Create New App.
3. Post Install Script should look like below:

```
#!/bin/sh
## postinstall

# Install JCL + Sync
installer -pkg /tmp/Jamf\ Connect\ Login-1.9.0.pkg -target / 
installer -pkg /tmp/Jamf\ Connect\ Sync-1.1.0.pkg -target /

# Enable Notify - Run Script
/usr/local/bin/authchanger -reset -Okta —DefaultJCRight -postAuth JamfConnectLogin:RunScript,privileged JamfConnectLogin:Notify


exit 0		## Success
exit 1		## Failure
```

4. On the next screen, Name your application and for login Redirect URI enter in: `https://127.0.0.1/jamfconnect` and then hit save.
5. Your app is now created.  You can assign it to users.  However, before you do so we need to configure a few more thing.  Make your App look like the following:
![OIDC App Settings](https://user-images.githubusercontent.com/17932646/61080455-18cd5100-a3f3-11e9-90fc-562d7093d1a7.png)
6. Lastly, scroll down and save the value of ClientID for use later.

## Set Keys for the PAM Module
Keys for the PAM Module get written to same plist as other Jamf Connect Login Keys: `/Library/Preferences/com.jamf.connect.login.plist`

| Key                    | Description                                                            | Example         |
|------------------------|------------------------------------------------------------------------|-----------------|
| AuthUIOIDCRedirectURI  | The Redirect URI the user is sent to after successful authentication.  | `<key>AuthUIOIDCRedirectURI</key>` `<string>https://127.0.0.1/jamfconnect</string>` |
| AuthUIOIDCProvider     | Specifies the IdP provider integrated with Jamf Connect Login          | `<key>AuthUIOIDCProvider</key>` `<string>Okta</string>` |
| AuthUIOIDCTenant       | Specifices the Tenant or Org of your IDP Instance                    | `<key>AuthUIOIDCTenant</key>` `<string>Acme</string>` |
| AuthUIOIDCClientID     | The Client ID of the added app in your IdP used to authenticate the user | `<key>AuthUIOIDCClientID</key>` `<string>0oad0gmia54gn3y8923h1</string>` |

These keys can either be set using a Configuration Profile with JAMF Pro or by using the defaults command.

Example Defaults command: `sudo defaults write /Library/Preferences/com.jamf.connect.login.plist AuthUIOIDCProvider -string Okta`

## Enable PAM
JAMF has good instrutions on how to enable the PAM module.  [PAM Module Documentation](https://docs.jamf.com/jamf-connect/1.4.1/administrator-guide/Pluggable_Authentication_Module_(PAM).html)

You can also follow these instructions using the nano editor.
1. Open terminal and edit the following file `sudo nano /etc/pam.d/sudo`
2. Once the editor opens, add the following to the 2nd of line of the file.  Right below `# sudo: auth account password session`: `auth sufficient pam_saml.so`
3. Press control + x to exit and then "y" and the enter key to save changes

Now you can use the `sudo` command and you should be prompted for Okta login.  The next step is to configure other authentication methods to use Okta as well.

## Configure which Authentication Calls to use PAM for
To configure the PAM module to use Okta Authentication for things like unlocking System Preferences and installing software, we must use the Security Tool that ships with macOS.  The file that controls the Auth Mechanism is `com.jamf.connect.sudosaml`.  You can read this file by typing the following into terminal:
`security authorizationdb read com.jamf.connect.sudosaml`

The results shoudl look like below:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>class</key>
	<string>evaluate-mechanisms</string>
	<key>comment</key>
	<string>Rule to allow for Azure authentication</string>
	<key>created</key>
	<real>569394749.63492501</real>
	<key>identifier</key>
	<string>authchanger</string>
	<key>mechanisms</key>
	<array>
		<string>JamfConnectLogin:AuthUINoCache</string>
	</array>
	<key>modified</key>
	<real>582579735.53209305</real>
	<key>requirement</key>
	<string>identifier authchanger and anchor apple generic and certificate leaf[subject.CN] = "Mac Developer: Joel Rennich (92Q527YFQS)" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */</string>
	<key>shared</key>
	<true/>
	<key>tries</key>
	<integer>10000</integer>
	<key>version</key>
	<integer>1</integer>
</dict>
</plist>
```

You will notice the `mechanisms` key.  Currently, it is set to `AuthUINoCache`.  If you would like Jamf Connect to not prompt the user for authentication for as long as the Okta Token length is set, change this to `AuthUI`.
###### Currently this feature does not work as intended, and JAMF has been notified.  No Estimate can be provided at this time for when it will be fixed. ######

To be able to use the PAM Module for Authentication we need to do the following steps:
1. Make a backup of the sudosaml file to use to overwrite the local authentication calls
2. Determine with authorizationdb calls you want to use Jamf Connect for
3. Backup the authorizationdb file you are about to overwrite with Jamf Connect
4. Replace local authentication rule with the jamf connect rule


### Make a backup of the sudosaml file to use to overwrite the local authentication calls###
To make a backup of the sudosaml file we need to use the security tool.  First you should go to a directory that you want to work out of.  Once there, you can run this command to make a backup:
`security authorizationdb read com.jamf.connect.sudosaml > sudosaml.org`

You now have a backup of the Jamf Connect mechanism for authentication.

### Determine which authorizationdb calls you want use Jamf Connect for ###
In macOS, there are many different authorization calls that are made when certain tasks are completed.  For this example, we will edit the authorization used to see if a user can install a pkg.  This authorization is `system.install.software`.  YOu can view the current rule for this call by using this command: `security authorizationdb read system.install.software`.  This default rule checks if the user is in the admin group to allow the installation of the package.  You can find a table of some calls to configure below.

### Backup the authorizationdb file you are about to overwrite with Jamf Connect ###
Now that we have determined what the authorization rule that we want to edit is we can replace the default macOS rule with the Jamf Connect one.  Before we do this, we should back up the macOS default rule in case things go wrong.  We can backup this file by typing this command: `security authorizationdb read system.install.software > installsoftware.org`.  

### Replace local authentication rule with Jamf Connect rule ###
Now we can add our Jamf Connect rule.  We do this by using the following command: `security authorizationdb write system.install.software < sudosaml.org`.  This will overwrite the rule with the backup of the jamf connect mechanism we made of backup of earlier.  you can verify this worked by typing `security authorizationdb read system.install.software` and you should see the Jamf Connect mechanism.

Now you can test this by trying to install a package.  If everything was configured properly, you should be prompted for an Okta login when you install Packages or use the `sudo` command in terminal.


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
