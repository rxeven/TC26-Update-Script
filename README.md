# TC26 Update Script
 Script for updating software, configurations and logging HWIDs for Zebra TC26 Devices.

## Requirements
### 1. Minimal ADB and Fastboot
Minimal ADB and Fastboot needs to be installed to overwrite and install the new files, and to get the HWID of the device.
Minimal ADB and Fastboot can be downloaded [from Android Data Host.](https://androiddatahost.com/uq6us)

Alternatively, ADB and Fastboot can be used in portable mode if using the installer on the system used to update the devices is not an option. Simply copy the */Minimal ADB and Fastboot/* folder from a system with the application installed to the root path of the script.
### 2. Device In USB Debugging Mode
The device can be set to USB Debugging mode by pressing the *"Build Number"* field under *Settings>About phone* then turning on *"USB Debugging"* under *Settings>System>Developer* Options.
## Usage
Configurations for what files the script will update is set by entering Y for Yes and N for No in the prompts at the script startup.
### HWID Logging
If enabled, will prompt for a friendly name or device description and append to the devices.txt file as "HWID: \<HWID of plugged in device> - Description: TC26-\<User defined description>". If the devices.txt file does not exist it will be created at the root path of the script.
### Update Config Files
If enabled, will copy any .json file at the root path of the script to the /sdcard directory of the device. Any files on the device with the same name will be overriden.
### Update APK
If enabled, will install any .apk file at the root path of the script to the device.
### Update DataWedge
If enabled, will copy any .db file at the root path of the script to the /sdcard directory of the device. Any files on the device with the same name will be overriden.