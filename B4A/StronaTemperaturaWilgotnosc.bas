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
	
	Private Const TEMAT_LISTA_URZADZEN As String = "lab/temperatura_wilg/zarejestrowane_urzadzenia"
	Private Const PREFIKS_STATUS As String = "lab/temperatura_wilg/status/"
	Private Const PREFIKS_POMIARY As String = "lab/temperatura_wilg/pomiary/"
	Private Const PREFIKS_HISTORIA As String = "lab/temperatura_wilg/historia/"
	

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

		If OstatniKliknietyWykres_1.IsInitialized And OstatniKliknietyWykres_2.IsInitialized Then
			OstatniKliknietyWykres_1.DrawOuterFrame = False
			OstatniKliknietyWykres_1.DrawChart
			
			OstatniKliknietyWykres_2.DrawOuterFrame = False
			OstatniKliknietyWykres_2.DrawChart
        End If

       
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
	If CzyStronaZbudowana = False Then Return
    
	' Dekodujemy tablicę bajtów TYLKO RAZ na samym początku:
	Dim wiadomosc As String = BytesToString(Payload, 0, Payload.Length, "UTF8").Trim

	If Topic = TEMAT_LISTA_URZADZEN Then
		ObsluzListeUrzadzen(wiadomosc)
        
	Else If Topic.StartsWith(PREFIKS_STATUS) Then
		Dim mac As String = Topic.SubString(PREFIKS_STATUS.Length).Trim
		ObsluzStatusUrzadzenia(mac, wiadomosc.ToLowerCase)
        
	Else If Topic.StartsWith(PREFIKS_POMIARY) Then
		Dim mac As String = Topic.SubString(PREFIKS_POMIARY.Length).Trim
		ObsluzNowyPomiar(mac, wiadomosc)
        
	Else If Topic.StartsWith(PREFIKS_HISTORIA) Then
		Dim mac As String = Topic.SubString(PREFIKS_HISTORIA.Length).Trim
		ObsluzHistoriePomiarow(mac, wiadomosc)
	End If
End Sub
' 1. Obsługa słownika zarejestrowanych urządzeń przy starcie
Private Sub ObsluzListeUrzadzen(jsonStr As String)
	Log("=== B4A: ODEBRANO SŁOWNIK STATUSÓW: " & jsonStr)
    
	Dim parser As JSONParser
	parser.Initialize(jsonStr)
	Urzadzenia = parser.NextObject

	For Each mac As String In Urzadzenia.Keys
		Dim stan As String = Urzadzenia.Get(mac)
		UpewnijSieZeWykresyIstnieja(mac, stan)
		PobierzHistorieUrzadzenia(mac, 200)
	Next
End Sub

' 2. Obsługa zmiany statusu (online / offline LWT)
Private Sub ObsluzStatusUrzadzenia(macAdres As String, stan As String)
	If Urzadzenia.IsInitialized = False Or Urzadzenia.ContainsKey(macAdres) = False Then Return
    
	Urzadzenia.Put(macAdres, stan)
    
	If WykresyTemp.ContainsKey(macAdres) And WykresyWilg.ContainsKey(macAdres) Then
		Dim ctrlTemp As ChartController = WykresyTemp.Get(macAdres)
		Dim ctrlWilg As ChartController = WykresyWilg.Get(macAdres)
        
		ctrlTemp.UstawTytul("adres urzadzenia: " & macAdres & " stan: " & stan)
		ctrlWilg.UstawTytul("adres urzadzenia: " & macAdres & " stan: " & stan)
	End If
    
	If stan = "online" Then
		ToastMessageShow("Urządzenie [" & macAdres & "] jest ONLINE", False)
	Else If stan = "offline" Then
		ToastMessageShow("Urządzenie [" & macAdres & "] przeszło w tryb OFFLINE!", True)
	End If
End Sub

' 3. Obsługa pojedynczego pomiaru live (CSV: temp,wilg,czas)
Private Sub ObsluzNowyPomiar(macAdres As String, daneCsv As String)
	Dim wartosci() As String = Regex.Split(",", daneCsv)
	If wartosci.Length < 3 Then Return
    
	Dim temp As Double = wartosci(0)
	Dim wilg As Double = wartosci(1)
	Dim czas_s As Double = wartosci(2)
    
	UpewnijSieZeWykresyIstnieja(macAdres, "online")
    
	Dim ctrlTemp As ChartController = WykresyTemp.Get(macAdres)
	Dim ctrlWilg As ChartController = WykresyWilg.Get(macAdres)
    
	ctrlTemp.DodajPunkt(czas_s, temp)
	ctrlWilg.DodajPunkt(czas_s, wilg)
End Sub

' 4. Obsługa paczki historycznej z bazy SQLite (JSON Array)
Private Sub ObsluzHistoriePomiarow(macAdres As String, jsonStr As String)
	Log("=== B4A: ODEBRANO HISTORIĘ DLA [" & macAdres & "] ===")
    
	Dim parser As JSONParser
	parser.Initialize(jsonStr)
	Dim listaPunktow As List = parser.NextArray
    
	If listaPunktow.Size = 0 Then Return
    
	UpewnijSieZeWykresyIstnieja(macAdres, "online")
    
	Dim ctrlTemp As ChartController = WykresyTemp.Get(macAdres)
	Dim ctrlWilg As ChartController = WykresyWilg.Get(macAdres)
    
	For Each pomiar As Map In listaPunktow
		Dim temp As Double = pomiar.Get("t")
		Dim wilg As Double = pomiar.Get("h")
		Dim czas_s As Double = pomiar.Get("c")
        
		ctrlTemp.DodajPunkt(czas_s, temp)
		ctrlWilg.DodajPunkt(czas_s, wilg)
	Next
    
	ToastMessageShow("Wczytano historię: " & listaPunktow.Size & " punktów", False)
End Sub

' Metoda pomocnicza (usuwa duplikację kodu tworzenia/aktualizacji wykresów)
Private Sub UpewnijSieZeWykresyIstnieja(mac As String, stan As String)
	If WykresyTemp.ContainsKey(mac) = False Then
		UtworzNowyWykresTemp(mac, stan)
		UtworzNowyWykresWilg(mac, stan)
	Else
		Dim ctrlT As ChartController = WykresyTemp.Get(mac)
		Dim ctrlW As ChartController = WykresyWilg.Get(mac)
		ctrlT.UstawTytul("adres urzadzenia: " & mac & " stan: " & stan)
		ctrlW.UstawTytul("adres urzadzenia: " & mac & " stan: " & stan)
	End If
End Sub




Private Sub btnNowyPomiar_Click
	' Upewniamy się, czy użytkownik na pewno chce skasować stare dane
	xui.Msgbox2Async("Czy na pewno chcesz usunąć stare pomiary z pamięci na Malince i zacząć nagrywać od nowa?", "Nowy eksperyment", "Tak, start", "", "Anuluj", Null)
	Wait For Msgbox_Result (Result As Int)
    
	If Result = xui.DialogResponse_Positive Then
        
		Dim MainScreen As B4XMainPage = B4XPages.MainPage
		If MainScreen.mqtt.Connected Then
			
			Dim id As String  = OstatniKliknietyWykres_1.Tag
			Dim mac As String = id.Replace("_WILG", "")
			Dim mac As String = mac.Replace("_TEMP", "")
			
			Dim ctrlTemp As ChartController = WykresyTemp.Get(mac)
			Dim ctrlWilg As ChartController = WykresyWilg.Get(mac)
			
			ctrlTemp.ResetujWykres
			ctrlWilg.ResetujWykres
			
			
			MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/"&mac, "RESET".GetBytes("UTF8"))
			Log("Wysłano komendę RESET do miniserwera!")
		End If

	End If
End Sub





Private Sub btnWlacz_Click
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		' Wysyłamy komendę START do NodeMCU
		Dim id As String  = OstatniKliknietyWykres_1.Tag
		Dim mac As String = id.Replace("_WILG", "")
		Dim mac As String = mac.Replace("_TEMP", "")
		
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
		Dim mac As String = mac.Replace("_TEMP", "")
		MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/"&mac, "STOP".GetBytes("UTF8"))
		Log("Wysłano komendę STOP")
		xui.MsgboxAsync("Zatrzymano pomiary.", "Status")
	End If
End Sub

