#!/bin/bash

###
###Notify Mechanism Enrollment Script
###

# Variables
jamfbinary="/usr/local/bin/jamf"

echo "Enrollment Beginning..." >> /var/log/jamf.log

# Set a main image
# Image can be up to 660x105 it will scale up or down proportionally to fit

echo "Command: Image: /usr/local/images/swl_logo.png.png" >> /var/tmp/depnotify.log

# Set the Main Title at the top of the window

echo "Command: MainTitle: Welcome to Sidewalk Labs!" >> /var/tmp/depnotify.log

# Set the Body Text

echo "Command: MainText:Please give us a few minutes to setup your computer for use!\\nJust grab a coffee! It won't take long!." >> /var/tmp/depnotify.log

echo "Status: Preparing new machine" >> /var/tmp/depnotify.log 
Sleep 5
echo "Command: Determinate: 9" >> /var/tmp/depnotify.log
sleep 5
echo "Status: Enrolling machine with Sidewalk Labs" >> /var/tmp/depnotify.log 
Sleep 5
#adding a safety net here to make sure the Jamf Binary is present. Just in case there is some delay on the installation via MDM

while [ ! -f /usr/local/bin/jamf ]
do
	sleep 2
done

### Jamf Policy Triggers

sleep 5
echo "Command: MainText: Installing applications such as Chrome, Slack, and Creative Cloud on your Computer." >> /var/tmp/depnotify.log
echo "Command: Image: /usr/local/images/chrome.png" >> /var/tmp/depnotify.log
echo "Status: Installing Google Chrome" >> /var/tmp/depnotify.log 

${jamfbinary} policy -event "google_chrome"

sleep 5
echo "Command: Image: /usr/local/images/slack.png" >> /var/tmp/depnotify.log
echo "Status: Installing Slack" >> /var/tmp/depnotify.log 

${jamfbinary} policy -event "slack"

sleep 5
echo "Command: Image: /usr/local/images/CCloud.png" >> /var/tmp/depnotify.log
echo "Status: Installing Creative Cloud Launcher" >> /var/tmp/depnotify.log

${jamfbinary} policy -event "creativecloud"

sleep 3
echo "Command: Image: /usr/local/images/VLC.png" >> /var/tmp/depnotify.log
echo "Status: Installing VLC Media Player" >> /var/tmp/depnotify.log

${jamfbinary} policy -event "vlcplayer"

sleep 3
echo "Command: MainText: Printers and Drivers" >> /var/tmp/depnotify.log
echo "Command: Image: /usr/local/images/printers.png" >> /var/tmp/depnotify.log
echo "Status: Installing Printer Software" >> /var/tmp/depnotify.log

${jamfbinary} policy -event "printers"

sleep 3
echo "Command: MainText: Security Policies and Patches" >> /var/tmp/depnotify.log
echo "Command: Image: /usr/local/images/security.png" >> /var/tmp/depnotify.log
echo "Status: Configuring Security Settings for your Computer" >> /var/tmp/depnotify.log

${jamfbinary} policy -event "security"

sleep 3
echo "Command: Image: /usr/local/images/appleLogo.png" >> /var/tmp/depnotify.log
echo "Status: Installing latest Software Updates form Apple."

softwareupdate -ia

#sleep 3
#echo "Command: Image: /usr/local/images/Filevault.png" >> /var/tmp/depnotify.log
#echo "Status: Enabling FileVault Encryption" >> /var/tmp/depnotify.log
#
#${jamfbinary} policy -event "filevault"

###
### Welcome Sidewalk Labs Screen
###

echo "Command: Image: /usr/local/images/swl_logo.png" >> /var/tmp/depnotify.log
echo "Command: MainText: If you require any assistance with your new computer, please do not hesitate to contact support at support@sidewalklabs.com"
echo "Status: Almost done!" >> /var/tmp/depnotify.log 

sleep 15
###
### Clean Up
###

### Reset AuthChanger
#/usr/local/bin/authchanger -reset -Okta —DefaultJCRight

sleep 3
echo "Command: Quit" >> /var/tmp/depnotify.log

sleep 1
rm -rf /var/tmp/depnotify.log

