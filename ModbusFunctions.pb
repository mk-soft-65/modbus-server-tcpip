;-TOP

; Comment : Modbus Server Functions 
; Author  : (c) Michael Kastner (mk-soft), mk-soft-65(a)t-online.de
; Version : v1.02.1
; License : LGPL - GNU Lesser General Public License
; Create  : 13.02.2026
; Update  : 20.02.2026

Structure ArrayOfByte
  a.a[0]
EndStructure

Procedure GetBit(*Buffer.ArrayOfByte, Bit)
  Protected offset, mask
  
  offset = Bit / 8
  mask = 1 << (Bit % 8)
  ProcedureReturn Bool(*Buffer\a[offset] & mask)
EndProcedure

Procedure SetBit(*Buffer.ArrayOfByte, Bit, State)
  Protected offset, mask
  
  offset = Bit / 8
  mask = 1 << (Bit % 8)
  If State
    *Buffer\a[offset] | mask
  Else
    *Buffer\a[offset] & (~mask)
  EndIf
EndProcedure

; ----

Procedure.s ModbusErrorText(ErrorCode)
  Protected text.s
  
  text = " Error " + Str(ErrorCode)
  Select ErrorCode
    Case 1: text + " (Illegal Function)"
    Case 2: text + " (Illegal Data Address)"
    Case 3: text + " (Illegal Data Value)"
    Case 4: text + " (Slave Device Failure)"
    Case 5: text + " (Acknowledge)"
    Case 6: text + " (Slave Device Busy)"
    Case 7: text + " (Negative Acknowledge)"
    Case 8: text + " (Memory Parity Error)"
    Case 10: text + " (Gateway Path Unavailable)"
    Case 11: text + " (Gateway Target Device Failed to Respond)"
    Default: text + " (Unknown)"
  EndSelect
  ProcedureReturn text
EndProcedure

; ----

Procedure ModbusError(ErrorCode, *Data.udtClientData)
  
  With *Data
    Logging("Error Client IP " + \IP + ": FC " + Str(\Receive\Functioncode) + ModbusErrorText(ErrorCode), 1)
    \Send\TransactionID = bswap16(\Receive\TransactionID)
    \Send\ProtocolID = 0
    \Send\DataLen = bswap16(3)
    \Send\UnitID = \Receive\UnitID
    \Send\Functioncode = \Receive\Functioncode | $80
    \Send\ErrorCode = ErrorCode
    ProcedureReturn 9
  EndWith
  
EndProcedure

; ----

Procedure ModbusFunction(*ClientData.udtClientData, *Data.udtModbusData)
  Protected Register, cBytes, Offset, lBound, uBound, SendLen
  
  With *ClientData
    
    If *Data = 0
      ProcedureReturn ModbusError(10, *ClientData)
    EndIf
    
    If *Data\Quality = 0
      ProcedureReturn ModbusError(11, *ClientData)
    EndIf
    
    Select \Receive\Functioncode
      Case 1 ;-- Read Coils
        If \Receive\Count > 2000
          ProcedureReturn ModbusError(2, *ClientData)
        ElseIf \Receive\Register + \Receive\Count > #CountCoils
          ProcedureReturn ModbusError(2, *ClientData)
        Else
          cBytes = \Receive\Count / 8
          If \Receive\Count % 8
            cBytes + 1
          EndIf
          lBound = \Receive\Register
          uBound = \Receive\Register + \Receive\Count - 1
          ; Set Response
          \Send\TransactionID = bswap16(\Receive\TransactionID)
          \Send\ProtocolID = 0
          \Send\DataLen = bswap16(3 + cBytes)
          \Send\UnitID = \Receive\UnitID
          \Send\Functioncode = \Receive\Functioncode
          \Send\ByteCount = cBytes
          ; Copy Send Data
          For Register = 0 To cBytes
            \Send\DataByte[Register] = 0
          Next
          LockMutex(*Data\Mutex)
          For Register = lBound To uBound
            SetBit(@\Send\DataByte, offset, GetBit(@*Data\Coils\Byte, Register))
            Offset + 1
          Next
          UnlockMutex(*Data\Mutex)
          SendLen = 6 + 3 + cBytes
          Logging("Request Client IP " + \IP + " - UnitID " + Str(\Receive\UnitID) + " - Read Coils Offset: " + Str(\Receive\Register) + " Count: " + Str(\Receive\Count), 2)
          ProcedureReturn SendLen
        EndIf
        
      Case 2 ;-- Read Discrete Inputs
        If \Receive\Count > 2000
          ProcedureReturn ModbusError(2, *ClientData)
        ElseIf \Receive\Register + \Receive\Count > #CountDiscreteInputs
          ProcedureReturn ModbusError(2, *ClientData)
        Else
          cBytes = \Receive\Count / 8
          If \Receive\Count % 8
            cBytes + 1
          EndIf
          lBound = \Receive\Register
          uBound = \Receive\Register + \Receive\Count - 1
          ; Set Response
          \Send\TransactionID = bswap16(\Receive\TransactionID)
          \Send\ProtocolID = 0
          \Send\DataLen = bswap16(3 + cBytes)
          \Send\UnitID = \Receive\UnitID
          \Send\Functioncode = \Receive\Functioncode
          \Send\ByteCount = cBytes
          ; Copy Send Data
          For Register = 0 To cBytes
            \Send\DataByte[Register] = 0
          Next
          LockMutex(*Data\Mutex)
          For Register = lBound To uBound
            SetBit(@\Send\DataByte, offset, GetBit(@*Data\DiscreteInputs\Byte, Register))
            Offset + 1
          Next
          UnlockMutex(*Data\Mutex)
          SendLen = 6 + 3 + cBytes
          Logging("Request Client IP " + \IP + " - UnitID " + Str(\Receive\UnitID) + " - Read Discrete Inputs Offset: " + Str(\Receive\Register) + " Count: " + Str(\Receive\Count), 2) 
          ProcedureReturn SendLen
        EndIf
        
      Case 3 ;-- Read Holding Register
        If \Receive\Count > 125
          ProcedureReturn ModbusError(2, *ClientData)
        ElseIf \Receive\Register + \Receive\Count > #CountHoldingRegisters
          ProcedureReturn ModbusError(2, *ClientData)
        Else
          cBytes = \Receive\Count * 2
          lBound = \Receive\Register
          uBound = \Receive\Register + \Receive\Count - 1
          ; Set Resonse
          \Send\TransactionID = bswap16(\Receive\TransactionID)
          \Send\ProtocolID = 0
          \Send\DataLen = bswap16(3 + cBytes)
          \Send\UnitID = \Receive\UnitID
          \Send\Functioncode = \Receive\Functioncode
          \Send\ByteCount = cBytes
          ; Copy Send Data
          LockMutex(*Data\Mutex)
          For Register = lBound To uBound
            \Send\DataWord[Offset] = *Data\HoldingRegister\Word[Register]
            Offset + 1
          Next
          UnlockMutex(*Data\Mutex)
          SendLen = 6 + 3 + cBytes
          Logging("Request Client IP " + \IP + " - UnitID " + Str(\Receive\UnitID) + " - Read Holding Offset: " + Str(\Receive\Register) + " Count: " + Str(\Receive\Count), 2)
          ProcedureReturn SendLen
        EndIf
        
      Case 4 ;-- Read Input Register
        If \Receive\Count > 125
          ProcedureReturn ModbusError(2, *ClientData)
        ElseIf \Receive\Register + \Receive\Count > #CountInputRegisters
          ProcedureReturn ModbusError(2, *ClientData)
        Else
          cBytes = \Receive\Count * 2
          lBound = \Receive\Register
          uBound = \Receive\Register + \Receive\Count - 1
          ; Set Response
          \Send\TransactionID = bswap16(\Receive\TransactionID)
          \Send\ProtocolID = 0
          \Send\DataLen = bswap16(3 + cBytes)
          \Send\UnitID = \Receive\UnitID
          \Send\Functioncode = \Receive\Functioncode
          \Send\ByteCount = cBytes
          ; Copy Send Data
          LockMutex(*Data\Mutex)
          For Register = lBound To uBound
            \Send\DataWord[Offset] = *Data\InputRegister\Word[Register]
            Offset + 1
          Next
          UnlockMutex(*Data\Mutex)
          SendLen = 6 + 3 + cBytes
          Logging("Request Client IP " + \IP + " - UnitID " + Str(\Receive\UnitID) + " - Read Inputs Offset: " + Str(\Receive\Register) + " Count: " + Str(\Receive\Count), 2)
          ProcedureReturn SendLen
        EndIf
        
      Case 5 ;-- Force Single Coil 
        If \Receive\Register >= #CountCoils
          ProcedureReturn ModbusError(2, *ClientData)
        Else
          LockMutex(*Data\Mutex)
          If \Receive\Status = $FF00
            SetBit(@*Data\Coils\Byte, \Receive\Register, #True)
          Else
            SetBit(@*Data\Coils\Byte, \Receive\Register, #False)
          EndIf
          UnlockMutex(*Data\Mutex)
          ; Set Response
          \SendEx\TransactionID = bswap16(\Receive\TransactionID)
          \SendEx\ProtocolID = 0
          \SendEx\DataLen = bswap16(6)
          \SendEx\UnitID = \Receive\UnitID
          \SendEx\Functioncode = \Receive\Functioncode
          \SendEx\Register = bswap16(\Receive\Register)
          \SendEx\Status = bswap16(\Receive\Status)
          SendLen = 6 + 6
          Logging("Request Client IP " + \IP + " - UnitID " + Str(\Receive\UnitID) + " - Write Single Coil Offset: " + Str(\Receive\Register) + " State: " + Hex(\Receive\Count), 2)
          ProcedureReturn SendLen
        EndIf
        
      Case 6 ;-- Write Single Holding Register 
        If \Receive\Register >= #CountHoldingRegisters
          ProcedureReturn ModbusError(2, *ClientData)
        Else
          LockMutex(*Data\Mutex)
          *Data\HoldingRegister\Word[\Receive\Register] = \Receive\Value
          UnlockMutex(*Data\Mutex)
          ; Set Response
          \SendEx\TransactionID = bswap16(\Receive\TransactionID)
          \SendEx\ProtocolID = 0
          \SendEx\DataLen = bswap16(6)
          \SendEx\UnitID = \Receive\UnitID
          \SendEx\Functioncode = \Receive\Functioncode
          \SendEx\Register = bswap16(\Receive\Register)
          \SendEx\Value = *Data\HoldingRegister\Word[\Receive\Register]
          SendLen = 6 + 6
          Logging("Request Client IP " + \IP + " - UnitID " + Str(\Receive\UnitID) + " - Write Single Holding Offset: " + Str(\Receive\Register) + " Value: " + Hex(\Receive\Count), 2)
          ProcedureReturn SendLen
        EndIf
        
      Case 15 ;-- Force Multiple Coils
        If \Receive\Count > 800
          ProcedureReturn ModbusError(2, *ClientData)
        ElseIf \Receive\Register + \Receive\Count > #CountCoils
          ProcedureReturn ModbusError(2, *ClientData)
        Else
          lBound = \Receive\Register
          uBound = \Receive\Register + \Receive\Count - 1
          LockMutex(*Data\Mutex)
          For Register = lBound To uBound
            SetBit(@*Data\Coils\Byte, Register, GetBit(@\Receive\DataByte, Offset))
            Offset + 1
          Next
          UnlockMutex(*Data\Mutex)
          ; Set Response
          \SendEx\TransactionID = bswap16(\Receive\TransactionID)
          \SendEx\ProtocolID = 0
          \SendEx\DataLen = bswap16(6)
          \SendEx\UnitID = \Receive\UnitID
          \SendEx\Functioncode = \Receive\Functioncode
          \SendEx\Register = bswap16(\Receive\Register)
          \SendEx\Count = bswap16(\Receive\Count)
          SendLen = 6 + 6
          Logging("Request Client IP " + \IP + " - UnitID " + Str(\Receive\UnitID) + " - Write Multiple Coils Offset: " + Str(\Receive\Register) + " State: " + Hex(\Receive\Count), 2)
          ProcedureReturn SendLen
        EndIf
        
      Case 16 ;-- Write Multiple Holding Registers
        If \Receive\Count > 123
          ProcedureReturn ModbusError(2, *ClientData)
        ElseIf \Receive\Register + \Receive\Count > #CountHoldingRegisters
          ProcedureReturn ModbusError(2, *ClientData)
        Else
          lBound = \Receive\Register
          uBound = lBound + \Receive\Count - 1
          LockMutex(*Data\Mutex)
          For Register = lBound To uBound
            *Data\HoldingRegister\Word[Register] = \Receive\DataWord[Offset]
            Offset + 1
          Next
          UnlockMutex(*Data\Mutex)
          ; Set Response
          \SendEx\TransactionID = bswap16(\Receive\TransactionID)
          \SendEx\ProtocolID = 0
          \SendEx\DataLen = bswap16(6)
          \SendEx\UnitID = \Receive\UnitID
          \SendEx\Functioncode = \Receive\Functioncode
          \SendEx\Register = bswap16(\Receive\Register)
          \SendEx\Count = bswap16(\Receive\Count)
          SendLen = 6 + 6
          Logging("Request Client IP " + \IP + " - UnitID " + Str(\Receive\UnitID) + " - Write Multiple Holding Offset: " + Str(\Receive\Register) + " Count: " + Hex(\Receive\Count), 2)
          ProcedureReturn SendLen
        EndIf
        
      Case 23 ;-- Read and Write Multiple Holding Registers
        If \Receive23\CountWrite > 121
          ProcedureReturn ModbusError(2, *ClientData)
        ElseIf \Receive23\RegisterWrite + \Receive23\CountWrite > #CountHoldingRegisters
          ProcedureReturn ModbusError(2, *ClientData)
        ElseIf \Receive23\CountRead > 125
          ProcedureReturn ModbusError(2, *ClientData)
        ElseIf \Receive23\RegisterRead + \Receive23\CountRead > #CountHoldingRegisters
          ProcedureReturn ModbusError(2, *ClientData)
        Else
          LockMutex(*Data\Mutex)
          ; Write Holding Registers
          lBound = \Receive23\RegisterWrite
          uBound = lBound + \Receive23\CountWrite - 1
          Offset = 0
          For Register = lBound To uBound
            *Data\HoldingRegister\Word[Register] = \Receive23\DataWord[Offset]
            Offset + 1
          Next
          ; Read Holding Registers
          cBytes = \Receive23\CountRead * 2
          lBound = \Receive23\RegisterRead
          uBound = \Receive23\RegisterRead + \Receive23\CountRead - 1
          Offset = 0
          For Register = lBound To uBound
            \Send\DataWord[Offset] = *Data\HoldingRegister\Word[Register]
            Offset + 1
          Next
          UnlockMutex(*Data\Mutex)
          ; Set Response
          \Send\TransactionID = bswap16(\Receive23\TransactionID)
          \Send\ProtocolID = 0
          \Send\DataLen = bswap16(3 + cBytes)
          \Send\UnitID = \Receive23\UnitID
          \Send\Functioncode = \Receive23\Functioncode
          \Send\ByteCount = cBytes
          SendLen = 6 + 3 + cBytes
          Logging("Request Client IP " + \IP + " - UnitID " + Str(\Receive23\UnitID) + " - Read and Write Holding Offset: " + Str(\Receive23\RegisterRead) + " Count: " + Str(\Receive23\CountRead), 2)
          ProcedureReturn SendLen
        EndIf
        
      Default
        ; Not Supported Function
        ProcedureReturn ModbusError(1, *ClientData)
        
    EndSelect
    
  EndWith
  
EndProcedure

; ----

Procedure thModbusServer(*Data.udtServerData)
  Protected ConnectionID, ReceiveLen, SendLen, Len, BlockLen, time
  Protected *buffer, *ReceiveBuffer.udtReceiveData
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    Protected StopNap = BeginWork(#NSActivityLatencyCritical | #NSActivityUserInitiated, "MB" + Hex(*Data))
  CompilerEndIf
    
  With *Data
    Logging("Start Modbus Server Thread")
    ; Create Server
    If \Port = 0
      \Port = 502
    EndIf
    \Time = ElapsedMilliseconds()
    Logging("Init Modbus Server on Port " + Str(\Port))
    Repeat
      If \Exit
        Delay(50)
        \ThreadId = 0
        \Exit = #False
        ProcedureReturn 0
      EndIf
      \ServerID = CreateNetworkServer(#PB_Any, \Port, #PB_Network_IPv4 | #PB_Network_TCP)
      If \ServerID
        Break
      EndIf
      Delay(100)
      If ElapsedMilliseconds() - \Time > 60000 ; ms
        Logging("Error Timeout Init Modbus Server on Port " + Str(\Port))
        Logging("Exit Server Thread")
        Delay(50)
        \ThreadId = 0
        \Exit = #False
        ProcedureReturn 0
      EndIf
    ForEver
    Logging("Running Modbus Server on Port " + Str(\Port))
    PostEvent(#MyEvent_ThreadSendStatus, 0, 0, 0, AllocateString("Server Running"))
    *Buffer = AllocateMemory(65536)
    
    Repeat
      If \Exit
        Break
      EndIf
      
      Select NetworkServerEvent()
        Case #PB_NetworkEvent_Connect
          ConnectionID = EventClient()
          If FindMapElement(Client(), Str(ConnectionID))
            DeleteMapElement(Client())
          EndIf
          If Not AddMapElement(Client(), Str(ConnectionID))
            CloseNetworkConnection(ConnectionID)
          EndIf
          Client()\ConnectionID = ConnectionID
          Client()\IP = IPString(GetClientIP(ConnectionID)) + ":" + Str(GetClientPort(ConnectionID))
          Client()\Time = ElapsedMilliseconds()
          Logging("Client Connected IP " + Client()\IP)
          
        Case #PB_NetworkEvent_Data
          Repeat ; No Loop
            ConnectionID = EventClient()
            If Not FindMapElement(Client(), Str(ConnectionID))
              CloseNetworkConnection(ConnectionID)
              Break
            EndIf
            ReceiveLen = ReceiveNetworkData(ConnectionID, *Buffer, 65536)
            If ReceiveLen = 0
              Break
            ElseIf ReceiveLen < 7
              Logging("Error Connection Client IP " + Client()\IP)
              CloseNetworkConnection(ConnectionID)
              DeleteMapElement(Client())
              Break
            EndIf
            ; Request time
            Client()\Time = ElapsedMilliseconds()
            ; Dispatch all modbus request. Buffer have always a complete modbus protocol
            *ReceiveBuffer = *buffer
            Repeat
              ; Swap Words Header
              *ReceiveBuffer\TransactionID = bswap16(*ReceiveBuffer\TransactionID)
              *ReceiveBuffer\DataLen = bswap16(*ReceiveBuffer\DataLen)
              ; Check Data len
              If (ReceiveLen - 6) < *ReceiveBuffer\DataLen
                Logging("Error DataLen Client IP " + Client()\IP)
                CloseNetworkConnection(ConnectionID)
                DeleteMapElement(Client())
                Break
              EndIf
              ; Check Protocol ID
              If *ReceiveBuffer\ProtocolID <> 0
                Logging("Error ProtocolID Client IP " + Client()\IP)
                CloseNetworkConnection(ConnectionID)
                DeleteMapElement(Client())
                Break
              EndIf
              ; Check Unit ID
              If *ReceiveBuffer\UnitID <= 0
                Logging("Error Invalid UnitID Client IP " + Client()\IP)
                CloseNetworkConnection(ConnectionID)
                DeleteMapElement(Client())
                Break
              EndIf
              ; Swap Words Protocol
              *ReceiveBuffer\Register = bswap16(*ReceiveBuffer\Register)
              *ReceiveBuffer\Count = bswap16(*ReceiveBuffer\Count)
              CopyMemory(*ReceiveBuffer, Client()\Receive, SizeOf(udtReceiveData))
              Len = ModbusFunction(@Client(), UnitID\Data[*ReceiveBuffer\UnitID])
              SendLen = SendNetworkData(Client()\ConnectionID, @Client()\Send, Len)
              If SendLen <> Len
                Logging("Error Send to Client IP " + Client()\IP)
                CloseNetworkConnection(ConnectionID)
                DeleteMapElement(Client())
                Break
              EndIf
              ; Next ADU Block Data
              BlockLen = *ReceiveBuffer\DataLen + 6
              ReceiveLen - BlockLen
              *ReceiveBuffer + BlockLen
              If ReceiveLen > 0
                Logging("Next Request Client IP " + Client()\IP)
              EndIf
            Until ReceiveLen <= 0 Or \Exit
          Until #True
            
        Case #PB_NetworkEvent_Disconnect
          ConnectionID = EventClient()
          If FindMapElement(Client(), Str(ConnectionID))
            Logging("Client Disconnected IP " + Client()\IP)
            DeleteMapElement(Client())
          EndIf
          
        Case #PB_NetworkEvent_None
          ; Remove Clients. Timeout 5 Minutes
          time = ElapsedMilliseconds()
          ForEach Client()
            If (time - Client()\Time) >= 5 * 60000 ; ms
              CloseNetworkConnection(Client()\ConnectionID)
              DeleteMapElement(Client())
            EndIf
          Next
          Delay(10)
          
      EndSelect
      
    ForEver
    
    ForEach Client()
      CloseNetworkConnection(Client()\ConnectionID)
    Next
    CloseNetworkServer(\ServerID)
    
    If *Buffer
      FreeMemory(*Buffer)
    EndIf
    
    Logging("Exit Modbus Server Thread")
    PostEvent(#MyEvent_ThreadSendStatus, 0, 0, 0, AllocateString("Server Stopped"))
    Delay(50)
    \ThreadId = 0
    \Exit = 0
  EndWith
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    EndWork(StopNap)
  CompilerEndIf
  
EndProcedure

; ----
