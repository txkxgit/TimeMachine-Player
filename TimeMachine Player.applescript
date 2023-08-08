##################################################################
# TimeMachine Player
#
# Allows to enable and disable local TimeMachine Backups
#
#
# Timo Kahle
# 2016-02-02
#
# Changes
# v1.0 (2016-02-02)
# o Initial version
#
# v1.2 (2016-07-10)
# o Changed Button labels
# o Renamed Quit Button to "Continue" as "Quit" was misleading
# o Exchanged application icons
# - Removed debug output
#
# v1.2.1 (2016-08-14)
# o Fixed bug where options "Continue" & "Start" where offered, instead of "Quit" & "Start" if TM is not running
#
# v1.2.2 (2016-09-21)
# o Fixed options
#
# v1.3.0 (2017-02-05)
# + Added function to open the TimeMachine Prefernce Pane when a job is started for a visual status overview
#
# v1.3.1 (2018-05-21)
# + Open the TimeMachine Prefernce Pane also if a job is already running and "Continue" is selected by the user, if it's not already open
# + Added  dialog in case TimeMachine not configured or not connected, in addition to the notification for more immediate user feedback
#
# v1.3.2 (2018-05-22)
# + Added "activate" statement before displaying dialogs to ensure dialogs are displayed frontmost
#
# v1.3.5 (2020-09-11)
# + Added option to speed up TimeMachine disabling throttling with 'debug.lowpri_throttle_enabled'
# o Exchanged Thk with txkx
#
# v1.3.6 (2020-11-06)
# Moved CMD_SPEEDUP_TM_BACKUP to the beginning to properly apply it
# 
# ToDo
# o Refactor ExecCommandAdmin to ExecCommand(cmd, adminMode) to handle both options (w/ or w/o Admin rights with a single method)
# o Call ExecCommand with or w/o Admin rights where necessary
#
##################################################################

# Variables and Constants
property APP_NAME : "TimeMachine Player"
property APP_VERSION : "1.3.6"
property APP_ICON : "applet.icns"
property APP_ICON_ERROR : "TimeMachine Player_error.icns"
property APP_ICON_INFO : "TimeMachine Player_info.icns"
property TIMEOUT_SEC : 3600 -- 60 minutes

# OS X Version check details
property OSX_VERSION_MIN : "10.12"

# Maintenance shell commands (require admin privileges)
property CMD_TM_DESTINATIONINFO : "tmutil destinationinfo"
property RES_TM_NO_DESTINATION : "tmutil: No destinations configured"
property CMD_TM_VOLUME : "tmutil destinationinfo | grep 'Mount Point' | sed 's/.*: //'"
property RES_TM_RUNNING_INDICATOR : "Running = 1"
property CMD_TM_RUNNING : "tmutil status"
property CMD_TM_START : "tmutil startbackup -r"
property CMD_TM_STOP : "tmutil stopbackup"
property CMD_TM_PREFPANE_OPEN : "open /System/Library/PreferencePanes/TimeMachine.prefPane/"
property CMD_TM_PREFPANE_EXIT : "killall -9 'System Preferences'"
property CMD_SPEEDUP_TM_BACKUP : "sudo sysctl debug.lowpri_throttle_enabled=0"

# Button Texts
property BTN_CANCEL : "Cancel"
property BTN_OK : "OK"
property BTN_CONTINUE : "Continue"
property BTN_QUIT : "Quit"
property BTN_EXIT : "Exit"
property BTN_STOP : "Stop"
property BTN_START : "Start"



##################################################################


# Main
on run
	# Define the app icon for dialogs
	set dlgIcon to (path to resource APP_ICON)
	set dlgIcon_Error to (path to resource APP_ICON_ERROR)
	set dlgIcon_Info to (path to resource APP_ICON_INFO)
	set dlgTitle to APP_NAME & " (" & APP_VERSION & ")"
	
	# Helpers
	set isConfiguredTMVol to false
	set isMountedTMVol to false
	set isRunningTM to false
	
	# Resources
	set dlg_Info_OSVersion_Check_Failed to APP_NAME & " is not supported on your OS X version and cannot be run. Please update your OS X version."
	set dlg_Error_CMDFailed to "An error occured while running " & APP_NAME & ". Please try again."
	set dlg_Error_Unkown to "An unknown error occurred. Please run " & APP_NAME & " again."
	set dlg_Info_NoTM to "Your TimeMachine Volume is currently not connected." & return & "Please connect your TimeMachine Volume and run " & APP_NAME & " again."
	set dlg_Error_TM_Not_Configured to "TimeMachine is not configured on your computer. Please configure a TimeMachine Backup Volume and run " & APP_NAME & " again."
	set dlg_Info_TM_Running to "A TimeMachine Backup is currently running. Do you want to STOP it or leave it running and QUIT?"
	set dlg_Info_TM_NotRunning to "Currently no TimeMachine Backup job is running. " & return & return & "If you want to run a TimeMachine Backup now, select RUN or QUIT to not do anything."
	set dlg_Info_Started_TM to "Started TimeMachine Backup"
	set dlg_Info_Stopped_TM to "Stopped TimeMachine Backup"
	set dlg_Notification_Subtitle_StopTM to "TM Stop"
	set dlg_Notification_Subtitle_StartTM to "TM Start"
	set dlg_Notification_Subtitle_ConfigFailed to "Config Error"
	
	
	
	# Check OS X Version for compatibility
	if OSXVersionSupported() is false then
		activate
		display dialog dlg_Info_OSVersion_Check_Failed & return with title dlgTitle buttons {BTN_OK} default button {BTN_OK} cancel button {BTN_OK} with icon dlgIcon_Error
	end if
	
	# Speedup the Backup
	set speedupTMBackup to ExecCommand(CMD_SPEEDUP_TM_BACKUP)
	delay 5
	
	# 1. Check if TimeMachine is currently running
	# If TRUE we offer to stop it (default: keep it running)
	# If FALSE we need to first check if it is configured and the Volume is available/mounted to offer starting it
	
	# Check if TimeMachine Backup is running
	set isRunningTM to ExecCommand(CMD_TM_RUNNING)
	if isRunningTM contains RES_TM_RUNNING_INDICATOR then
		set isRunningTM to true
		
		# Offer to stop TimeMachine
		#set theAction to display dialog dlg_Info_TM_Running with title dlgTitle buttons {BTN_CONTINUE, BTN_STOP} default button {BTN_CONTINUE} cancel button {BTN_CONTINUE} with icon dlgIcon_Info
		activate
		set theAction to display dialog dlg_Info_TM_Running with title dlgTitle buttons {BTN_CONTINUE, BTN_STOP} default button {BTN_CONTINUE} with icon dlgIcon_Info
		set retVal to button returned of theAction
		if retVal is BTN_STOP then
			#display alert "DEBUG : cancel action: STOP : " & retVal
			# TODO
			set stopTMJob to ExecCommand(CMD_TM_STOP)
			# TODO
			# + Add check for return value
			display notification dlg_Info_Stopped_TM with title dlgTitle subtitle dlg_Notification_Subtitle_StopTM
		else
			# Added in 1.3.1: Continue running, check if TimeMachine Prefernce Pane is open & if not, open it
			set openTMPrefPane to ExecCommand(CMD_TM_PREFPANE_OPEN)
			return
		end if
	else
		# TimeMachine is not running, so we need to check if if it is configured and the Volume is available/mounted to offer starting it
		set isRunningTM to false
		
		# Check if TimeMachine is configured on this computer
		if IsConfiguredTM() is true then
			set isConfiguredTMVol to true
			
			# Check if TimeMachine is mounted on this computer
			if IsMountedTM() is true then
				set isMountedTMVol to true
			end if
		end if
		
		
		# If TM is configured and mounted, check if currently a TM  Backup is running
		if isConfiguredTMVol is true and isMountedTMVol is true then
			# TODO
			# Offer to start TimeMachine
			activate
			set theAction to display dialog dlg_Info_TM_NotRunning with title dlgTitle buttons {BTN_EXIT, BTN_START} default button {BTN_START} cancel button {BTN_EXIT} with icon dlgIcon_Info
			set retVal to button returned of theAction
			if retVal is BTN_START then
				#display alert "DEBUG : cancel action: START : " & retVal
				# TODO
				# Ask whether to start TimeMachine
				set openTMPrefPane to ExecCommand(CMD_TM_PREFPANE_OPEN)
				#set speedupTMBackup to ExecCommand(CMD_SPEEDUP_TM_BACKUP)
				set startTMJob to ExecCommand(CMD_TM_START)
				# TODO
				# + Add check for return value
				# + Send Notification
				display notification dlg_Info_Started_TM with title dlgTitle subtitle dlg_Notification_Subtitle_StartTM
			else
				return
			end if
		else
			set theResult_CheckFailed to ""
			
			if isConfiguredTMVol is false then
				set theResult_CheckFailed to dlg_Error_TM_Not_Configured
			end if
			
			if isMountedTMVol is false then
				set theResult_CheckFailed to dlg_Info_NoTM
			end if
			
			display notification theResult_CheckFailed with title dlgTitle subtitle dlg_Notification_Subtitle_ConfigFailed
			
			activate
			display dialog dlg_Notification_Subtitle_ConfigFailed & return & return & theResult_CheckFailed with title dlgTitle buttons {BTN_EXIT} default button {BTN_EXIT} cancel button {BTN_EXIT} with icon dlgIcon_Info
		end if
		
	end if
	
end run


##################################################################
# Helper functions
##################################################################

# Run a command without admin privileges
on ExecCommand(thisAction)
	
	try
		#Introduce timeout to prevent timing out of large transfers
		with timeout of TIMEOUT_SEC seconds
			#set returnValue to do shell script (thisAction & " 2>&1")
			set returnValue to do shell script (thisAction)
		end timeout
		
		return returnValue
	on error errMsg
		if errMsg contains "no such file" then
			return "Warning: " & errMsg
		else
			return "Error: " & errMsg
		end if
	end try
end ExecCommand


# Check if TimeMachine Backup configured
on IsConfiguredTM()
	set tm_Config to do shell script CMD_TM_DESTINATIONINFO
	
	if tm_Config does not contain RES_TM_NO_DESTINATION then
		return true
	else
		return false
	end if
end IsConfiguredTM


# Get TimeMachine Volume and check if it is mounted
on IsMountedTM()
	set tm_Mounted to do shell script CMD_TM_VOLUME
	
	if tm_Mounted is not "" then
		return true
	else
		return false
	end if
end IsMountedTM


# Valid OS X version
on OSXVersionSupported()
	set strOSXVersion to system version of (system info)
	considering numeric strings
		set IsSupportedOSXVersion to strOSXVersion is greater than or equal to OSX_VERSION_MIN
	end considering
	
	return IsSupportedOSXVersion
end OSXVersionSupported


# Handle onQuit events
on quit
	return
end quit