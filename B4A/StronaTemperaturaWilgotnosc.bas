B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@


Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    

	Private btnNowyPomiar As Button
	Private btnWlacz As Button
	Private btnWylacz As Button
	
	Private ListaWidokow As CustomListView
	
	Private Urzadzenia As Map
	
	Private DynamiczneWykresyTemp As List	
	Private DynamiczneWykresyWilg As List
	
	
	
	Private CzyStronaZbudowana As Boolean
	
	Private WykresSzablon As xChart
	
	Private OstatnieCzasy As List
	
	Private Stoper As Timer
	
	

End Sub



' mosquitto_sub -v -t '$SYS/broker/clients/connected' Sprawdzanie liczby polaczonych urzadzen

' journalctl -u mosquitto -f Logi mqtt


' sudo ss -tn state established sport = :1883 Pokazuje dane o połączonych urządzeniach 

'ip neigh show    Adresy ip i mac polaczonych urzadzen
'
Public Sub Initialize As Object
	DynamiczneWykresyTemp.Initialize
	DynamiczneWykresyWilg.Initialize
	
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1

	Root.LoadLayout("TempHum")
	B4XPages.SetTitle(Me, "Pomiary Temperatury")
    DynamiczneWykresyTemp.Initialize
	DynamiczneWykresyWilg.Initialize
		
End Sub




Private Sub B4XPage_Appear

	CzyStronaZbudowana = True
	
	
'	UtworzNowyWykresTemp
'	UtworzNowyWykresWilg
	
	
	Log("Strona sie pojawila ")
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	
	PobierzStatusyUrzadzen
	
	MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/", "GET_DEVICES".GetBytes("UTF8")) ' Sprawdz liczbe polaczen
	
'	Stoper.Initialize("Tykniecie", 10000)


End Sub



Public Sub UtworzNowyWykresTemp(mac As String)
	
	Dim PanelKontener As B4XView = xui.CreatePanel("")
	PanelKontener.SetLayoutAnimated(0, 0, 0, ListaWidokow.AsView.Width, 400dip)
	PanelKontener.LoadLayout("OknoWykresu")
    
	Dim NowyWykres As xChart = WykresSzablon
	Dim SterownikWykresu As ChartController
	
	
	Dim nr As String = DynamiczneWykresyTemp.Size
	SterownikWykresu.Initialize ("Pomiar temperatury adres urzadzenia "&mac,  NowyWykres)
	SterownikWykresu.DodajKrzywa("Temperatura", xui.Color_Red)
	SterownikWykresu.UstawPrzedzialOsiY(10,45.0)
	SterownikWykresu.UstawNazwyOsi("Czas [s]", "°C")
	SterownikWykresu.UstawAutoSkalowanie(True)
	SterownikWykresu.CzestRys = 1
	SterownikWykresu.CzestPunkt = 1
	SterownikWykresu.CzestPodzialki = 100

	DynamiczneWykresyTemp.Add(SterownikWykresu)
	ListaWidokow.Add(PanelKontener, NowyWykres)
	
End Sub





Public Sub UtworzNowyWykresWilg(mac As String)
	
	Dim PanelKontener As B4XView = xui.CreatePanel("")
	PanelKontener.SetLayoutAnimated(0, 0, 0, ListaWidokow.AsView.Width, 400dip)
	PanelKontener.LoadLayout("OknoWykresu")
    
	Dim NowyWykres As xChart = WykresSzablon
	Dim SterownikWykresu As ChartController
	
	
	Dim nr As String = DynamiczneWykresyWilg.Size
	SterownikWykresu.Initialize ("Pomiar wilgoci adres urzadzenia "&mac,  NowyWykres)
	SterownikWykresu.DodajKrzywa("Wilgoc", xui.Color_Red)
	SterownikWykresu.UstawPrzedzialOsiY(30,100.0)
	SterownikWykresu.UstawNazwyOsi("Czas [s]", "%")
	SterownikWykresu.UstawAutoSkalowanie(False)
	SterownikWykresu.CzestRys = 1
	SterownikWykresu.CzestPunkt = 1
	SterownikWykresu.CzestPodzialki = 100
	
    
	DynamiczneWykresyWilg.Add(SterownikWykresu)
	ListaWidokow.Add(PanelKontener, NowyWykres)
	
End Sub



Public Sub PobierzLiczbeUrzadzen
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	
	
	Dim cmd As String = "GET_COUNT"
	MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/", cmd.GetBytes("UTF8"))

End Sub



Public Sub PobierzStatusyUrzadzen
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		Dim cmd() As Byte = "GET_STATUSES".GetBytes("utf8")
		MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/", cmd)
		Log("B4A: Wysłano żądanie GET_STATUSES do skryptu.")
	Else
		Log("B4A: Brak połączenia z brokerem MQTT!")
	End If
End Sub


Public Sub PobierzHistorieUrzadzenia(macAdres As String, limitPunktow As Int)
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		' Format komendy: GET_HISTORY:<MAC>:<LIMIT>
		Dim cmd As String = "GET_HISTORY:" & macAdres & ":" & limitPunktow
		Dim cmdBytes() As Byte = cmd.GetBytes("utf8")
        
		MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/", cmdBytes)
		Log("B4A: Wysłano żądanie historii dla [" & macAdres & "], limit: " & limitPunktow)
	Else
		Log("B4A: Brak połączenia z brokerem MQTT!")
	End If
End Sub



Public Sub OdbierzDaneZSieci (Topic As String, Payload() As Byte)
'	Podczas odpalenia aplikacji program pobiera słownik mac : status
'	W kolejnum kroku:
'	Nasłuchuje na temat:
' 	-statusów urządzeń online/ofline
'	-danych pomiarowych konkretnych urzadzen
'	-zarejestrowaniu nowego urzadzenia 


	If CzyStronaZbudowana = False Then Return
    
	Dim msg As String = BytesToString(Payload, 0, Payload.Length, "UTF8")


	
	If Topic = "lab/temperatura_wilg/zarejestrowane_urzadzenia" Then
		Dim jsonStr As String = BytesToString(Payload, 0, Payload.Length, "utf8")
		Log("=== B4A: ODEBRANO SLOWNIK STATUSOW ===")
		Log(jsonStr)
            
		Dim parser As JSONParser
		parser.Initialize(jsonStr)
		
'		Dim SlownikStatusow As Map = parser.NextObject
		Dim Urzadzenia As Map = parser.NextObject

		' Wypisujemy zawartość słownika do okna Logów
		For Each mac As String In Urzadzenia.Keys
			Dim stan As String = Urzadzenia.Get(mac)
			Log("-> Urządzenie: " & mac & " | Stan: " & stan)
			PobierzHistorieUrzadzenia(mac, 500)
		Next
		
		
		Return
	End If


	Dim PrefiksStatus As String = "lab/temperatura_wilg/status/"
	If Topic.StartsWith(PrefiksStatus) Then
		Log("Informacje o statusie")
		' Wycięcie adresu MAC z tematu MQTT
		Dim macAdres As String = Topic.SubString(PrefiksStatus.Length).Trim
		Dim stan As String = BytesToString(Payload, 0, Payload.Length, "utf8").Trim.ToLowerCase
        
		' Sprawdzenie poprzedniego stanu, aby nie dublować powiadomień
		Dim poprzedniStan As String = ""
		If Urzadzenia.IsInitialized And Urzadzenia.ContainsKey(macAdres) Then
			poprzedniStan = Urzadzenia.Get(macAdres)
		End If
        
		' Aktualizacja stanu w lokalnej pamięci telefonu
		If Urzadzenia.IsInitialized = False Then Urzadzenia.Initialize
		Urzadzenia.Put(macAdres, stan)
        
		' Wyświetlenie odpowiedniego powiadomienia na telefonie
		If stan = "online" Then
			Log(">>> POWIADOMIENIE: Urządzenie [" & macAdres & "] połączyło się z siecią!")
			ToastMessageShow("Węzeł [" & macAdres & "] jest ONLINE", False)
            
		Else If stan = "offline" Then
			Log(">>> POWIADOMIENIE: Urządzenie [" & macAdres & "] rozłączone (LWT)!")
			' Dłuższy komunikat Toast dla zdarzenia awaryjnego/rozłączenia
			ToastMessageShow("UWAGA: Stacja [" & macAdres & "] przeszła w tryb OFFLINE!", True)
		End If
        
		Return
	End If

	' =========================================================================
	' 3. CYKLICZNE POMIARY TELEMETRYCZNE Z KONKRETNEGO URZĄDZENIA
	' =========================================================================
	Dim PrefiksPomiary As String = "lab/temperatura_wilg/pomiary/"
	If Topic.StartsWith(PrefiksPomiary) Then
		Dim macAdres As String = Topic.SubString(PrefiksPomiary.Length).Trim
		Dim daneStr As String = BytesToString(Payload, 0, Payload.Length, "utf8").Trim
        
		' Jeśli pomiar przyszedł od urządzenia, które figurowało jako offline, automatycznie oznacz je jako online
		If Urzadzenia.IsInitialized Then
			If Urzadzenia.GetDefault(macAdres, "offline") <> "online" Then
				Urzadzenia.Put(macAdres, "online")
			End If
		End If
        
		Log("B4A Pomiar -> [" & macAdres & "]: " & daneStr)
        
		' Tutaj dopisujemy dane do wykresu xChart:
		' np. PrzekazPomiarDoWykresu(macAdres, daneStr)
		Return
	End If
	
	
	Dim PrefiksHistoria As String = "lab/temperatura_wilg/historia/"
	If Topic.StartsWith(PrefiksHistoria) Then
		Dim macAdres As String = Topic.SubString(PrefiksHistoria.Length).Trim
		Dim jsonStr As String = BytesToString(Payload, 0, Payload.Length, "utf8")
        
		Log("=== B4A: ODEBRANO HISTORIĘ DLA URZĄDZENIA [" & macAdres & "] ===")
		UtworzNowyWykresTemp(mac)
		UtworzNowyWykresWilg(mac)
		
        
		Dim parser As JSONParser
		parser.Initialize(jsonStr)
		Dim listaPunktow As List = parser.NextArray
        
		Log("Wczytano próbek z bazy: " & listaPunktow.Size)
        
		' Przetwarzanie punktów i zasilenie wykresu xChart:
		For Each pomiar As Map In listaPunktow
			Dim temp As Double = pomiar.Get("t")
			Dim wilg As Double = pomiar.Get("h")
			Dim czas_s As Double = pomiar.Get("c")
            
			' Tutaj przekazujesz dane bezpośrednio do instancji xChart / kontrolera wykresu:
			' SterownikWykresu.DodajPunkt(czas_s, temp)
		Next
        
		ToastMessageShow("Wczytano historię: " & listaPunktow.Size & " punktów", False)
		Return
	End If
	
	
End Sub







Private Sub btnNowyPomiar_Click
	' Upewniamy się, czy użytkownik na pewno chce skasować stare dane
	xui.Msgbox2Async("Czy na pewno chcesz usunąć stare pomiary z pamięci na Malince i zacząć nagrywać od nowa?", "Nowy eksperyment", "Tak, start", "", "Anuluj", Null)
	Wait For Msgbox_Result (Result As Int)
    
	If Result = xui.DialogResponse_Positive Then
        
		' 1. Wysyłamy tajną komendę do Malinki, żeby "wyzerowała" plik CSV
		Dim MainScreen As B4XMainPage = B4XPages.MainPage
		If MainScreen.mqtt.Connected Then
			MainScreen.mqtt.Publish("lab/temperatura/sterowanie", "RESET".GetBytes("UTF8"))
			Log("Wysłano komendę RESET do miniserwera!")
		End If
        
		' 2. Czyścimy wszystkie dane u nas w telefonie
'		ListaTemperatur.Clear
'		ListaCzasow.Clear
'		NajnowszyCzasWPamieci = -1
'		RealTimeChart.ClearData
'		RealTimeChart.AddLine("Temperatura [°C]", xui.Color_Red)
'		RealTimeChart.DrawChart
        
		xui.MsgboxAsync("Pamięć wyczyszczona! Włóż czujnik do cieczy. Od teraz Malinka zapisuje nowy, czysty wykres.", "Gotowe")
	End If
End Sub





Private Sub btnWlacz_Click
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		' Wysyłamy komendę START do NodeMCU
		MainScreen.mqtt.Publish("lab/temperatura/sterowanie", "START".GetBytes("UTF8"))
		xui.MsgboxAsync("Włączono pomiary.", "Status")
	End If
End Sub

Private Sub btnWylacz_Click
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		' Wysyłamy komendę STOP do NodeMCU
		MainScreen.mqtt.Publish("lab/temperatura/sterowanie", "STOP".GetBytes("UTF8"))
		Log("Wysłano komendę STOP")
		xui.MsgboxAsync("Zatrzymano pomiary.", "Status")
	End If
End Sub
