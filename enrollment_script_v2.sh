#!/bin/bash

#variables
NOTIFY_LOG="/var/tmp/depnotify.log"
#TOKEN_BASIC="/var/tmp/idtokenbasic"
#TOKEN_RAW="/var/tmp/idtokenraw"
#TOKEN_GIVEN_NAME=$(echo "$(cat $TOKEN_BASIC)" | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep given_name)
#TOKEN_UPN=$(echo "$(cat $TOKEN_BASIC)" | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep upn)
jamfbinary="/usr/local/bin/jamf"

echo "Enrollment beginning" >> /var/log/jamf.log
echo "Starting Notify Run" >> $NOTIFY_LOG

# Sidewalk Welcome
echo "Command: Image: /usr/local/images/swl_logo.png.png" >> $NOTIFY_LOG
echo "Command: MainTitle: Welcome to Sidewalk Labs!" >> $NOTIFY_LOG
echo "Command: MainText: Your Mac is now managed and will be automatically configured for you." >> $NOTIFY_LOG
# Define the number of increments for the progress bar
echo "Command: Determinate: 11" >> $NOTIFY_LOG
echo "Status: Preparing your new Mac..." >> $NOTIFY_LOG
sleep 15

#adding a safety net here to make sure the Jamf Binary is present. Just in case there is some delay on the installation via MDM

while [ ! -f /usr/local/bin/jamf ]
do
	sleep 2
done

#2 - Setting up single sign-on passwords for local account

echo "Command: Image: /usr/local/images/oktalogo.png" >> $NOTIFY_LOG
echo "Command: MainTitle: Tired of remembering multiple passwords?" >> $NOTIFY_LOG
echo "Command: MainText: We use Okta to help you log in to each of our corporate services. You can use your email address and Okta password to sign into all necessary applications." >> $NOTIFY_LOG
echo "Status: Setting the account password for your Mac to sync with your Okta password..." >> $NOTIFY_LOG
sleep 10

#3 - Self Service makes the Mac life easier

echo "Command: Image: /Applications/Self Service.app/Contents/Resources/AppIcon.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Self Service makes the Mac life easier" >> $NOTIFY_LOG
echo "Command: MainText: Self Service includes helpful bookmarks and installers for other applications that may interest you." >> $NOTIFY_LOG
echo "Status: Installing Jamf Self Service..." >> $NOTIFY_LOG
sleep 10

#4 - Application Policies

echo "Command: Image: /System/Library/CoreServices/Install in Progress.app/Contents/Resources/Installer.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Installing everything you need for your first day" >> $NOTIFY_LOG
echo "Command: MainText: All the apps you'll need today are already being installed. Once we're ready to start, you'll find Google Chrome, Slack, VLC Player and Creative Cloud are all ready to go. Launch apps from the dock and have fun!" >> $NOTIFY_LOG
sleep 5
echo "Command: Image: /usr/local/images/chrome.png" >> $NOTIFY_LOG
echo "Status: Installing Google Chrome" >> $NOTIFY_LOG 

${jamfbinary} policy -event "google_chrome"

sleep 5
echo "Command: Image: /usr/local/images/slack.png" >> $NOTIFY_LOG
echo "Status: Installing Slack" >> $NOTIFY_LOG 

${jamfbinary} policy -event "slack"

sleep 5
echo "Command: Image: /usr/local/images/CCloud.png" >> $NOTIFY_LOG
echo "Status: Installing Creative Cloud Launcher" >> $NOTIFY_LOG

${jamfbinary} policy -event "creativecloud"

sleep 3
echo "Command: Image: /usr/local/images/VLC.png" >> $NOTIFY_LOG
echo "Status: Installing VLC Media Player" >> $NOTIFY_LOG

${jamfbinary} policy -event "vlcplayer"

#5 Printers and Security Policies

echo "Command: Image: /usr/local/images/printers.png" >> $NOTIFY_LOG
echo "Status: Installing Printer Software" >> $NOTIFY_LOG

${jamfbinary} policy -event "printers"

echo "Command: Image: /usr/local/images/security.png" >> $NOTIFY_LOG
echo "Status: Configuring Security Settings for your Computer" >> $NOTIFY_LOG

${jamfbinary} policy -event "security"

sleep 3
echo "Command: Image: /usr/local/images/appleLogo.png" >> $NOTIFY_LOG
echo "Status: Installing latest Software Updates form Apple." >> >> $NOTIFY_LOG

softwareupdate -ia

echo "Command: Image: /usr/local/images/swl_logo.png" >> $NOTIFY_LOG
echo "Command: MainText: If you require any assistance with your new computer, please do not hesitate to contact support at support@sidewalklabs.com" >> $NOTIFY_LOG
echo "Status: Almost done!" >> $NOTIFY_LOG 
sleep 15

echo "Command: Quit" >> $NOTIFY_LOG

sleep 1
rm -rf $NOTIFY_LOG
