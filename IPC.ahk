class IPC
{
	
	static __INIT__ := IPC.__INIT_CLASS__()
	__CHECK_INIT__ := IPC.__INIT_CLASS__()

	__New(target, handler:="") {
		this.Insert("_", [])
		
		this.target := target
		if handler
			this.handler := handler

		IPC.__[this.target] := &this
	
	}

	__Delete() {
		IPC.__.Remove(this.target)
	}

	__Set(k, v, p*) {

		if (k = "__CHECK_INIT__")
			return v

		if (k = "target") {
			dhw := A_DetectHiddenWindows
			DetectHiddenWindows, On
			if !(v:=WinExist(v))
				throw Exception("Target script does not exist.", -1)
			DetectHiddenWindows, % dhw
		
		} else if (k = "handler") {
			if (v && !IsFunc(v))
				throw Exception("Invalid Handler", -1)
		
		}
		
		return this._[k] := v
	}

	class __Get extends IPC.__PROPERTIES__
	{

		__(k, p*) {
			if this._.HasKey(k)
				return this._[k, p*]
		}
	}

	send(ByRef data) {

		VarSetCapacity(CDS, 3*A_PtrSize, 0)
		szBytes := (StrLen(data) + 1) * (A_IsUnicode ? 2 : 1)

		NumPut(szBytes, CDS, A_PtrSize)
		NumPut(&data, CDS, 2*A_PtrSize)
		
		dhw := A_DetectHiddenWindows
		DetectHiddenWindows, On
		SendMessage, 0x4a, % A_ScriptHwnd, &CDS,, % "ahk_id " this.target
		DetectHiddenWindows, % dhw
		
		return ErrorLevel
	}

	receive(data) {
		if !this.handler
			return
		return (this.handler).(this, data)
	}

	__onCOPYDATA(lParam) {
		static sender , data

		StrAddress := NumGet(lParam + 2*A_PtrSize)
		COD := StrGet(StrAddress)
		
		if (sender:=(IPC.__.HasKey(this) ? IPC.__[this] : "")) {
			data := COD
			SetTimer, IPC_onCOPYDATA, -1
		}
		return true

		IPC_onCOPYDATA:
		Object(sender).receive(data)
		sender := "" , data := ""
		return

	}

	__INIT_CLASS__() {
		static init 

		if init
			return
		init := true
		IPC.__ := [] , IPC._ := []
		IPC.base := {__Set:IPC.__baseSet, __Get:IPC.__baseGet}
		
		IPC.monitor := true
		return
	}

	__baseSet(k, v, p*) {
		
		if (k = "monitor") {
			args := (v ? [0x4a, "IPC.__onCOPYDATA"] : [0x4a, ""])
			OnMessage(args*)
		}

		return this._[k] := v
	}

	class __baseGet extends IPC.__PROPERTIES__
	{

		__(k, p*) {
			if this._.HasKey(k)
				return this._[k, p*]
		}

		monitor() {
			return (OnMessage(0x4a) = "IPC.__onCOPYDATA") ? true : false
		}
	}

	class __PROPERTIES__
	{
		__Call(target, name, params*) {
			if !(name ~= "i)^(base|__Class)$") {
				return ObjHasKey(this, name)
				       ? this[name].(target, params*)
				       : this.__.(target, name, params*)
			}
		}
	}
}