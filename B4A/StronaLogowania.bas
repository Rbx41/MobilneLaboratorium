B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	Private btnConnect As Button
	Private lblStatus As Label
	Private txtIpAddress As EditText
End Sub

Public Sub Initialize As Object
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
    
	' Ładujemy układ formularza połączeniowego
	Root.LoadLayout("LoginLayout")
	B4XPages.SetTitle(Me, "Nawiązywanie połączenia")
	lblStatus.Text = "Oczekuje na adres IP..."
End Sub

Public Sub UstawStatus(Tekst As String)
	If lblStatus.IsInitialized Then
		lblStatus.Text = Tekst
	End If
End Sub



Private Sub btnConnect_Click
    If txtIpAddress.Text.Trim = "" Then
        lblStatus.Text = "Błąd: Wpisz adres IP brokera!"
        xui.MsgboxAsync("Błąd: Wpisz adres IP brokera!", "Brak adresu IP")
        Return 
    End If
    
    Dim MainScreen As B4XMainPage = B4XPages.MainPage
    
    ' ZABEZPIECZENIE: Sprawdzamy, czy nie jesteśmy już połączeni
    If MainScreen.mqtt.IsInitialized And MainScreen.mqtt.Connected Then
        Log("MQTT jest już połączone! Pomijam łączenie.")
        lblStatus.Text = "Już połączono!"
        B4XPages.ShowPage("StronaRC") 
        Return 
    End If
    
    lblStatus.Text = "Łączenie z " & txtIpAddress.Text.Trim & "..."
    
    ' !!! ROZWIĄZANIE PROBLEMU !!!
    ' Nie inicjalizujemy MQTT tutaj. Przekazujemy adres IP do B4XMainPage 
    ' i to on wykonuje całą "brudną robotę".
    MainScreen.PolaczZSerwerem(txtIpAddress.Text.Trim)
End Sub