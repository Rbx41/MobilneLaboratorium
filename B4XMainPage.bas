B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	
	Private btnConnect As Button
	Private lblStatus As Label
	Private txtIpAddress As EditText 
    
	'GŁÓWNY OBIEKT SIECIOWY
	Public mqtt As MqttClient
    
	Private const CLIENT_ID As String = "android_telefon_01"
    
	' Deklaracja kolejnych stron
	Private EkranMenu As StronaMenu
	Public EkranRC As StronaRC
	Public EkranTabeli As StronaTabela
	Public EkranKompasu As StronaKompas
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
    
	Root.LoadLayout("LoginLayout")
	B4XPages.SetTitle(Me, "Logowanie do Laboratorium")
    
	' Inicjalizacja podstron (rejestrujemy je w pamięci, ale ich NIE POKAZUJEMY)
	EkranMenu.Initialize
	EkranRC.Initialize
	EkranKompasu.Initialize
	B4XPages.AddPage("StronaMenu", EkranMenu)
	B4XPages.AddPage("StronaRC", EkranRC)
	B4XPages.AddPage("StronaKompas", EkranKompasu) ' <--- NOWE
	
	EkranTabeli.Initialize
	B4XPages.AddPage("StronaTabela", EkranTabeli)
    
	lblStatus.Text = "Oczekuje na połączenie..."
End Sub


Private Sub btnConnect_Click
	Log("Clicked")
	' 1. Zabezpieczenie: Sprawdzamy czy pole nie jest puste
	' Funkcja .Trim usuwa ewentualne spacje, które ktoś mógł przez przypadek wpisać
	If txtIpAddress.Text.Trim = "" Then
		lblStatus.Text = "Błąd: Wpisz adres IP brokera!"
		xui.MsgboxAsync("Błąd: Wpisz adres IP brokera!", "Brak adresu IP")
		Return ' Przerywamy łączenie
	End If
    

	Dim BrokerUrl As String = "tcp://" & txtIpAddress.Text.Trim & ":1883"
    
	lblStatus.Text = "Łączenie z " & txtIpAddress.Text.Trim & "..."
    

	If mqtt.IsInitialized = False Then
		mqtt.Initialize("mqtt", BrokerUrl, CLIENT_ID)
	End If
    
	Dim mo As MqttConnectOptions
	mo.Initialize("", "")
	mqtt.Connect2(mo)
	
End Sub

'  REAKCJA - Odpowiedź od serwera
Sub mqtt_Connected (Success As Boolean)
	If Success Then
		lblStatus.Text = "Połączono!"
        
		' Telefon nasłuchuje napięcia z NodeMCU
		mqtt.Subscribe("lab/rc/#", 0)
        

		B4XPages.ShowPage("StronaMenu")
	Else
		lblStatus.Text = "Błąd połączenia: " & LastException.Message
	End If
End Sub



Private Sub mqtt_MessageArrived (Topic As String, Payload() As Byte)
	If Topic.StartsWith("lab/rc/") Then
		If B4XPages.GetManager.GetPage("StronaRC") <> Null Then
            
			EkranRC.OdbierzDaneZSieci(Topic, Payload)
		End If
	End If
End Sub
