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

	
	Private Urzadzenia As Map
	
	Private WykresyTemp As Map	
	Private WykresyWilg As Map
	
	
	
	Private CzyStronaZbudowana As Boolean
	
	Private WykresSzablon As xChart
	
	Private OstatnieCzasy As List
	
	Private Stoper As Timer
	
	Dim OstatniKliknietyWykres_1 As xChart
	Dim OstatniKliknietyWykres_2 As xChart
	
	

	Private ListaWykresow As CustomListView
End Sub



' mosquitto_sub -v -t '$SYS/broker/clients/connected' Sprawdzanie liczby polaczonych urzadzen

' journalctl -u mosquitto -f Logi mqtt


' sudo ss -tn state established sport = :1883 Pokazuje dane o połączonych urządzeniach 

'ip neigh show    Adresy ip i mac polaczonych urzadzen
'
Public Sub Initialize As Object
	WykresyTemp.Initialize
	WykresyWilg.Initialize
	Urzadzenia.Initialize

	
	
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1

	Root.LoadLayout("TempHum")
	B4XPages.SetTitle(Me, "Pomiary Temperatury")
	

	
    WykresyTemp.Initialize
	WykresyWilg.Initialize
	
'	ListaWykresow.AsView.ScrollViewOffsetY = 500
	

	
End Sub




Private Sub B4XPage_Appear

	CzyStronaZbudowana = True

	Log("Strona sie pojawila ")
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	
	PobierzStatusyUrzadzen
	
	MainScreen.mqtt.Publish("lab/temperatura_wilg/zapytania/", "GET_DEVICES".GetBytes("UTF8")) ' Sprawdz liczbe polaczen
	


	
	
	
'	Stoper.Initialize("Tykniecie", 10000)


End Sub



Public Sub UtworzNowyWykresTemp(mac As String, status As String)

	Dim PanelKontener As B4XView = xui.CreatePanel("")
	
	
'	PanelKontener.SetTextAlignment("TOP","CENTER")
	
	
	PanelKontener.SetLayoutAnimated(0, 0, 0, ListaWykresow.AsView.Width, 350dip)
	PanelKontener.LoadLayout("OknoWykresu")

   
	
	Dim NowyWykres As xChart = WykresSzablon
	
	NowyWykres.Tag = mac & "_TEMP" 
	
	Dim SterownikWykresu As ChartController
	Dim nr As String = WykresyTemp.Size
	SterownikWykresu.Initialize ("adres urzadzenia: "&mac&" stan: "&status,  NowyWykres)
	SterownikWykresu.DodajKrzywa("Temperatura", xui.Color_Red)
	SterownikWykresu.UstawPrzedzialOsiY(10,45.0)
	SterownikWykresu.UstawNazwyOsi("Czas [s]", "°C")
	SterownikWykresu.UstawAutoSkalowanie(True)
	SterownikWykresu.CzestRys = 1
	SterownikWykresu.CzestPunkt = 1
	SterownikWykresu.CzestPodzialki = 100
	


	WykresyTemp.Put(mac,SterownikWykresu)
	
	ListaWykresow.Add(PanelKontener, NowyWykres)
	

End Sub





Public Sub UtworzNowyWykresWilg(mac As String, status As String)
	
	Dim PanelKontener As B4XView = xui.CreatePanel("")
	PanelKontener.SetLayoutAnimated(0, 0, 0, ListaWykresow.AsView.Width, 350dip)
	PanelKontener.LoadLayout("OknoWykresu")
	
    
	Dim NowyWykres As xChart = WykresSzablon
	
	NowyWykres.Tag = mac & "_WILG"
	
	Dim SterownikWykresu As ChartController
	Dim nr As String = WykresyWilg.Size
	SterownikWykresu.Initialize ("adres urzadzenia: "&mac&" stan: "&status,  NowyWykres)
	SterownikWykresu.DodajKrzywa("Wilgoc", xui.Color_Red)
	SterownikWykresu.UstawPrzedzialOsiY(0,100.0)
	SterownikWykresu.UstawNazwyOsi("Czas [s]", "%")
	SterownikWykresu.UstawAutoSkalowanie(True)
	SterownikWykresu.CzestRys = 1
	SterownikWykresu.CzestPunkt = 1
	SterownikWykresu.CzestPodzialki = 100
	
'	SterownikWykresu.DodajPunkt(0,0)
    
	WykresyWilg.Put(mac,SterownikWykresu)
	
	ListaWykresow.Add(PanelKontener, NowyWykres)
	
End Sub




Private Sub WykresSzablon_CursorTouch (Action As Int, CursorPointIndex As Int)
    If Action = 0 Then
		
        Dim kliknietyWykres As xChart = Sender
        Dim identyfikator As String = kliknietyWykres.Tag
        
        Dim mac As String = ""
        Dim BlizniaczyKontroler As ChartController
		
        
'        ' 1. Rozpoznajemy typ i pobieramy parę z przeciwnej mapy:
        If identyfikator.EndsWith("_TEMP") Then
            mac = identyfikator.Replace("_TEMP", "")
			Log(mac)
            If WykresyWilg.IsInitialized And WykresyWilg.ContainsKey(mac) Then
                BlizniaczyKontroler = WykresyWilg.Get(mac)
            End If
		
            
        Else If identyfikator.EndsWith("_WILG") Then
            mac = identyfikator.Replace("_WILG", "")
			Log(mac)
            If WykresyTemp.IsInitialized And WykresyTemp.ContainsKey(mac) Then
                BlizniaczyKontroler = WykresyTemp.Get(mac)
            End If

        End If

        ' 2. Reset zaznaczenia poprzedniego wykresu
		If OstatniKliknietyWykres_1.IsInitialized And OstatniKliknietyWykres_2.IsInitialized Then
			OstatniKliknietyWykres_1.DrawOuterFrame = False
			OstatniKliknietyWykres_1.DrawChart
			
			OstatniKliknietyWykres_2.DrawOuterFrame = False
			OstatniKliknietyWykres_2.DrawChart
        End If

        ' 3. Zaznaczenie klikniętego wykresu
        kliknietyWykres.DrawOuterFrame = True
        kliknietyWykres.DrawChart
        OstatniKliknietyWykres_1 = kliknietyWykres
		
		Dim BlizniaczyWykres As xChart = BlizniaczyKontroler.WezWykres
		BlizniaczyWykres.DrawOuterFrame = True
		BlizniaczyWykres.DrawChart
		OstatniKliknietyWykres_2 = BlizniaczyWykres
  
        
    End If
	
	
End Sub




Public Sub PobierzLiczbeUrzadzen
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	
	
	Dim cmd As String = "GET_COUNT"
	MainScreen.mqtt.Publish("lab/temperatura_wilg/zapytania/", cmd.GetBytes("UTF8"))

End Sub



Public Sub PobierzStatusyUrzadzen
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		Dim cmd() As Byte = "GET_STATUSES".GetBytes("utf8")
		MainScreen.mqtt.Publish("lab/temperatura_wilg/zapytania/", cmd)
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
        
		MainScreen.mqtt.Publish("lab/temperatura_wilg/zapytania/", cmdBytes)
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


	
'	If Topic = "lab/temperatura_wilg/zarejestrowane_urzadzenia" Then
'		Dim jsonStr As String = BytesToString(Payload, 0, Payload.Length, "utf8")
'		Log("=== B4A: ODEBRANO SLOWNIK STATUSOW ===")
'		Log(jsonStr)
'            
'		Dim parser As JSONParser
'		parser.Initialize(jsonStr)
'		
''		Dim SlownikStatusow As Map = parser.NextObject
'		Urzadzenia = parser.NextObject
'
'		' Wypisujemy zawartość słownika do okna Logów
'		For Each mac As String In Urzadzenia.Keys
'			Dim stan As String = Urzadzenia.Get(mac)
'			Log("-> Urządzenie: " & mac & " | Stan: " & stan)
'			Urzadzenia.Put(mac, stan)
'			UtworzNowyWykresTemp(mac, stan)
'			UtworzNowyWykresWilg(mac, stan)
'			
'			PobierzHistorieUrzadzenia(mac, 200)
'		Next
'		
'		
'		Return
'	End If


	If Topic = "lab/temperatura_wilg/zarejestrowane_urzadzenia" Then
		Dim jsonStr As String = BytesToString(Payload, 0, Payload.Length, "utf8")
		Log("=== B4A: ODEBRANO SLOWNIK STATUSOW ===")
		Log(jsonStr)
        
		Dim parser As JSONParser
		parser.Initialize(jsonStr)
		Urzadzenia = parser.NextObject

		For Each mac As String In Urzadzenia.Keys
			Dim stan As String = Urzadzenia.Get(mac)
			Log("-> Urządzenie: " & mac & " | Stan: " & stan)
        
			' Twórz wykresy TYLKO jeśli jeszcze nie istnieją na liście
			If WykresyTemp.ContainsKey(mac) = False Then
				UtworzNowyWykresTemp(mac, stan)
				UtworzNowyWykresWilg(mac, stan)
			Else
				' Jeśli już istnieją, zaktualizuj jedynie ich nagłówki
				Dim ctrlT As ChartController = WykresyTemp.Get(mac)
				Dim ctrlW As ChartController = WykresyWilg.Get(mac)
				ctrlT.UstawTytul("adres urzadzenia: " & mac & " stan: " & stan)
				ctrlW.UstawTytul("adres urzadzenia: " & mac & " stan: " & stan)
			End If
        
			PobierzHistorieUrzadzenia(mac, 200)
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
		Else
			Return
		End If
        
		' Aktualizacja stanu w lokalnej pamięci telefonu
		If Urzadzenia.IsInitialized = False Then Urzadzenia.Initialize
		Urzadzenia.Put(macAdres, stan)
        
		Dim WykresTemp As ChartController = WykresyTemp.Get(macAdres)
		Dim WykresWilg As ChartController = WykresyWilg.Get(macAdres)
		
		If WykresyTemp.IsInitialized And WykresyWilg.IsInitialized Then
			Log("Wykresy zainicjowane")
		Else
			Log("Wykresy zainicjowane !!!! Może wywalić błąd !!!!!!!!!!!")
		End If
		
		Log(macAdres)
		Log(stan)
		
		WykresTemp.UstawTytul("adres urzadzenia: "&macAdres&" stan: "&stan)
		WykresWilg.UstawTytul("adres urzadzenia: "&macAdres&" stan: "&stan)
		
		
		
		
		
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
'		If Urzadzenia.IsInitialized Then
'			If Urzadzenia.GetDefault(macAdres, "offline") <> "online" Then
'				Urzadzenia.Put(macAdres, "online")
'			End If
'		End If
'        
'		Log("B4A Pomiar -> [" & macAdres & "]: " & daneStr)

		Dim wartosci() As String = Regex.Split(",", daneStr)
		If wartosci.Length >= 3 Then
			Dim temp As Double = wartosci(0)
			Dim wilg As Double = wartosci(1)
			Dim czas_s As Double = wartosci(2)
            
			' Jeśli wykres dla tego urządzenia jeszcze nie istnieje, utwórz go
			If WykresyTemp.ContainsKey(macAdres) = False Then
				UtworzNowyWykresTemp(macAdres, "podlaczone")
				UtworzNowyWykresWilg(macAdres, "podlaczone")
			End If
            
			' Pobieramy właściwe sterowniki bezpośrednio po kluczu MAC:
			Dim ctrlTemp As ChartController = WykresyTemp.Get(macAdres)
			Dim ctrlWilg As ChartController = WykresyWilg.Get(macAdres)
            
			ctrlTemp.DodajPunkt(czas_s, temp)	
			ctrlWilg.DodajPunkt(czas_s, wilg)
		End If
		Return
        
		' Tutaj dopisujemy dane do wykresu xChart:
		' np. PrzekazPomiarDoWykresu(macAdres, daneStr)
		Return
	End If
	
	
	Dim PrefiksHistoria As String = "lab/temperatura_wilg/historia/"
	If Topic.StartsWith(PrefiksHistoria) Then
		Dim macAdres As String = Topic.SubString(PrefiksHistoria.Length).Trim
		Dim jsonStr As String = BytesToString(Payload, 0, Payload.Length, "utf8")
        
		Log("=== B4A: ODEBRANO HISTORIĘ DLA URZĄDZENIA [" & macAdres & "] ===")
'		UtworzNowyWykresTemp(macAdres)
'		UtworzNowyWykresWilg(macAdres)
		
        
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
			Dim ctrlTemp As ChartController = WykresyTemp.Get(macAdres)
			Dim ctrlWilg As ChartController = WykresyWilg.Get(macAdres)
			
			ctrlTemp.DodajPunkt(czas_s, temp)
			ctrlWilg.DodajPunkt(czas_s, wilg)
			
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
			
			Dim id As String  = OstatniKliknietyWykres_1.Tag
			Dim mac As String = id.Replace("_WILG", "")
			Dim mac As String = id.Replace("_TEMP", "")
			
			Dim ctrlTemp As ChartController = WykresyTemp.Get(mac)
			Dim ctrlWilg As ChartController = WykresyWilg.Get(mac)
			
			ctrlTemp.ResetujWykres
			ctrlWilg.ResetujWykres
			
			
			MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/"&mac, "RESET".GetBytes("UTF8"))
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
		Dim id As String  = OstatniKliknietyWykres_1.Tag
		Dim mac As String = id.Replace("_WILG", "")
		Dim mac As String = id.Replace("_TEMP", "")
		
		MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/"&mac, "START".GetBytes("UTF8"))
		xui.MsgboxAsync("Włączono pomiary.", "Status")
	End If
End Sub

Private Sub btnWylacz_Click
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		' Wysyłamy komendę STOP do NodeMCU
		Dim id As String  = OstatniKliknietyWykres_1.Tag
		Dim mac As String = id.Replace("_WILG", "")
		Dim mac As String = id.Replace("_TEMP", "")
		MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/"&mac, "STOP".GetBytes("UTF8"))
		Log("Wysłano komendę STOP")
		xui.MsgboxAsync("Zatrzymano pomiary.", "Status")
	End If
End Sub

