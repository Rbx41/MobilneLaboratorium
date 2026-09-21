B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@


Sub Class_Globals
	Public Wartosci As List
	Public Czasy As List
	Public Etykieta As String
	Public Kolor As Int

End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(Etykieta_ As String ,Kolor_ As Int)
	Kolor = Kolor_
	Etykieta = Etykieta_
End Sub

Public Sub DodajPunkt(Czas As Double , Wartosc As Double)
	Czasy.Add(Czas)
	Wartosci.Add(Wartosc)
End Sub