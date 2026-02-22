;-TOP

; Comment : Modbus Server Declaration  
; Author  : (c) Michael Kastner (mk-soft), mk-soft-65(a)t-online.de
; Version : v1.02.3
; License : LGPL - GNU Lesser General Public License
; Create  : 13.02.2026
; Update  : 21.02.2026

; ----

Structure udtReceiveData
  TransactionID.w
  ProtocolID.w
  DataLen.w
  UnitID.a
  Functioncode.a
  Register.u
  StructureUnion
    Count.u
    Status.u
    Value.w
  EndStructureUnion
  ByteCount.a
  StructureUnion
    DataByte.b[256]
    DataWord.w[128]
  EndStructureUnion
EndStructure

Structure udtReceiveData23
  TransactionID.w
  ProtocolID.w
  DataLen.w
  UnitID.a
  Functioncode.a
  RegisterRead.u
  CountRead.u
  RegisterWrite.u
  CountWrite.u
  ByteCount.a
  StructureUnion
    DataByte.b[252]
    DataWord.w[126]
  EndStructureUnion
EndStructure

; ----

Structure udtSendData
  TransactionID.w
  ProtocolID.w
  DataLen.w
  UnitID.a
  Functioncode.a
  StructureUnion
    ByteCount.a
    ErrorCode.a
  EndStructureUnion
  StructureUnion
    DataByte.b[256]
    DataWord.w[128]
  EndStructureUnion
EndStructure

Structure udtSendDataEx
  TransactionID.w
  ProtocolID.w
  DataLen.w
  UnitID.a
  Functioncode.a
  Register.u
  StructureUnion
    Count.u
    Status.u
    Value.w
  EndStructureUnion
EndStructure

; ----

#CountCoils = 8000
#CountDiscreteInputs = 8000
#CountHoldingRegisters = 5000
#CountInputRegisters = 5000

Structure udtDataCoils
  StructureUnion
    Byte.a[#CountCoils / 8]
  EndStructureUnion
EndStructure

Structure udtDataDiscreteInputs
  StructureUnion
    Byte.a[#CountDiscreteInputs / 8]
  EndStructureUnion
EndStructure

Structure udtDataHoldingRegister
  StructureUnion
    Word.w[#CountHoldingRegisters]
  EndStructureUnion
EndStructure

Structure udtDataInputsRegister
  StructureUnion
    Word.w[#CountInputRegisters]
  EndStructureUnion
EndStructure

; ----

; Modbus Data Buffer with High-Low Byte notation

; Coils               Binäre Ausgänge	Lesen/Schreiben	00001 – 09999
; Discrete Inputs     Binäre Eingänge	Nur Lesen	10001 – 19999
; Holding Registers   Parameter/Werte	Lesen/Schreiben	40001 – 49999
; Input Registers     Analoge Eingänge	Nur Lesen	30001 – 39999

Structure udtModbusData
  Mutex.i
  Quality.l
  Coils.udtDataCoils
  DiscreteInputs.udtDataDiscreteInputs
  HoldingRegister.udtDataHoldingRegister
  InputRegister.udtDataInputsRegister
EndStructure

; ----

; Array Of UnidID with Pointer to Modbus Data

Structure udtUnitID
  *Data.udtModbusData[255]
EndStructure

Global UnitID.udtUnitID

; ----

Structure udtServerData
  ThreadId.i
  Exit.i
  ;
  ServerID.i
  Port.i
  Time.q
  Count.i
EndStructure

Structure udtClientData
  ConnectionID.i
  IP.s
  Time.q
  StructureUnion
    Receive.udtReceiveData
    Receive23.udtReceiveData23
  EndStructureUnion
  StructureUnion
    Send.udtSendData
    SendEx.udtSendDataEx
  EndStructureUnion
EndStructure

Global ServerData.udtServerData
Global NewMap Client.udtClientData()

; ----
