;-TOP

; Comment : Simple Modbus Server
; Author  : (c) Michael Kastner (mk-soft), mk-soft-65(a)t-online.de
; Version : v1.02.2
; Create  : 13.02.2026
; Update  : 21.02.2026

EnableExplicit

CompilerIf Not #PB_Compiler_Thread
  CompilerError "Use Compiler Option ThreadSafe!"
CompilerEndIf

#ProgramTitle = "Simple Modbus TCP/IP Server"
#ProgramVersion = "v1.02.2 by mk-soft"

#AutoStart = #True

IncludeFile "Global.pb"
IncludeFile "ModbusDeclare.pb"
IncludeFile "ModbusFunctions.pb"
IncludeFile "DataSource.pb"

Enumeration Windows
  #Main
EndEnumeration

Enumeration MenuBar
  #MainMenu
EndEnumeration

Enumeration MenuItems
  #MainMenuAbout
  #MainMenuExit
  #MainLevel_0
  #MainLevel_1
  #MainLevel_2
EndEnumeration

Enumeration Gadgets
  #MainList
  #MainButtonStart
  #MainButtonStop
EndEnumeration

Enumeration StatusBar
  #MainStatusBar
EndEnumeration

Procedure DoLogging()
  Protected count, temp.s
  
  count = CountGadgetItems(#MainList)
  temp = FormatDate("[%hh:%ii:%ss] ", Date()) + FreeString(EventData())
  AddGadgetItem(#MainList, -1, temp)
  SetGadgetState(#MainList, count)
  SetGadgetState(#MainList, -1)
  If count > 1000
    RemoveGadgetItem(#MainList, 0)
  EndIf
EndProcedure
  
Procedure UpdateWindow()
  Protected dx, dy
  dx = WindowWidth(#Main)
  dy = WindowHeight(#Main) - StatusBarHeight(#MainStatusBar) - MenuHeight()
  ; Resize gadgets
  ResizeGadget(#MainList, 0, 0, dx, dy-35)
  ResizeGadget(#MainButtonStart, 10, dy-30, 110, 25)
  ResizeGadget(#MainButtonStop, 130, dy-30, 110, 25)
EndProcedure

Procedure Main()
  Protected dx, dy
  
  #MainStyle = #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_MaximizeGadget | #PB_Window_MinimizeGadget
  
  If OpenWindow(#Main, #PB_Ignore, #PB_Ignore, 800, 600, #ProgramTitle , #MainStyle)
    ; Menu
    CreateMenu(#MainMenu, WindowID(#Main))
    MenuTitle("&File")
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      MenuItem(#PB_Menu_About, "")
    CompilerElse
      MenuItem(#MainMenuAbout, "About")
    CompilerEndIf
    ; Menu File Items
    
    CompilerIf Not #PB_Compiler_OS = #PB_OS_MacOS
      MenuBar()
      MenuItem(#MainMenuExit, "E&xit")
    CompilerEndIf
    
    MenuTitle("Logging")
    MenuItem(#MainLevel_0, "Level 0: ModBus Connections")
    MenuItem(#MainLevel_1, "Level 1: Modbus Errors")
    MenuItem(#MainLevel_2, "Level 2: Modbus Data")
    SetMenuItemState(#MainMenu, #MainLevel_0 , 1)
    
    ; StatusBar
    CreateStatusBar(#MainStatusBar, WindowID(#Main))
    AddStatusBarField(#PB_Ignore)
    
    ; Gadgets
    dx = WindowWidth(#Main)
    dy = WindowHeight(#Main) - StatusBarHeight(#MainStatusBar) - MenuHeight()
    ListViewGadget(#MainList, 0, 0, dx, dy-35)
    ButtonGadget(#MainButtonStart, 10, dy-30, 110, 25, "Start")
    ButtonGadget(#MainButtonStop, 130, dy-30, 110, 25, "Stopp")
    
    ; Bind Events
    BindEvent(#PB_Event_SizeWindow, @UpdateWindow(), #Main)
    BindEvent(#MyEvent_ThreadSendString, @DoLogging())
    
    ; Start Server
    If #AutoStart
      ServerData\ThreadId = CreateThread(@thModbusServer(), @ServerData)
      DataThread\ThreadID = CreateThread(@thDataSource(), @DataThread)
    EndIf
    
    Repeat
      Select WaitWindowEvent()
        Case #PB_Event_CloseWindow
          Select EventWindow()
            Case #Main
              If IsThread(ServerData\ThreadId)
                ServerData\Exit = #True
                If WaitThread(ServerData\ThreadId, 5000) = 0
                  KillThread(ServerData\ThreadId)
                EndIf
              EndIf
              If IsThread(DataThread\ThreadID)
                DataThread\Exit = #True
                If WaitThread(DataThread\ThreadId, 5000) = 0
                  KillThread(DataThread\ThreadId)
                EndIf
              EndIf
              Break
              
          EndSelect
          
        Case #PB_Event_Menu
          Select EventMenu()
            CompilerIf #PB_Compiler_OS = #PB_OS_MacOS   
              Case #PB_Menu_About
                PostEvent(#PB_Event_Menu, #Main, #MainMenuAbout)
                
              Case #PB_Menu_Preferences
                
              Case #PB_Menu_Quit
                PostEvent(#PB_Event_CloseWindow, #Main, #Null)
                
            CompilerEndIf
              
            Case #MainMenuExit
              PostEvent(#PB_Event_CloseWindow, #Main, #Null)
              
            Case #MainMenuAbout
              MessageRequester("About", #ProgramTitle + #LF$ + #ProgramVersion, #PB_MessageRequester_Info)
              
            Case #MainLevel_0
              LoggingLevel = 0
              SetMenuItemState(#MainMenu, #MainLevel_0 , 1)
              SetMenuItemState(#MainMenu, #MainLevel_1 , 0)
              SetMenuItemState(#MainMenu, #MainLevel_2 , 0)
              
            Case #MainLevel_1
              LoggingLevel = 1
              SetMenuItemState(#MainMenu, #MainLevel_0 , 0)
              SetMenuItemState(#MainMenu, #MainLevel_1 , 1)
              SetMenuItemState(#MainMenu, #MainLevel_2 , 0)
              
            Case #MainLevel_2
              LoggingLevel = 2
              SetMenuItemState(#MainMenu, #MainLevel_0 , 0)
              SetMenuItemState(#MainMenu, #MainLevel_1 , 0)
              SetMenuItemState(#MainMenu, #MainLevel_2 , 1)
              
          EndSelect
          
          
        Case #PB_Event_Gadget
          Select EventGadget()
            Case #MainList
              Select EventType()
                Case #PB_EventType_Change
                  ;
              EndSelect
              
            Case #MainButtonStart
              If Not IsThread(ServerData\ThreadId)
                ServerData\Exit = #False
                ServerData\ThreadId = CreateThread(@thModbusServer(), @ServerData)
              EndIf
              If Not IsThread(DataThread\ThreadID)
                DataThread\Exit = #False
                DataThread\ThreadID = CreateThread(@thDataSource(), @DataThread)
              EndIf
              
            Case #MainButtonStop
              If IsThread(ServerData\ThreadId)
                ServerData\Exit = #True
              EndIf
              If IsThread(DataThread\ThreadID)
                DataThread\Exit = #True
              EndIf
              
          EndSelect
          
        Case #MyEvent_ThreadSendStatus
          StatusBarText(#MainStatusBar, EventGadget(), FreeString(EventData()))
          
      EndSelect
    ForEver
    
  EndIf
  
EndProcedure : Main()
