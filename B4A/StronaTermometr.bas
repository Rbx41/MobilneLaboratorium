B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@




Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	' Elementy z Visual Designera
	Private RealTimeChart As xChart
	Private btnPokazTabele As Button
	' Warto dodać ten przycisk w Designerze, aby móc wywołać pobieranie z Malinki!
	Private btnPobierzZMalinki As Button
	Private NajnowszyCzasWPamieci As Double = -1
	Private HistoriaPobrana As Boolean = False
	' Zmienna bezpieczeństwa
	Private CzyStronaZbudowana As Boolean = False
    
	' Zmienne do przechowywania historii (współdzielone)
	Public ListaCzasow As List
	Public ListaTemperatur As List
	Private btnPobierzHistorie As Button
	Private btnNowyPomiar As Button
End Sub

Public Sub Initialize As Object
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
    
	Root.LoadLayout("Temp")
	B4XPages.SetTitle(Me, "Pomiary Temperatury")
    
	' Inicjalizacja list
	ListaCzasow.Initialize
	ListaTemperatur.Initialize
    
	' --- KONFIGURACJA WYKRESU ---
	RealTimeChart.ClearData
	RealTimeChart.AddLine("Temperatura [°C]", xui.Color_Red)
    
	RealTimeChart.AutomaticScale = False
	RealTimeChart.YMinValue = 15.0
	RealTimeChart.YMaxValue = 35.0
    
	RealTimeChart.XAxisName = "Czas [s]"
	RealTimeChart.YAxisName = "°C"
	RealTimeChart.DrawChart
    
	CzyStronaZbudowana = True
	Log("Strona Termometru gotowa!")
End Sub

' ==============================================================
' ODBIÓR DANYCH Z MQTT (Na żywo z NodeMCU)
' ==============================================================
Public Sub OdbierzDaneZSieci (Topic As String, Payload() As Byte)
	If CzyStronaZbudowana = False Then Return
    
	Dim msg As String = BytesToString(Payload, 0, Payload.Length, "UTF8")
    
	If Topic = "lab/temperatura" Then
		Dim podzieloneDane() As String = Regex.Split(",", msg)
        
		If podzieloneDane.Length = 2 Then
			Dim WartoscTemperatury As Double = podzieloneDane(0)
			Dim CzasSekundy As Double = podzieloneDane(1)
            
			' Dodaj do lokalnej pamięci RAM
			DodajPunktDoPamieci(WartoscTemperatury, CzasSekundy, True)
		End If
	End If
End Sub

'
'Private Sub DodajPunktDoPamieci(Temp As Double, Czas As Double, RysujWykres As Boolean)
'	' ZABEZPIECZENIE przed dublowaniem
'	If Czas <= NajnowszyCzasWPamieci And ListaCzasow.Size > 0 Then
'		Return
'	End If
'    
'	NajnowszyCzasWPamieci = Czas
'	ListaTemperatur.Add(Temp)
'	ListaCzasow.Add(Czas)
'    
'	' Auto-skalowanie osi Y
'	If Temp >= RealTimeChart.YMaxValue - 1 Then RealTimeChart.YMaxValue = Temp + 5
'	If Temp <= RealTimeChart.YMinValue + 1 Then RealTimeChart.YMinValue = Temp - 5
'    
'	Dim CzasOsX As String = NumberFormat(Czas, 1, 1)
'	RealTimeChart.AddLineMultiplePoints(CzasOsX, Array As Double(Temp), False)
'    
'	' Rysujemy wykres tylko, jeśli przełącznik jest na True
'	If RysujWykres Then
'		RealTimeChart.DrawChart
'	End If
'End Sub

Private Sub DodajPunktDoPamieci(Temp As Double, Czas As Double, RysujWykres As Boolean)
	' ZABEZPIECZENIE przed dublowaniem
	If Czas <= NajnowszyCzasWPamieci And ListaCzasow.Size > 0 Then
		Return
	End If
    
	NajnowszyCzasWPamieci = Czas
	ListaTemperatur.Add(Temp)
	ListaCzasow.Add(Czas)
    
	' Auto-skalowanie osi Y
	If Temp >= RealTimeChart.YMaxValue - 1 Then RealTimeChart.YMaxValue = Temp + 5
	If Temp <= RealTimeChart.YMinValue + 1 Then RealTimeChart.YMinValue = Temp - 5
    
	' Rysujemy wykres na nowo tylko, jeśli przełącznik jest na True
	If RysujWykres Then
		PrzeliczIRysujWykres
	End If
End Sub


Private Sub PrzeliczIRysujWykres
	RealTimeChart.ClearData
	RealTimeChart.AddLine("Temperatura [°C]", xui.Color_Red)
    
	Dim IloscPunktow As Int = ListaCzasow.Size
	If IloscPunktow = 0 Then Return
    
	Dim CzasStartowy As Double = ListaCzasow.Get(0)
    
	' --- TWOJE CENTRUM DOWODZENIA WYKRESEM ---
	Dim MaxPunktowWizualnych As Int = 100
	Dim LiczbaPodzialek As Int = 10
	' -----------------------------------------
    
	Dim KrokDanych As Int = 1
	If IloscPunktow > MaxPunktowWizualnych Then
		KrokDanych = IloscPunktow / MaxPunktowWizualnych
	End If
    
	Dim PunktyNaJednaPodzialke As Int = 1
	If MaxPunktowWizualnych > LiczbaPodzialek Then
		PunktyNaJednaPodzialke = MaxPunktowWizualnych / LiczbaPodzialek
	End If
    
	Dim LicznikNarysowanych As Int = 0
    
	For i = 0 To IloscPunktow - 1 Step KrokDanych
		Dim CzasBezwzgledny As Double = ListaCzasow.Get(i)
		Dim Temp As Double = ListaTemperatur.Get(i)
        
		Dim CzasWzgledny As Double = CzasBezwzgledny - CzasStartowy
        
		Dim EtykietaOsiX As String = ""
		Dim PokazPodpis As Boolean = False ' <--- TA ZMIENNA JEST KLUCZEM
        
		' Wyświetlamy sekundy TYLKO dokładnie co określoną podziałkę
		If LicznikNarysowanych Mod PunktyNaJednaPodzialke = 0 Then
			EtykietaOsiX = NumberFormat(CzasWzgledny, 1, 0) & "s"
			PokazPodpis = True ' Nakazujemy bibliotece narysować ten konkretny tekst!
		End If
        
		' Przekazujemy naszą zmienną zamiast sztywnego False!
		RealTimeChart.AddLineMultiplePoints(EtykietaOsiX, Array As Double(Temp), PokazPodpis)
        
		LicznikNarysowanych = LicznikNarysowanych + 1
	Next
    
	' Twarde rysowanie całości
	RealTimeChart.DrawChart
End Sub

' ==============================================================
' FUNKCJA 1: POBIERANIE ARCHIWALNYCH DANYCH Z RASPBERRY PI
' ==============================================================
Private Sub btnPobierzZMalinki_Click
	Log("Pobieranie pełnej historii stygnięcia z miniserwera...")
    
	Dim job As HttpJob
	job.Initialize("", Me)
    
	' Korzystamy z portu 8080, który uruchomiliśmy przez PM2 na Malince
	job.Download("http://192.168.42.1:8080/stygniecie_cieczy.csv")
    
	Wait For (job) JobDone(job As HttpJob)
    
	If job.Success Then
		' Czyścimy stare dane przed załadowaniem pełnej historii
		ListaTemperatur.Clear
		ListaCzasow.Clear
		NajnowszyCzasWPamieci = -1
		RealTimeChart.ClearData
		RealTimeChart.AddLine("Temperatura [°C]", xui.Color_Red)
        
		Dim CalyTekstCSV As String = job.GetString
		Dim Linie() As String = Regex.Split(CRLF, CalyTekstCSV)
        
		' Poprawiona nazwa zmiennej (bez spacji!)
		Dim LicznikLinii As Int = 0
        
		For Each Linia As String In Linie
			If Linia.Trim <> "" Then
				LicznikLinii = LicznikLinii + 1
                
				If LicznikLinii Mod 1 = 0 Then
					Dim Czesci() As String = Regex.Split(",", Linia)
					If Czesci.Length = 2 Then
						Dim T As Double = Czesci(0)
						Dim C As Double = Czesci(1)
						DodajPunktDoPamieci(T, C, False)
					End If
				End If
			End If
		Next
        
		xui.MsgboxAsync("Pomyślnie zaimportowano " & ListaTemperatur.Size & " punktów z Raspberry Pi!", "Kopia pobrana")
	Else
		xui.MsgboxAsync("Błąd pobierania z serwera: " & job.ErrorMessage, "Błąd sieci")
	End If
	job.Release
End Sub


' ==============================================================
' FUNKCJA 2: ZAPISYWANIE DANYCH DO PLIKU .CSV W TELEFONIE
' ==============================================================
Public Sub ZapiszKopieWTelefonie As String
	Dim sb As StringBuilder
	sb.Initialize
    
	' Budujemy strukturę pliku CSV krok po kroku
	For i = 0 To ListaTemperatur.Size - 1
		sb.Append(ListaTemperatur.Get(i)).Append(",").Append(ListaCzasow.Get(i)).Append(CRLF)
	Next
    
	' Poprawione pobieranie Daty i Czasu w B4A!
	Dim ZnacznikCzasu As String = DateTime.Date(DateTime.Now) & "_" & DateTime.Time(DateTime.Now)
	ZnacznikCzasu = ZnacznikCzasu.Replace("/", "-").Replace(":", "-")
    
	Dim NazwaPliku As String = "Raport_Termometr_" & ZnacznikCzasu & ".csv"
    
	File.WriteString(File.DirInternal, NazwaPliku, sb.ToString)
    
	Log("Zapisano kopię bezpieczeństwa w telefonie: " & NazwaPliku)
	Return NazwaPliku
End Sub

' ==============================================================
' FUNKCJA 3: OBSŁUGA PRZEJŚCIA DO TABELI I EKSPORTU
' ==============================================================
Private Sub btnPokazTabele_Click
	If ListaTemperatur.Size > 0 Then
        
		' 1. Wykonujemy twardy zapis do pamięci flash telefonu (plik CSV)
		Dim NazwaZapisanegoPliku As String = ZapiszKopieWTelefonie
        
		' 2. Pobieramy referencję do głównego ekranu
		Dim MainScreen As B4XMainPage = B4XPages.MainPage
        
		' 3. Przekazujemy listy do nowej strony Tabeli Termometru.
		' Korzystamy z nowej metody WczytajDane, która wymaga tylko 2 parametrów:
		MainScreen.EkranTabeliTermometru.WczytajDane(ListaCzasow, ListaTemperatur)
        
		' 4. Robimy zrzut ekranu (Snapshot) naszego wykresu temperatury
		Dim SnapshotTermometru As B4XBitmap = RealTimeChart.mBase.Snapshot
        
		' 5. Przekazujemy obraz do tabeli (uwaga: nowa metoda nazywa się PokazWykres - liczba pojedyncza!)
		MainScreen.EkranTabeliTermometru.PokazWykres(SnapshotTermometru)
        
		' 6. Informujemy użytkownika i przełączamy ekran na NOWĄ stronę
		xui.MsgboxAsync("Dane zostały zabezpieczone w pliku: " & NazwaZapisanegoPliku, "Eksport udany")
		B4XPages.ShowPage("StronaTabelaTermometr")
	Else
		xui.MsgboxAsync("Brak danych! Poczekaj na pomiary lub pobierz historię z Raspberry Pi.", "Pusto")
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
		ListaTemperatur.Clear
		ListaCzasow.Clear
		NajnowszyCzasWPamieci = -1
		RealTimeChart.ClearData
		RealTimeChart.AddLine("Temperatura [°C]", xui.Color_Red)
		RealTimeChart.DrawChart
        
		xui.MsgboxAsync("Pamięć wyczyszczona! Włóż czujnik do cieczy. Od teraz Malinka zapisuje nowy, czysty wykres.", "Gotowe")
	End If
End Sub



Public Sub PobierzHistorieZMalinki
	Log("Pobieranie pełnej historii stygnięcia z miniserwera...")
    
	Dim job As HttpJob
	job.Initialize("", Me)
	job.Download("http://192.168.42.1:8080/stygniecie_cieczy.csv")
    
	Wait For (job) JobDone(job As HttpJob)
    
	If job.Success Then
		ListaTemperatur.Clear
		ListaCzasow.Clear
		NajnowszyCzasWPamieci = -1
		RealTimeChart.ClearData
		RealTimeChart.AddLine("Temperatura [°C]", xui.Color_Red)
        
		Dim CalyTekstCSV As String = job.GetString
		Dim Linie() As String = Regex.Split(CRLF, CalyTekstCSV)
		Dim LicznikLinii As Int = 0
        
		For Each Linia As String In Linie
			If Linia.Trim <> "" Then
				LicznikLinii = LicznikLinii + 1
				If LicznikLinii Mod 1 = 0 Then
					Dim Czesci() As String = Regex.Split(",", Linia)
					If Czesci.Length = 2 Then
						Dim T As Double = Czesci(0)
						Dim C As Double = Czesci(1)
						' Ładujemy w tle (False - nie rysuj jeszcze!)
						DodajPunktDoPamieci(T, C, False)
					End If
				End If
			End If
		Next
        
		' !!! Rysujemy cały wykres RAZ, po załadowaniu wszystkich punktów !!!
'		RealTimeChart.DrawChart
		PrzeliczIRysujWykres
		Log("Pomyślnie wczytano historię: " & ListaTemperatur.Size & " punktów.")
	Else
		' Wypisujemy twardy błąd, żeby wiedzieć, co blokuje pobieranie!
		Log("BŁĄD POBIERANIA: " & job.ErrorMessage)
	End If
	job.Release
End Sub


Private Sub B4XPage_Appear
	' Sprawdzamy, czy historia nie była już wcześniej załadowana
	If HistoriaPobrana = False Then
		Log("Strona się pojawiła! Automatyczne ładowanie historii...")
        
		' Zaznaczamy flagę, żeby nie ładował ponownie, gdy zrzucisz aplikację w tło
		HistoriaPobrana = True
        
		' Odpalamy pobieranie z Malinki
		PobierzHistorieZMalinki
	End If
End Sub




Private Sub btnWlacz_Click
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		' Wysyłamy komendę START do NodeMCU
		MainScreen.mqtt.Publish("lab/temperatura/sterowanie", "START".GetBytes("UTF8"))
		Log("Wysłano komendę START")
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