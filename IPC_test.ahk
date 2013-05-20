#Include IPC.ahk
SetWorkingDir, % A_WorkingDir

dhw := A_DetectHiddenWindows
DetectHiddenWindows, On
PID := DynaRun(code(), "IPC_" A_TickCount)
WinWait, % "ahk_pid " PID
if !(target := WinExist())
	ExitApp
DetectHiddenWindows, % dhw

Gui, Font, s9, Consolas
Gui, Add, Edit, w300 r5 -WantReturn
Gui, Add, Button, xp y+10 w88 h26 Default gSend, Send
Gui, Show
return
GuiClose:
ExitApp

Send:
GuiControlGet, data,, Edit1
IPC.send(data, target)
if (data = "quit") {
	OutputDebug, % A_ScriptName " is exiting."
	ExitApp
}
return

code() {
	rcvr =
	(LTrim
	`#Include IPC.ahk
	`#Persistent

	IPC.handler := "handler"
	return

	handler(COD, sender) {
		OutputDebug, `% (COD = "quit")
		              ? A_ScriptName " is exiting."
		              : "Data: " COD . " | Sender: " sender
		if (COD = "quit")
			SetTimer, Exit, -1
		return
		Exit:
		ExitApp
	}
	)
	return rcvr
}

DynaRun(Script, pipename:="") {
	if (pipename == "")
		pipename := "AHK" A_TickCount
	
	__PIPE_GA_ := DllCall("CreateNamedPipe", "Str", "\\.\pipe\" pipename
		, "UInt", 2, "Uint", 0, "UInt", 255, "UInt", 0, "UInt", 0, "Ptr", 0, "Ptr", 0)
	__PIPE_    := DllCall("CreateNamedPipe", "Str","\\.\pipe\" pipename
		, "UInt", 2, "UInt", 0, "UInt", 255, "UInt", 0, "UInt", 0, "Ptr", 0, "Ptr", 0)
	
	if (__PIPE_ == -1 || __PIPE_GA_ == -1)
		return false
	Run, %A_AhkPath% "\\.\pipe\%pipename%",, UseErrorLevel HIDE, PID
	if ErrorLevel
		MsgBox, 262144, ERROR
		, % "Could not open file:`n" __AHK_EXE_ """\\.\pipe\" pipename """"
	
	DllCall("ConnectNamedPipe", "Ptr", __PIPE_GA_, "Ptr", 0)
	DllCall("CloseHandle", "Ptr", __PIPE_GA_)
	DllCall("ConnectNamedPipe", "Ptr", __PIPE_, "Ptr", 0)
	Script := (A_IsUnicode ? Chr(0xfeff) : (Chr(239) . Chr(187) . Chr(191))) Script
	if !DllCall("WriteFile", "Ptr", __PIPE_, "Str", Script
		, "UInt", (StrLen(Script)+1)*(A_IsUnicode ? 2 : 1), "UInt*", 0, "Ptr", 0)
		return A_LastError
	DllCall("CloseHandle", "Ptr", __PIPE_)
	return PID
}