;-TOP

; Modbus Server Data Source Example

; Der Modbus Server und Data Source Thread laufen asynchron.
; Damit die Daten konsistent sind, müssen diese gegenseitig mit Mutex beim aktualisieren geschützt sein.
;
; Die Daten werden im Modbus Format in die Input und Holding Registers eingetragen
; - 16 Bit Word in High/Low Byte Notation (bswap16)
; - 32 Bit Long/Float Werte High/Low Word Notation (bswap32). 
;   * Hier in Modbus-Client "Tausche Words in 32 Bit Werte" einstellen. Ist heutiger Standard bei den meisten Geräten.
; - 64 Bit Quat/Double Werte das gleiche (bswap64)
; 
; 32 Bit Werte benötigen immer 2 Register und 64 Bit Werte benötigen immer 4 Register
;
; Um einfacher die eigenen Werte zu den Registern zu verweisen, eine überlagerte Struktur anlegen
; und diese auf die gleiche Adresse von den Modbus Registern zuweisen.

Structure udtHoldingDataSource ; Values 3x40001
  Count.w         ; Register offet 0 
  fill.w          ; Register offet 1 
  ShortValue1.w   ; Register offet 2 
  ShortValue2.w   ; Register offet 3 
  longValue1.l    ; Register offet 4 # 2 Words
  longValue2.l    ; Register offet 6 # 2 Words
  FloatValue1.l   ; Register offet 8 # Float as Swapped Long Data, 2 Words
  FloatValue2.l   ; Register offet 10 
  DoubleValue1.q  ; Register offet 12 # Double as Swapped Quad Data, 4 Words
  DoubleValue2.q  ; Register offet 16
EndStructure

Structure udtInputDataSource ; Analog Inputs 4x30001
  Analog_1.w
  Analog_2.w
  Analog_3.w
  Analog_4.w
  Analog_5.w
  Analog_6.w
  Analog_7.w
  Analog_8.w
EndStructure

; ----

Structure udtDataThread
  ThreadID.i
  Exit.i
EndStructure

; ----

Global DataThread.udtDataThread

; Modbus Daten für UnitID 1 anlgen
UnitID\Data[1] = AllocateStructure(udtModbusData)
; Mutex für Konsistens anlegen
UnitID\Data[1]\Mutex = CreateMutex()

; ----

Procedure thDataSource(*Data.udtDataThread)
  Protected *DiscreateInputs.udtDataDiscreteInputs, *Coils.udtDataCoils
  Protected *HoldingData.udtHoldingDataSource, *InputData.udtInputDataSource
  Protected Mutex
  Protected fltVal.f, dblVal.d
  Protected Count, fltCount.f, index
  
  With *Data
    Logging("Start Data Server Thread")
    
    ; Setze Coils Struktur auf Modbus auf Offset 0 (1x00001)
    *Coils = UnitID\Data[1]\Coils
    
    ; Setze DiscreteInputs Struktur auf Modbus auf Offset 0 (2x10001)
    *DiscreateInputs = UnitID\Data[1]\DiscreteInputs
    
    ; Setze Input Daten Struktur auf Modbus Input Register auf Offset 0 (4x30001)
    *InputData = UnitID\Data[1]\InputRegister
    
    ; Setze Holding Daten Struktur auf Modbus Holding Register auf Offset 0 (3x40001)
    *HoldingData = UnitID\Data[1]\HoldingRegister
    
    ; Mutex für Konsistens übernehmen
    Mutex = UnitID\Data[1]\Mutex
    
    ; Setze UnitID Online
    UnitID\Data[1]\Quality = #True
    
    Repeat
      If \Exit
        Break
      EndIf
      
      ; DiscreteInputs vorbereiten
      
      ; DiscreteInpust zuweisen
      LockMutex(Mutex)
      For index = 0 To 99
        *DiscreateInputs\Byte[index] = Random(255)
      Next
      UnlockMutex(Mutex)
      
      ; Analog Input Daten vorbereiten
      
      ; Daten in Holding Registers ablegen in High/Low Byte Notation
      LockMutex(Mutex)
      *InputData\Analog_1 = bswap16(1)
      *InputData\Analog_2 = bswap16(2)
      *InputData\Analog_3 = bswap16(3)
      *InputData\Analog_4 = bswap16(4)
      *InputData\Analog_5 = bswap16(5)
      *InputData\Analog_6 = bswap16(6)
      *InputData\Analog_7 = bswap16(7)
      *InputData\Analog_8 = bswap16(8)
      UnlockMutex(Mutex)
      
      ; Holding Daten vorbereiten
      count + 1
      fltCount + 0.01
      
      ; Daten in Holding Registers ablegen in High/Low Byte Notation
      LockMutex(Mutex)
      *HoldingData\Count = bswap16(Count)
      *HoldingData\ShortValue1 = bswap16(1)
      *HoldingData\ShortValue2 = bswap16(Random(1000))
      ; Daten in Holding Registers ablegen in High/Low Word Notation (Heutiger Standard, Tausche Words in 32 Bit Werten)
      *HoldingData\longValue1 = bswap32(1)
      *HoldingData\longValue2 = bswap32(Random(10000, 1000))
      ; Auf Float oder Double über die Rohdaten als Long oder Quad die Konvertierung durchführen
      *HoldingData\FloatValue1 = bswap32_float(fltCount)
      fltVal = 999.99
      *HoldingData\FloatValue2 = bswap32_float(fltVal)
      dblVal = 2026.02
      *HoldingData\DoubleValue1 = bswap64_double(dblVal)
      dblVal = -1.0
      *HoldingData\DoubleValue2 = bswap64_double(dblVal)
      UnlockMutex(Mutex)
      
      ; Kleine Pause
      Delay(1000)
    ForEver
    
    Logging("Exit Data Server Thread")
    Delay(50)
    \ThreadID = 0
    \Exit = 0
  EndWith
EndProcedure


  