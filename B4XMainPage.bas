B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@

'
'Sub Class_Globals
'	Private Root As B4XView
'	Private xui As XUI
'    
'	' GŁÓWNY OBIEKT SIECIOWY
'	Public mqtt As MqttClient
'	Public const CLIENT_ID As String = "android_telefon_01"
'    
'	' Deklaracja podstron
'	Public EkranLogowania As StronaLogowania



Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	' GŁÓWNY OBIEKT SIECIOWY
	Public mqtt As MqttClient
	Public serialBT As Serial
	Private astream As AsyncStreamsText
	
	Public const CLIENT_ID As String = "android_telefon_01"
    
	' Deklaracja podstron
	Public EkranLogowania As StronaLogowania
	Public EkranRC As StronaRC
	Public EkranKompasu As StronaKompas
	Public EkranTabeli As StronaTabela
	Public EkranTermometru As StronaTermometr ' <--- NOWA STRONA DLA TERMOMETRU
	Public EkranTabeliTermometru As StronaTabelaTemperatura
    
	' Przyciski z widoku MenuPage
	Private btnIdzDoRC As Button
	Private btnIdzDoKompasu As Button
	Private btnIdzDoTerm As Button ' <--- NOWY PRZYCISK
	Private btnIdzPomiaruTempWilg As Button
    
	' Zmienna przechowująca informację, co użytkownik kliknął w Menu
	Public CelLogowania As String = ""
End Sub

Public Sub Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
    
	' ŁADUJEMY PRAWDZIWE MENU NA STARCIE APLIKACJI
	Root.LoadLayout("MenuPage")
	B4XPages.SetTitle(Me, "Menu Główne Laboratorium")
    
	' Inicjalizacja stron
	EkranLogowania.Initialize
	EkranRC.Initialize
	EkranKompasu.Initialize
	EkranTabeli.Initialize
	EkranTermometru.Initialize
	EkranTabeliTermometru.Initialize
	

	
	B4XPages.AddPage("StronaLogowania", EkranLogowania)
	B4XPages.AddPage("StronaRC", EkranRC)
	B4XPages.AddPage("StronaKompas", EkranKompasu)
	B4XPages.AddPage("StronaTabela", EkranTabeli)
	B4XPages.AddPage("StronaTermometr", EkranTermometru) ' <--- Dodanie do pamięci
	B4XPages.AddPage("StronaTabelaTermometr", EkranTabeliTermometru)

End Sub

' =========================================================
' AKCJE Z MENU GŁÓWNEGO 
' =========================================================
Private Sub btnIdzDoRC_Click
	' Zapisujemy cel i idziemy do logowania
	CelLogowania = "StronaRC"
	B4XPages.ShowPage("StronaLogowania")
End Sub

Private Sub btnIdzDoTerm_Click
	' Zapisujemy cel i idziemy do logowania
	Log("btnIdzDoTerm_Click")
	PolaczZBluetooth("00:11:35:89:71:17")
	CelLogowania = "StronaTermometr"
	B4XPages.ShowPage("StronaLogowania")
End Sub

Private Sub btnIdzDoKompasu_Click
	' Kompas nie potrzebuje sieci, więc idziemy tam od razu
	B4XPages.ShowPage("StronaKompas")
End Sub

' =========================================================
' LOGIKA ŁĄCZENIA MQTT (Wywoływana przez Stronę Logowania)
' =========================================================
Public Sub PolaczZSerwerem(AdresIP As String)
	Dim BrokerUrl As String = "tcp://" & AdresIP & ":1883"
    
	If mqtt.IsInitialized = False Then
		mqtt.Initialize("mqtt", BrokerUrl, CLIENT_ID)
	End If
    
	Dim mo As MqttConnectOptions
	mo.Initialize("", "")
	mqtt.Connect2(mo)
End Sub

' --- REAKCJA NA POŁĄCZENIE ---
Sub mqtt_Connected (Success As Boolean)
	If Success Then
		If EkranLogowania.IsInitialized Then EkranLogowania.UstawStatus("Połączono!")
        
		' Zmieniliśmy subskrypcję na "lab/#", żeby łapało i "lab/rc/..." i "lab/temperatura"
		mqtt.Subscribe("lab/#", 0)
        
		' PRZERZUCAMY DO STRONY, KTÓRĄ UŻYTKOWNIK KLIKNĄŁ W MENU!
		If CelLogowania <> "" Then
			B4XPages.ShowPage(CelLogowania)
		End If
	Else
		If EkranLogowania.IsInitialized Then EkranLogowania.UstawStatus("Błąd połączenia!")
	End If
End Sub

' =========================================================
' ODBIÓR DANYCH Z MQTT (TUTAJ TRAFIAJĄ DANE Z PŁYTEK)
' =========================================================
Private Sub mqtt_MessageArrived (Topic As String, Payload() As Byte)
    
	' 1. Dane dla układu RC
	If Topic.StartsWith("lab/rc/") Then
		If EkranRC.IsInitialized Then
			EkranRC.OdbierzDaneZSieci(Topic, Payload)
		End If
	End If
    
	' 2. Dane dla Termometru
'	If Topic = "lab/temperatura" Then
'		If EkranTermometru.IsInitialized Then
'			EkranTermometru.OdbierzDaneZSieci(Topic, Payload)
'		End If
'	End If
    
End Sub

Public Sub PolaczZBluetooth(AdresMAC As String)
	Dim rp As RuntimePermissions
	Dim p As Phone
    
	' Jeśli telefon ma Androida 12 lub nowszego (SDK 31+)
	If p.SdkVersion >= 31 Then
        
		' Najpierw sprawdzamy, czy aplikacja JUŻ MA to uprawnienie
		If rp.Check("android.permission.BLUETOOTH_CONNECT") = False Then
			Log("Brak uprawnienia, pytam system...")
			rp.CheckAndRequest("android.permission.BLUETOOTH_CONNECT")
			Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean)
            
			If Result = False Then
				Log("Odmowa uprawnień Bluetooth!")
				xui.MsgboxAsync("Aplikacja potrzebuje uprawnień do połączenia z aparaturą pomiarową.", "Błąd")
				Return ' Wychodzimy z funkcji
			End If
		Else
			Log("Uprawnienie BLUETOOTH_CONNECT zostało przyznane już wcześniej.")
		End If
        
	End If
    
	' Jeśli mamy uprawnienia (lub stary system), łączymy się natychmiast
	Log("Próbuję połączyć z: " & AdresMAC)
	If serialBT.IsInitialized = False Then serialBT.Initialize("serialBT")
	serialBT.Connect(AdresMAC)
End Sub


Sub serialBT_Connected (Success As Boolean)
	If Success Then
		Log("Połączono z aparaturą!")
		' Inicjalizujemy AsyncStreamsText, nazwa zdarzenia to "astreamText"
		astream.Initialize(Me, "astreamText", serialBT.InputStream, serialBT.OutputStream)
	Else
		Log("Błąd połączenia sprzętowego...")
	End If
End Sub

Sub astreamText_NewText (Text As String)
	' Jeśli strona istnieje i ma być zaktualizowana:
	EkranTermometru.OdbierzDaneBluetooth(Text)
End Sub


Public Sub WyslijTekstBluetooth (Tekst As String)
	If astream.IsInitialized Then ' astream to Twoja instancja AsyncStreams
		astream.Write(Tekst)
	End If
End Sub