Strict

' Preprocessor related:
#MOJO_AUTO_SUSPEND_ENABLED = False

' Imports:
Import mojo

Import brl.databuffer
Import brl.datastream

' Check if we're using HTML5:
#If TARGET = "html5"
	Import dom
	
	Import "native/file_to_databuffer.js"
	
	' External bindings (JavaScript):
	Extern
	
	' Functions:
	
	' File-to-DataBuffer:
	Function LoadFile:DataBuffer(F:File, B_Out:DataBuffer)="loadFile"
	
	' DOM:
	Function log:Void(e:Event) = "window.console.log"
	Function log:Void(f:FileList) = "window.console.log"
	Function log:Void(f:File) = "window.console.log"
	'Function log:Void(o:Object) = "window.console.log"
	
	' Classes:
	Class File
		' Fields:
		Field lastModified:Int
		Field lastModifiedDate:String
		Field name:String
		Field size:Int
		Field fileName:String
		Field fileSize:Int
		Field type:String
	End
	
	Class FileList Extends DOMObject
		' Fields:
		Field length:Int
		
		' Methods:
		Method item:File(index:Int)
	End
	
	Class HTMLFileInputElement Extends HTMLInputElement = "HTMLInputElement"
		' Fields:
		Field files:FileList
	End
	
	Public	
	
	' Classes:
	Class EventRepeater Extends EventListener
		' Constructor(s):
		Method New(Callback:EventHandler)
			Self.Callback = Callback
		End
		
		' Methods:
		Method handleEvent:Int(event:Event)
			Return Callback.HandleEvent(event)
		End
		
		' Fields:
		Field Callback:EventHandler
	End
	
	' Functions:
	Function AddFileRequester:HTMLFileInputElement(listener:EventListener, node:dom.Node)
		Local input:= HTMLFileInputElement(document.createElement("input")) ' HTMLInputElement
		
		input.type = "file"
		input.addEventListener("change", listener)
		
		node.appendChild(input)
		
		Return input
	End
	
	Function AddButton:HTMLInputElement(name:String, listener:EventListener, node:dom.Node)
		Local button:= document.createElement("input")
		
		button.setAttribute("type", "button")
		button.setAttribute("name", name)
		button.setAttribute("value", name)
		button.addEventListener("click", listener)
		
		node.appendChild(button)
		
		Return HTMLInputElement(button)
	End
#Else
	#Error "Please build this application with the HTML5 target."
#End

' Interfaces:
Interface EventHandler
	' Methods:
	Method HandleEvent:Int(event:Event)
End

' Classes:
Class FileApp Extends App Implements EventHandler
	' Constant variable(s):
	Const FILES_NEEDED:= 3
	
	' Methods:
	Method OnCreate:Int()
		SetUpdateRate(30) ' 0 ' 60
		
		Self.running = False
		Self.filesQueued = 0
		
		' This is a dummy object used to get around the limitations of DOM:
		Self.repeater = New EventRepeater(Self)
		
		Self.bodyNode = dom.Node(Element(document.getElementsByTagName("body").item(0)).getElementsByTagName("div").item(0))
		
		Self.fileButtons = New HTMLFileInputElement[FILES_NEEDED]
		Self.files = New DataBuffer[FILES_NEEDED] ' Self.fileButtons.Length
		
		For Local I:= 0 Until fileButtons.Length ' FILES_NEEDED
			Self.fileButtons[I] = AddFileRequester(repeater, bodyNode)
		Next
		
		#If CONFIG = "debug"
			MakeRunButton()
		#End
		
		Return 0
	End
	
	Method HandleEvent:Int(event:Event)
		Select event.type
			Case "change"
				Local fileButton:= GetFileButton(event.target)
				
				If (fileButton <> Null And files.Length > filesQueued) Then
					Local f:File = fileButton.files.item(0)
					
					Print("New file: ~q" + f.name + "~q - " + f.size + " bytes")
					
					files[filesQueued] = LoadFile(f, New DataBuffer())
					
					filesQueued += 1
				Endif
			Case "click"
				If (event.target = runButton) Then
					'Local runButton:= Self.runButton
					
					OnRunButtonPressed()
				Endif
		End Select
		
		Return 1
	End
	
	Method OnFilesLoaded:Void()
		If (runButton <> Null) Then
			Return
		Endif
		
		'running = True
		
		MakeRunButton()
		
		Print("All files have been loaded.")
		
		Return
	End
	
	Method OnRunButtonPressed:Void()
		If (running Or Not AllFilesLoaded) Then
			Return
		Endif
		
		running = True
		
		Print("Starting the application properly.")
		
		Return
	End
	
	Method MakeRunButton:Void()
		If (runButton <> Null) Then
			Return
		Endif
		
		runButton = AddButton("Run", repeater, bodyNode)
		
		Return
	End
	
	Method GetFileButton:HTMLFileInputElement(target:EventTarget)
		For Local I:= 0 Until fileButtons.Length
			If (fileButtons[I] = target) Then ' EventTarget(...)
				Return fileButtons[I]
			Endif
		Next
		
		Return Null
	End
	
	Method OnUpdate:Int()
		If (Not running) Then
			If (AllFilesLoaded) Then
				OnFilesLoaded()
			Endif
			
			Return 0
		Endif
		
		If (MouseHit(MOUSE_LEFT)) Then
			ReadLoadedFiles()
		Endif
		
		Return 0
	End
	
	Method OnRender:Int()
		Cls()
		
		If (Not running) Then
			If (AllFilesLoaded) Then
				DrawText("All files have been loaded.", 8.0, 8.0)
			Else
				' This basically never happens.
				DrawText("Waiting for files; " + FilesCompleted + " completed.", 8.0, 8.0)
			Endif
			
			Return 0
		Endif
		
		DrawText("Running as expected, click on the screen to output all files as plain text.", 8.0, 8.0)
		
		Return 0
	End
	
	Method ReadLoadedFiles:Void()
		For Local I:= 0 Until files.Length
			Local buffer:= files[I]
			Local inputStream:= New DataStream(buffer)
			
			Print("")
			Print("Parsing file #" + (I+1) + ":")
			Print("")
			
			While (Not inputStream.Eof())
				' Read the current line.
				Local line:= inputStream.ReadLine()
				
				Print("Line: " + line)
			Wend
			
			inputStream.Close()
		Next
		
		Print(" ")
		Print("========== End of parsing files===========")
		Print(" ")
		
		Return
	End
	
	' Properties:
	Method AllFilesLoaded:Bool() Property
		Return ((filesQueued = FILES_NEEDED) And FileBuffersLoaded)
	End
	
	Method FileBuffersLoaded:Bool() Property
		For Local I:= 0 Until files.Length
			Local file:= files[I]
			
			If (file <> Null And file.Length = 0) Then
				Return False
			Endif
		Next
		
		Return True
	End
	
	Method FilesCompleted:Int() Property
		Local count:= 0
		
		For Local I:= 0 Until files.Length
			Local file:= files[I]
			
			If (file <> Null And file.Length <> 0) Then
				count += 1
			Endif
		Next
		
		Return count
	End
	
	' Fields:
	Field fileButtons:HTMLFileInputElement[]
	Field runButton:HTMLInputElement
	
	Field files:DataBuffer[]
	
	Field filesQueued:Int
	Field repeater:EventRepeater
	
	Field bodyNode:dom.Node
	
	Field running:Bool
End

' Functions:
Function Main:Int()
	New FileApp()
	
	Return 0
End