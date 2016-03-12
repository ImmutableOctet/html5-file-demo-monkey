Strict

'original code sourced from Monkey forum posting:
'http://www.monkey-x.com/Community/posts.php?topic=5698

' Imports:
Import mojo

' Check if we're using HTML5:
#If TARGET = "html5"
	Import dom
	
	' External bindings (JavaScript):
	Extern
	
	' Functions:
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
	
	' HTML5-specific Monkey code:
	
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
		Self.filesLoaded = 0
		
		' This is a dummy object used to get around the limitations of DOM:
		Self.repeater = New EventRepeater(Self)
		
		Self.bodyNode = dom.Node(Element(document.getElementsByTagName("body").item(0)).getElementsByTagName("div").item(0))
		
		Self.fileButtons = New HTMLFileInputElement[FILES_NEEDED]
		
		For Local I:= 0 Until fileButtons.Length ' FILES_NEEDED
			Self.fileButtons[I] = AddFileRequester(repeater, bodyNode)
		Next
		
		#If CONFIG = "debug"
			MakerunButton()
		#End
		
		Return 0
	End
	
	Method HandleEvent:Int(event:Event)
		Select event.type
			Case "change"
				Local fileButton:= GetFileButton(event.target)
				
				If (fileButton <> Null) Then
					Local f:File = fileButton.files.item(0)
					
					Print("New file: ~q" + f.name + "~q - " + f.size + " bytes")
					
					filesLoaded += 1
					
					If (AllfilesLoaded) Then
						OnfilesLoaded()
					Endif
				Endif
			Case "click"
				If (event.target = runButton) Then
					'Local runButton:= Self.runButton
					
					OnrunButtonPressed()
				Endif
		End Select
		
		Return 1
	End
	
	Method OnfilesLoaded:Void()
		'running = True
		
		MakerunButton()
		
		Print("All files have been loaded.")
		
		Return
	End
	
	Method OnrunButtonPressed:Void()
		If (running Or Not AllfilesLoaded) Then
			Return
		Endif
		
		running = True
		
		Print("Starting the application properly.")
		
		Return
	End
	
	Method MakerunButton:Void()
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
			Return 0
		Endif
		
		Print("The application is running.")
		
		Return 0
	End
	
	Method OnRender:Int()
		Cls()
		
		If (Not running) Then
			DrawText("Files loaded: " + filesLoaded, 8.0, 8.0)
			
			Return 0
		Endif
		
		DrawText("All files have been loaded.", 8.0, 8.0)
		
		Return 0
	End
	
	' Properties:
	Method AllfilesLoaded:Bool() Property
		Return (filesLoaded = FILES_NEEDED)
	End
	
	' Fields:
	Field fileButtons:HTMLFileInputElement[]
	Field runButton:HTMLInputElement
	
	Field filesLoaded:Int
	Field repeater:EventRepeater
	
	Field bodyNode:dom.Node
	
	Field running:Bool
End

' Functions:
Function Main:Int()
	New FileApp()
	
	Return 0
End