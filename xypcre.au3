#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=.\xypcre.ico
#AutoIt3Wrapper_Outfile=.\xypcre.exe
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=1.2.0
#AutoIt3Wrapper_Res_ProductVersion=1.2.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_Fileversion_First_Increment=Y
#AutoIt3Wrapper_Res_Field=ProductName|XYplorerPCRE
#AutoIt3Wrapper_Res_Description=PCRE scripting helper for XYplorer
#AutoIt3Wrapper_Res_Comment=https://www.github.com/SammaySarkar/xypcre
#AutoIt3Wrapper_Res_LegalCopyright=author: SammaySarkar
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/tc 0 /reel /gd
#AutoIt3Wrapper_Tidy_Stop_OnError=n
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/rm /so /rsln
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <SendMessage.au3>
; Opt('TrayIconHide', 1)
Opt('GUIOnEventMode', 1)

;if run without parameters, return programidentifier and quit
;an alternative programidentifier is the productname property
If ($CmdLine[0] == 0) Then
	ConsoleWrite("XYplorerPCRE")
	; if 1st param is abort, close a misbehaving xypcre by hwnd
ElseIf ($CmdLine[1] == 'abort') Then
	If ($CmdLine[2] <> '') Then WinKill(HWnd($CmdLine[2]))
	;close another xypcre by given hwnd (if cond. stops an error)
ElseIf ($CmdLine[0] == 2) Then
	Main()
EndIf
Exit

;main program
Func Main()
	Global Const $XYhWnd = $CmdLine[1] ; hwnd of calling XY process
	Global Const $IFS = $CmdLine[2] ; session $IFS variable
	Global Const $dwScript = 0x00400001 ; send data as script
	Global Const $dwString = 0x00400000 ; send data as string
	Global $Data ; contains latest sent/received data
	Global $pstep = -1 ; controls flow
	Global $nstep = 0 ; controls flow
	;params
	Global $op ; operation mode (0:match, 1:capture, 2: replace)
	Global $string ; the source string
	Global $pattern ; the regexp pattern
	Global $replace ; replacement pattern
	Global $sep ; separator for tokenized return
	Global $format ; return format (escaping, layout scheme)
	Global $index ; index of single token to return
	;strings
	Global Const $matchErrStr = "pcrematch() error"
	Global Const $replaceErrStr = "pcrereplace() error"
	Global Const $captureErrStr = "pcrecapture() error"
	Global Const $splitErrStr = "pcresplit() error"

	Global Const $hWnd = Dec(StringTrimLeft(GUICreate("xypcre"), 2)) _ ; msggui hwnd
			 & '|' & WinGetHandle(AutoItWinGetTitle()) ; main gui hwnd
	Global Const $WM_COPYDATA = 0x004A ; msg ID of WM_COPYDATA (dec: 74)
	GUIRegisterMsg($WM_COPYDATA, "IN_XYMSG")
	; GUISetState() ; GUI is hidden if commented out

	$op = MsgWaiter($dwScript) ;get op mode
	Switch $op
		Case 0
			opMatch()
		Case 1
			opCapture()
		Case 2
			opReplace()
		Case 3
			opSplit()
	EndSwitch

	Return
EndFunc   ;==>Main

;main data send/reception wait loop
;send $Data with XY loopbreaker, wait for XY send, put received to $Data
Func MsgWaiter($dwdata)
	ResetData()
	OUT_XYMSG($dwdata) ; send $Data with loopbreaker
	;$pstep incremented in IN_XYMSG() on each reception
	Do ; wait till then
		ContinueLoop
	Until $pstep == $nstep
	$nstep += 1 ;set $step target for next dataloop
	Return $Data ;assignable return
EndFunc   ;==>MsgWaiter

;fill $Data with XY IFS reset/loopbreaker script
Func ResetData()
	$Data = "::perm " & $IFS & "=" & $hWnd & ";"
EndFunc   ;==>ResetData

;escape a string for $sep separator
Func SepEscape($str)
	Local $s = StringSplit($sep, '', 2)
	Local $u[UBound($s)] ;create unique char array with max length
	Local $k = 0 ; $u resizer
	For $i = 0 To UBound($s) - 1
		For $j = $i + 1 To UBound($s) - 1
			If $s[$j] == $s[$i] Then
				$s[$j] = ""
			EndIf
		Next
		;fill $u with only unique chars
		If ($s[$i] <> '') Then
			$u[$k] = $s[$i]
			$k += 1 ; keep count of unique chars
			$s[$i] = '' ;memorysave ?s
		EndIf
	Next
	ReDim $u[$k] ;remove extra $u length

	For $i = 0 To UBound($u) - 1
		$str = StringReplace($str, $u[$i], '[' & $u[$i] & ']', 0, 1)
	Next
	Return $str
EndFunc   ;==>SepEscape

Func opReplace() ; $string, $pattern, $replace
	$string = MsgWaiter($dwScript)
	$pattern = MsgWaiter($dwScript)
	$replace = MsgWaiter($dwScript)
	;all necessary params received
	;send last $IFS reset, next transfer will be the result
	ResetData()
	OUT_XYMSG($dwScript)
	;sets $Data = final result
	$Data = pcreReplace()
	$Data = $op & $Data ; prefix $op to identify result data
	;MsgBox(0, "sending", $Data)
	OUT_XYMSG($dwString) ;send result as string
	;ResetData() ;maybe one last transfer of errors etc
	;OUT_XYMSG($dwScript)
	Return
EndFunc   ;==>opReplace

Func pcreReplace()
	Local $result = StringRegExpReplace($string, $pattern, $replace)
	Local $resultErr = @error
	Local $resultExt = @extended
	Switch $resultErr
		; Case 0 ; success
		Case 2 ; pattern error
			MsgBox(0 + 16, $replaceErrStr, "pattern error at char " & $resultExt)
	EndSwitch

	Return $result
EndFunc   ;==>pcreReplace

Func opMatch()
	$string = MsgWaiter($dwScript)
	$pattern = MsgWaiter($dwScript)
	$sep = MsgWaiter($dwScript)
	$index = MsgWaiter($dwScript)
	$format = MsgWaiter($dwScript)
	;all necessary params received
	;send last $IFS reset, next transfer will be the result
	ResetData()
	OUT_XYMSG($dwScript)
	;sets $Data = final result
	$Data = pcreMatch()
	$Data = $op & $Data ; prefix $op to identify result data
	OUT_XYMSG($dwString) ;send result as string
	;ResetData() ;maybe one last transfer of errors etc
	;OUT_XYMSG($dwScript)
	Return
EndFunc   ;==>opMatch

Func pcreMatch() ; $string, $pattern, $sep, $index, $format
	Local $matchArr = StringRegExp($string, $pattern, 4)
	Local $matchErr = @error
	Local $matchExt = @extended
	Local $result

	;MsgBox(0, "", ($matchArr[0])[0])
	;returns 2D array: [[globalmatch][group1][group2]][[globalmatch]...]...
	;we want to get the global matches only, so ($matchArr[$i])[0]
	Switch $matchErr
		Case 0 ; valid array, matches found
			;if index is defined, return only one match
			If ($index > 0) Then
				If ($index <= UBound($matchArr)) Then
					$result = ($matchArr[$index - 1])[0]
				Else ; index > matchcount, return last match
					$result = ($matchArr[UBound($matchArr) - 1])[0]
				EndIf
				If ($format == 1) Then
					$result = SepEscape($result)
				ElseIf ($format == 2) Then
					$result = StringLen($result) & '|' & $result
				EndIf
				;else make formatted matchlist
			Else
				If ($format == 2) Then
					Local $strlens, $strs
					For $i = 0 To UBound($matchArr) - 1
						$strlens = $strlens & '+' & StringLen(($matchArr[$i])[0])
						$strs = $strs & ($matchArr[$i])[0]
						$matchArr[$i] = ''
					Next
					$result = StringTrimLeft($strlens, 1) & '|' & $strs
				ElseIf ($format == 1) Then
					For $i = 0 To UBound($matchArr) - 1
						$result = $result & SepEscape(($matchArr[$i])[0]) & $sep
						$matchArr[$i] = '' ; memorysave ?
					Next
					$result = StringTrimRight($result, StringLen($sep)) ; trim last extra $sep
				Else
					For $i = 0 To UBound($matchArr) - 1
						$result = $result & ($matchArr[$i])[0] & $sep
						$matchArr[$i] = ''
					Next
					$result = StringTrimRight($result, StringLen($sep)) ; trim last extra $sep
				EndIf
			EndIf
			; Case 1 ; no match
			; 	If ($format == 2) Then
			; 		$result = "0|"
			; 	EndIf
		Case 2 ; pattern error
			MsgBox(0 + 16, $matchErrStr, "pattern error at char " & $matchExt)
	EndSwitch

	Return $result
EndFunc   ;==>pcreMatch

Func opCapture()
	$string = MsgWaiter($dwScript)
	$pattern = MsgWaiter($dwScript)
	$index = MsgWaiter($dwScript)
	$sep = MsgWaiter($dwScript)
	$format = MsgWaiter($dwScript)
	;all necessary params received
	;send last $IFS reset, next transfer will be the result
	ResetData()
	OUT_XYMSG($dwScript)
	;sets $Data = final result
	$Data = pcreCapture()
	$Data = $op & $Data ; prefix $op to identify result data
	;MsgBox(0, "sending", $Data)
	OUT_XYMSG($dwString) ;send result as string
	;ResetData() ;maybe one last transfer of errors etc
	;OUT_XYMSG($dwScript)
	Return
EndFunc   ;==>opCapture

Func pcreCapture() ; $string, $pattern, $index, $sep, $format
	Local $matchArr = StringRegExp($string, $pattern, 4)
	Local $matchErr = @error
	Local $matchExt = @extended
	Local $result

	;returns 2D array: [[globalmatch][group1][group2]][[globalmatch]...]...
	;we want to return the global matches only, so ($matchArr[$i])[0]
	Switch $matchErr
		Case 0 ; valid array, matches found
			;validate index
			If ($index < 1) Then
				$index = 1
			ElseIf ($index >= UBound($matchArr[0])) Then ; each array has *global* + groups
				$index = UBound($matchArr[0]) - 1 ; lastgroup index
			EndIf
			;build $indexth capture groups from each match
			If ($format == 2) Then
				Local $strlens, $strs
				For $i = 0 To UBound($matchArr) - 1
					$strlens = $strlens & '+' & StringLen(($matchArr[$i])[$index])
					$strs = $strs & ($matchArr[$i])[$index]
					$matchArr[$i] = ''
				Next
				$result = StringTrimLeft($strlens, 1) & '|' & $strs
			ElseIf ($format == 1) Then
				For $i = 0 To UBound($matchArr) - 1
					$result = $result & SepEscape(($matchArr[$i])[$index]) & $sep
					$matchArr[$i] = ''
				Next
				$result = StringTrimRight($result, StringLen($sep)) ; trim last extra $sep
			Else
				For $i = 0 To UBound($matchArr) - 1
					$result = $result & ($matchArr[$i])[$index] & $sep
					$matchArr[$i] = ''
				Next
				$result = StringTrimRight($result, StringLen($sep)) ; trim last extra $sep
			EndIf
			; Case 1 ; no match
			; 	If ($format == 2) Then
			; 		$result = "0|"
			; 	EndIf
		Case 2 ; pattern error
			MsgBox(0 + 16, $captureErrStr, "pattern error at char " & $matchExt)
	EndSwitch

	Return $result
EndFunc   ;==>pcreCapture

Func opSplit()
	$string = MsgWaiter($dwScript)
	$pattern = MsgWaiter($dwScript)
	$sep = MsgWaiter($dwScript)
	$format = MsgWaiter($dwScript)
	;all necessary params received
	;send last $IFS reset, next transfer will be the result
	ResetData()
	OUT_XYMSG($dwScript)
	;sets $Data = final result
	$Data = pcreSplit()
	$Data = $op & $Data ; prefix $op to identify result data
	;MsgBox(0, "sending", $Data)
	OUT_XYMSG($dwString) ;send result as string
	;ResetData() ;maybe one last transfer of errors etc
	;OUT_XYMSG($dwScript)
	Return
EndFunc   ;==>opSplit

Func pcreSplit() ; $string, $pattern, $sep, $format
	Local $stop, $err, $pos, $result, $sub, $strlens, $strs
	$stop = 0
	$err = 0
	$pos = 1
	While ($stop <> 1)
		Local $match = StringRegExp($string, $pattern, 2)
		$err = @error
		$pos = @extended
		If ($err == 2) Then
			MsgBox(0 + 16, $splitErrStr, "pattern error at char " & $pos)
			Return ''
		ElseIf ($err == 1) Then ;match not found
			$stop = 1
			$sub = $string
			$string = ''
		Else
			$sub = StringLeft($string, $pos - StringLen($match[0]) - 1) ;get pre-matching part
			$string = StringTrimLeft($string, $pos - 1) ;remove sub from string
		EndIf
		If ($format == 2) Then
			$strlens = $strlens & '+' & StringLen($sub)
			$strs = $strs & $sub
		ElseIf ($format == 1) Then
			$result = $result & SepEscape($sub) & $sep
		Else
			$result = $result & $sub & $sep
		EndIf
	WEnd
	If ($format == 2) Then
		$result = StringTrimLeft($strlens, 1) & '|' & $strs
	Else
		$result = StringTrimRight($result, StringLen($sep))
	EndIf
	Return $result
EndFunc   ;==>pcreSplit

;WM_COPYDATA funcs

; incoming WM_COPYDATA handler
; sets Global $Data to incoming data, and inrcrements Global $Step
Func IN_XYMSG($_hWnd, $_Msg, $_wParam, $lParam)
	Local $copyDataStruct = DllStructCreate('dword dwData;dword cbData;ptr lpData', $lParam)
	Local $lpData = DllStructGetData($copyDataStruct, 'lpData')
	Local $dataSize = DllStructGetData($copyDataStruct, 'cbData') / 2
	Local $dataStruct = DllStructCreate('wchar data[' & $dataSize & ']', $lpData)
	$Data = DllStructGetData($dataStruct, 'data') ; Data.
	If ($dataSize = 0) Then $Data = ''
	$pstep += 1 ;enable wait for next data reception
	Return True
EndFunc   ;==>IN_XYMSG

; send data to XY via WM_COPYDATA (original author: Marco)
Func OUT_XYMSG(ByRef Const $dwData)
	Local $dataSize = StringLen($Data)
	Local $dataStruct = DllStructCreate('wchar data[' & $dataSize & ']')
	Local $copyDataStruct = DllStructCreate('dword dwData;dword cbData;ptr lpData')
	DllStructSetData($dataStruct, 'data', $Data)
	DllStructSetData($copyDataStruct, 'dwData', $dwData)
	DllStructSetData($copyDataStruct, 'cbData', $dataSize * 2)   ; $dataSize is 2bytes per wchar
	DllStructSetData($copyDataStruct, 'lpData', DllStructGetPtr($dataStruct))
	_SendMessage($XYhWnd, $WM_COPYDATA, $hWnd, DllStructGetPtr($copyDataStruct))
	Return True
EndFunc   ;==>OUT_XYMSG

