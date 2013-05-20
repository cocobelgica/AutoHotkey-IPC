class IPC
{
	
	static _ := IPC.__init__()

	__New() {
		return false
	}

	send(ByRef data, ByRef target) {

		VarSetCapacity(CDS, 3*A_PtrSize, 0)
		szBytes := (StrLen(data) + 1) * (A_IsUnicode ? 2 : 1)

		NumPut(szBytes, CDS, A_PtrSize)
		NumPut(&data, CDS, 2*A_PtrSize)
		
		dhw := A_DetectHiddenWindows
		DetectHiddenWindows, On
		SendMessage, 0x4a, % A_ScriptHwnd, &CDS,, % "ahk_id " target
		DetectHiddenWindows, % dhw
		
		return ErrorLevel
	}

	__receive(lParam) {
		static data , sender

		StrAddress := NumGet(lParam + 2*A_PtrSize)
		COD := StrGet(StrAddress)
		
		;(IPC.handler).(COD)
		data := COD , sender := this
		SetTimer, IPC_onCOPYDATA, -1
		return true
		
		IPC_onCOPYDATA:
		(IPC.handler).(data, sender)
		data := "" , sender := ""
		return
	}

	__init__() {
		static init

		if init
			return
		this.base := IPC.__BASE__
		init := true
		return []
	}

	class __BASE__
	{

		__Set(k, v, p*) {
			
			if (k = "handler") {
				if !IsFunc(v)
					throw Exception("Invalid handler.", -1)
				OnMessage(0x4a, "IPC.__receive")
			}

			return this._[k] := v
		}

		__Get(k, p*) {
			if this._.HasKey(k)
				return this._[k, p*]

		}
	
	}

}