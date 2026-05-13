B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	Private btnIdzDoRC As Button
	Private btnIdzDoKompasu As Button
End Sub


Public Sub Initialize As Object
	Return Me
End Sub


Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MenuPage")
	B4XPages.SetTitle(Me, "Menu Główne Laboratorium")
End Sub

' --- AKCJE PRZYCISKÓW ---

' Kiedy użytkownik kliknie przycisk "Eksperyment RC"
Private Sub btnIdzDoRC_Click
	
	B4XPages.ShowPage("StronaRC")
End Sub

Private Sub btnIdzDoKompasu_Click
	B4XPages.ShowPage("StronaKompas")
End Sub