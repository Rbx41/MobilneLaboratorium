B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@



Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	
	Public mqtt As MqttClient
	Public serialBT As Serial
	Private astream As AsyncStreamsText
	
	Public const CLIENT_ID As String = "android_telefon_01"
    
	
	Public EkranLogowania As StronaLogowania
	Public EkranRC As StronaRC
	Public EkranKompasu As StronaKompas
	Public EkranTabeli As StronaTabela
	Public EkranTermometru As StronaTermometr
	Public EkranTemperaturyWilgotnosci As StronaTemperaturaWilgotnosc
	
	Public EkranTabeliTermometru As StronaTabelaTemperatura
    
	
	Private btnIdzDoRC As Button
	Private btnIdzDoKompasu As Button
	Private btnIdzDoTerm As Button
	Private btnIdzPomiaruTempWilg As Button

	Public CelLogowania As String = ""
	Private EkranPrzewijany As ScrollView
End Sub

Public Sub Initialize As Object
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
    

	EkranPrzewijany.Initialize(900dip)
	Root.AddView(EkranPrzewijany, 0, 0, 100%x, 100%y)
	EkranPrzewijany.Panel.LoadLayout("MenuPage")
	B4XPages.SetTitle(Me, "Menu Główne Laboratorium")
    

	EkranLogowania.Initialize
	EkranRC.Initialize
	EkranKompasu.Initialize
	EkranTabeli.Initialize
	EkranTermometru.Initialize
	EkranTabeliTermometru.Initialize
	EkranTemperaturyWilgotnosci.Initialize

	
	B4XPages.AddPage("StronaLogowania", EkranLogowania)
	B4XPages.AddPage("StronaRC", EkranRC)
	B4XPages.AddPage("StronaKompas", EkranKompasu)
	B4XPages.AddPage("StronaTabela", EkranTabeli)
	B4XPages.AddPage("StronaTermometr", EkranTermometru) 
	B4XPages.AddPage("StronaTabelaTermometr", EkranTabeliTermometru)
	B4XPages.AddPage("StronaTemperaturaWilgotnosc", EkranTemperaturyWilgotnosci)

End Sub


Private Sub btnIdzDoRC_Click
	CelLogowania = "StronaRC"
	B4XPages.ShowPage("StronaLogowania")
End Sub

Private Sub btnIdzDoTerm_Click
	PolaczZBluetooth("00:11:35:89:71:17")
	CelLogowania = "StronaTermometr"
	B4XPages.ShowPage("StronaTermometr")
End Sub

Private Sub btnIdzDoKompasu_Click
	B4XPages.ShowPage("StronaKompas")
End Sub


Private Sub btnIdzPomiaruTempWilg_Click
	CelLogowania = "StronaRC"
	B4XPages.ShowPage("StronaLogowania")
End Sub



Public Sub PolaczZSerwerem(AdresIP As String)
	Dim BrokerUrl As String = "tcp://" & AdresIP & ":1883"
   
	If mqtt.IsInitialized And mqtt.Connected Then
		Log("Już połączono z brokerem.")
		Return
	End If
    
	
	mqtt.Initialize("mqtt", BrokerUrl, CLIENT_ID)
    
	Dim mo As MqttConnectOptions
	mo.Initialize("", "")
    
	Try
		mqtt.Connect2(mo)
	Catch
		Log("Błąd wywołania Connect2: " & LastException.Message)
		If EkranLogowania.IsInitialized Then
			EkranLogowania.UstawStatus("Serwer zajęty, spróbuj ponownie...")
		End If
	End Try
End Sub




Sub mqtt_Connected (Success As Boolean)
	If Success Then
		Log("Suckes")
		If EkranLogowania.IsInitialized Then EkranLogowania.UstawStatus("Połączono!")
		mqtt.Subscribe("lab/#", 0)
		If CelLogowania <> "" Then
			B4XPages.ShowPage(CelLogowania)
		End If
	Else
		If EkranLogowania.IsInitialized Then
			EkranLogowania.UstawStatus("Błąd: Nie znaleziono brokera!")
		End If
	End If
End Sub



Private Sub mqtt_MessageArrived (Topic As String, Payload() As Byte)

	If Topic.StartsWith("lab/rc/") Then
		If EkranRC.IsInitialized Then
			EkranRC.OdbierzDaneZSieci(Topic, Payload)
		End If
	End If
    
End Sub

Public Sub PolaczZBluetooth(AdresMAC As String)
	Dim rp As RuntimePermissions
	Dim p As Phone

	If p.SdkVersion >= 31 Then
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
    
	Log("Próbuję połączyć z: " & AdresMAC)
	If serialBT.IsInitialized = False Then serialBT.Initialize("serialBT")
	serialBT.Connect(AdresMAC)
End Sub


Sub serialBT_Connected (Success As Boolean)
	If Success Then
		Log("Połączono z aparaturą!")
		astream.Initialize(Me, "astreamText", serialBT.InputStream, serialBT.OutputStream)
	Else
		Log("Błąd połączenia sprzętowego...")
	End If
End Sub




Sub astreamText_NewText (Text As String)
	EkranTermometru.OdbierzDaneBluetooth(Text)
End Sub


Public Sub WyslijTekstBluetooth (Tekst As String)
	If astream.IsInitialized Then 
		astream.Write(Tekst)
	End If
End Sub

