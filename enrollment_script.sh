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