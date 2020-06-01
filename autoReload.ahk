#Warn, UseUnsetLocal, Off ; this is one of the exceptions where we don't want warnings for unset local vars
; TODO have the timer run as a seperate process and reload or restart (whichever is appropriate) client script via command line
; TODO parse host script for includes to monitor
autoReload()
{
	static startTime := autoReload() ; bootstraps the timer running this function at load time
	local currentScriptTime
	if (startTime)
	{
		FileGetTime, currentScriptTime, %A_ScriptFullPath%
		if not ErrorLevel
		{
			if (startTime != currentScriptTime) ; the host script has been modified since this instance got started
			{
				Critical ; it's go time so we take over
				; first we see if there is a error message from a previous try to reload and close it
				; this way we get to see what the error is but without the need to manually dismiss the message after fixing it
				WinWait, %A_ScriptName%, Error, 0
				WinClose, %A_ScriptName%, Error
				Reload ; now try to run the new version. if that is successful startTime will get updated by the new instance
				 ; we only ever reach this point if the scripts new version has errors
				startTime := currentScriptTime ; make sure we don't run into an endless loop of unsuccessful reloads
				return
			}
		} else MsgBox, something went wrong here...
	} else ; bootstrapper starts here
	{
		; TODO check if the current instance is the only one running so we can deal with scripts that use #SingleInstance off
		FileGetTime, startTime, %A_ScriptFullPath%
		ToolTip, Reload successful
		Sleep, 1000
		ToolTip
		SetTimer, autoReload, 500, -2147483648 ; run at lowest priority so we don't interfere with any other thread
		return startTime
	}
}

/*
returns 1 on the first finding of a file that
	- is not commented out
	- does actually exist
	- has changed since the last invocation
This function is only ever to be called without a parameter. This will cause scanForChanges() to start at the root of the script as
denoted by A_ScriptFullPath. The function will then recursively check any valid includes.
Finally, if no change has been detected scanForChanges() will return 0 thus allowing for the following usage:
	if scanForChanges() reload
*/
scanForChanges(filePath := "")
{
	static includeList
	if (includeList) ; true after the first time this function was called, similar to the bootstrapper above
	{
		if (filePath)
		{
		}
	} else ; this is the first invocation after the script has started
	{
		FileGetTime, startTime, %A_ScriptFullPath%
		includeList[%A_ScriptFullPath%] := startTime
		return 0 ; since script execution has only just started we are done here
	}
}
