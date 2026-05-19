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



' Kiedy użytkownik kliknie przycisk "Eksperyment RC"
Private Sub btnIdzDoRC_Click
	' ==============================================================
	' !!! ZMIANA !!!
	' Zamiast iść bezpośrednio do StronaRC, otwieramy najpierw
	' stronę logowania z serwerem, czyli "B4XMainPage"
	' ==============================================================
	B4XPages.ShowPage("B4XMainPage")
End Sub



Private Sub btnIdzDoTerm_Click
	' ==============================================================
	' !!! ZMIANA !!!
	' Zamiast iść bezpośrednio do StronaRC, otwieramy najpierw
	' stronę logowania z serwerem, czyli "B4XMainPage"
	' ==============================================================
	B4XPages.ShowPage("B4XMainPage")
End Sub


Private Sub btnIdzDoKompasu_Click
	B4XPages.ShowPage("StronaKompas")
End Sub