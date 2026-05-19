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
	Public const CLIENT_ID As String = "android_telefon_01"
    
	' Deklaracja podstron
	Public EkranLogowania As StronaLogowania
	Public EkranRC As StronaRC
	Public EkranKompasu As StronaKompas
	Public EkranTabeli As StronaTabela
	Public EkranTermometru As StronaTermometr ' <--- NOWA STRONA DLA TERMOMETRU
    
	' Przyciski z widoku MenuPage
	Private btnIdzDoRC As Button
	Private btnIdzDoKompasu As Button
	Private btnIdzDoTerm As Button ' <--- NOWY PRZYCISK
    
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
	EkranTermometru.Initialize ' <--- Inicjalizacja
    
	B4XPages.AddPage("StronaLogowania", EkranLogowania)
	B4XPages.AddPage("StronaRC", EkranRC)
	B4XPages.AddPage("StronaKompas", EkranKompasu)
	B4XPages.AddPage("StronaTabela", EkranTabeli)
	B4XPages.AddPage("StronaTermometr", EkranTermometru) ' <--- Dodanie do pamięci
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
	If Topic = "lab/temperatura" Then
		If EkranTermometru.IsInitialized Then
			EkranTermometru.OdbierzDaneZSieci(Topic, Payload)
		End If
	End If
    
End Sub