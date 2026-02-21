;-TOP

; Global Functions

;- -- MacOS NapStop --

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  ; Author : Danilo
  ; Date   : 25.03.2014
  ; Link   : https://www.purebasic.fr/english/viewtopic.php?f=19&t=58828
  ; Info   : NSActivityOptions is a 64bit typedef - use it with quads (.q) !!!
  
  #NSActivityIdleDisplaySleepDisabled             = 1 << 40
  #NSActivityIdleSystemSleepDisabled              = 1 << 20
  #NSActivitySuddenTerminationDisabled            = (1 << 14)
  #NSActivityAutomaticTerminationDisabled         = (1 << 15)
  #NSActivityUserInitiated                        = ($00FFFFFF | #NSActivityIdleSystemSleepDisabled)
  #NSActivityUserInitiatedAllowingIdleSystemSleep = (#NSActivityUserInitiated & ~#NSActivityIdleSystemSleepDisabled)
  #NSActivityBackground                           = $000000FF
  #NSActivityLatencyCritical                      = $FF00000000
  
  Procedure BeginWork(Option.q, Reason.s= "MyReason")
    Protected NSProcessInfo = CocoaMessage(0,0,"NSProcessInfo processInfo")
    If NSProcessInfo
      ProcedureReturn CocoaMessage(0, NSProcessInfo, "beginActivityWithOptions:@", @Option, "reason:$", @Reason)
    EndIf
  EndProcedure
  
  Procedure EndWork(Activity)
    Protected NSProcessInfo = CocoaMessage(0, 0, "NSProcessInfo processInfo")
    If NSProcessInfo
      CocoaMessage(0, NSProcessInfo, "endActivity:", Activity)
    EndIf
  EndProcedure
CompilerEndIf

;--- String Helper --
  
Procedure AllocateString(String.s) ; Result = Pointer
  Protected *mem.string = AllocateStructure(String)
  If *mem
    *mem\s = String
  EndIf
  ProcedureReturn *mem
EndProcedure

Procedure.s FreeString(*mem.string) ; Result String
  Protected r1.s
  If *mem
    r1 = *mem\s
    FreeStructure(*mem)
  EndIf
  ProcedureReturn r1
EndProcedure

;--- Logging --

; Level 0: Standard
; Level 1: Modbus Fehler
; Level 2: Modbus Data

Global LoggingLevel = 0

Macro Logging(String, Level=0)
  If Level <= LoggingLevel : PostEvent(#MyEvent_ThreadSendString, 0, 0, 0, AllocateString(String)) : EndIf
EndMacro

;-----

Enumeration #PB_Event_FirstCustomValue
  #MyEvent_ThreadSendString
  #MyEvent_ThreadSendStatus
EndEnumeration

; ----
  
Procedure bswap16(value.u)
  CompilerIf #PB_Compiler_Backend = #PB_Backend_C
    !return __builtin_bswap16(v_value);
  CompilerElse
    !xor eax,eax
    !mov ax, word [p.v_value]
    !rol ax, 8
    ProcedureReturn
  CompilerEndIf
EndProcedure

Procedure bswap32(value.l)
  CompilerIf #PB_Compiler_Backend = #PB_Backend_C
    !return __builtin_bswap32(v_value);
  CompilerElse
    !mov eax, dword [p.v_value]
    !bswap eax
    ProcedureReturn
  CompilerEndIf
EndProcedure

Procedure.q bswap64(value.q)
  CompilerIf #PB_Compiler_Backend = #PB_Backend_C
    !return __builtin_bswap64(v_value);
  CompilerElse
    CompilerIf #PB_Compiler_Processor=#PB_Processor_x64
      !mov rax, qword [p.v_value]
      !bswap rax
    CompilerElse
      !mov edx, dword [p.v_value]
      !mov eax, dword [p.v_value + 4]
      !bswap edx
      !bswap eax
    CompilerEndIf
    ProcedureReturn
  CompilerEndIf
EndProcedure

; ----

; Special swap functions for Modbus

Procedure bswap32_float(value.f) ; Return a float as swap long 
  Protected long.l
  
  long = PeekL(@value)
  CompilerIf #PB_Compiler_Backend = #PB_Backend_C
    !return __builtin_bswap32(v_long);
  CompilerElse
    !mov eax, dword [p.v_long]
    !bswap eax
    ProcedureReturn
  CompilerEndIf
EndProcedure

Procedure.q bswap64_double(value.d) ; Return a double as swap quad
  Protected quad.q
  
  quad = PeekQ(@value)
  CompilerIf #PB_Compiler_Backend = #PB_Backend_C
    !return __builtin_bswap64(v_quad);
  CompilerElse
    CompilerIf #PB_Compiler_Processor=#PB_Processor_x64
      !mov rax, qword [p.v_quad]
      !bswap rax
    CompilerElse
      !mov edx, dword [p.v_quad]
      !mov eax, dword [p.v_quad + 4]
      !bswap edx
      !bswap eax
    CompilerEndIf
    ProcedureReturn
  CompilerEndIf
EndProcedure

; ----

CompilerIf #PB_Compiler_IsMainFile
  
  f.f = 100
  l = bswap32_float(f)
  
CompilerEndIf
