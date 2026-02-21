# modbus-server-tcpip for purebasic

English:

Modbus Server and Data Source Basis
-----------------------------------

The modbus server and data source thread run asynchronously.
To ensure data consistency, they must be mutually protected with mutexes during updates.

The data is entered into the input and holding registers in Modbus format
- 16-bit word in high/low byte notation (bswap16)
- 32-bit long/float values in high/low word notation (bswap32). 
  * Set "Swap words in 32-bit values" in the modbus client. This is the current standard for most devices.
- 64-bit Quat/Double values the same (bswap64)
 
32-bit values always require 2 registers and 64-bit values always require 4 registers.

To make it easier to refer your own values to the registers, create a superimposed structure
and assign it to the same address as the Modbus registers.

-----------------------------------

German:

Modbus Server und Data Source Basis
-----------------------------------

Der Modbus Server und Data Source Thread laufen asynchron.
Damit die Daten konsistent sind, müssen diese gegenseitig mit Mutex beim aktualisieren geschützt sein.

Die Daten werden im Modbus Format in die Input und Holding Registers eingetragen
- 16 Bit Word in High/Low Byte Notation (bswap16)
- 32 Bit Long/Float Werte High/Low Word Notation (bswap32). 
  * Hier in Modbus-Client "Tausche Words in 32 Bit Werte" einstellen. Ist heutiger Standard bei den meisten Geräten.
- 64 Bit Quat/Double Werte das gleiche (bswap64)
 
32 Bit Werte benötigen immer 2 Register und 64 Bit Werte benötigen immer 4 Register

Um einfacher die eigenen Werte zu den Registern zu verweisen, eine überlagerte Struktur anlegen
und diese auf die gleiche Adresse von den Modbus Registern zuweisen.



