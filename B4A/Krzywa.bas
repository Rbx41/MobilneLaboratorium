B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@


Sub Class_Globals


	Public Etykieta As String
	Public Kolor As Int
	Public Id As Int

End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(Etykieta_ As String ,Kolor_ As Int, Id_ As Int)
	Kolor = Kolor_
	Etykieta = Etykieta_
	Id = Id_
End Sub
