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
	
	Private ListaWykresow As CustomListView
	Private WykresSzablon As xChart
	Private DynamiczneWykresy As List
	
	Private DynamiczneWykresy As List	
	Private CzyStronaZbudowana As Boolean
	
	Private OstatnieCzasy As List
	
	Private Stoper As Timer
	
	

End Sub



' mosquitto_sub -v -t '$SYS/broker/clients/connected' Sprawdzanie liczby polaczonych urzadzen

' journalctl -u mosquitto -f Logi mqtt


' sudo ss -tn state established sport = :1883 Pokazuje dane o połączonych urządzeniach 

'ip neigh show    Adresy ip i mac polaczonych urzadzen

Public Sub Initialize As Object
	DynamiczneWykresy.Initialize
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1

	Root.LoadLayout("TempHum")
	B4XPages.SetTitle(Me, "Pomiary Temperatury")
    DynamiczneWykresy.Initialize
		
End Sub




Private Sub B4XPage_Appear

	CzyStronaZbudowana = True
	
	
	UtworzNowyWykresTemp
	UtworzNowyWykresWilg
	
	
	Log("Strona sie pojawila ")
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	MainScreen.mqtt.Publish("lab/temperatura_wilg/sterowanie/", "GET_DEVICES".GetBytes("UTF8")) ' Sprawdz liczbe polaczen
	
'	Stoper.Initialize("Tykniecie", 10000)


End Sub



Public Sub UtworzNowyWykresTemp()
	
	Dim PanelKontener As B4XView = xui.CreatePanel("")
	PanelKontener.SetLayoutAnimated(0, 0, 0, ListaWykresow.AsView.Width, 400dip)
	PanelKontener.LoadLayout("OknoWykresu")
    
	Dim NowyWykres As xChart = WykresSzablon
	Dim SterownikWykresu As ChartController
	
	
	Dim nr As String = DynamiczneWykresy.Size
	SterownikWykresu.Initialize ("Pomiar temperatury nr "&nr,  NowyWykres)
	SterownikWykresu.DodajKrzywa("Temperatura", xui.Color_Red)
	SterownikWykresu.UstawPrzedzialOsiY(10,45.0)
	SterownikWykresu.UstawNazwyOsi("Czas [s]", "°C")
	SterownikWykresu.UstawAutoSkalowanie(True)
	SterownikWykresu.CzestRys = 1
	SterownikWykresu.CzestPunkt = 1
	SterownikWykresu.CzestPodzialki = 100

    
	DynamiczneWykresy.Add(SterownikWykresu)
	ListaWykresow.Add(PanelKontener, NowyWykres)
End Sub





Public Sub UtworzNowyWykresWilg()
	
	Dim PanelKontener As B4XView = xui.CreatePanel("")
	PanelKontener.SetLayoutAnimated(0, 0, 0, ListaWykresow.AsView.Width, 400dip)
	PanelKontener.LoadLayout("OknoWykresu")
    
	Dim NowyWykres As xChart = WykresSzablon
	Dim SterownikWykresu As ChartController
	
	
	Dim nr As String = DynamiczneWykresy.Size
	SterownikWykresu.Initialize ("Pomiar wilgoci nr "&nr,  NowyWykres)
	SterownikWykresu.DodajKrzywa("Wilgoc", xui.Color_Red)
	SterownikWykresu.UstawPrzedzialOsiY(30,100.0)
	SterownikWykresu.UstawNazwyOsi("Czas [s]", "%")
	SterownikWykresu.UstawAutoSkalowanie(False)
	SterownikWykresu.CzestRys = 1
	SterownikWykresu.CzestPunkt = 1
	SterownikWykresu.CzestPodzialki = 100
	
    
	DynamiczneWykresy.Add(SterownikWykresu)
	ListaWykresow.Add(PanelKontener, NowyWykres)
End Sub





Public Sub OdbierzDaneZSieci (Topic As String, Payload() As Byte)
	If CzyStronaZbudowana = False Then Return
    

	Dim msg As String = BytesToString(Payload, 0, Payload.Length, "UTF8")

	
	If Topic = "lab/temperatura_wilg/lista_urzadzen" Then
		If msg.Trim = "" Then
			Log("Brak zarejestrowanych urządzeń w bazie.")
			Return
		End If
		
		Dim TablicaID() As String = Regex.Split(",", msg)
		
		Dim ListaUrzadzen As List
		ListaUrzadzen.Initialize
		
		For Each ID As String In TablicaID
			ListaUrzadzen.Add(ID)
			Log("Wyciągnięte ID: " & ID)
		Next
		
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
