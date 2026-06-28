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
	Private btnNowyPomiar As Button
	Private btnWlacz As Button
	Private btnWylacz As Button
    
	Private NajnowszyCzasWPamieci As Double = -1
	Private CzyStronaZbudowana As Boolean = False
    
	' Zmienne do przechowywania historii (współdzielone z tabelą)
	Public ListaCzasow As List
	Public ListaTemperatur As List
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
	Log("Strona Termometru gotowa do odbioru przez Bluetooth!")
End Sub

' ==============================================================
' ODBIÓR DANYCH Z BLUETOOTH (Na żywo z NodeMCU)
' ==============================================================
' Tę metodę będziesz wywoływać z B4XMainPage, gdy przyjdzie nowa linijka tekstu
Public Sub OdbierzDaneBluetooth (LiniaDanych As String)
	If CzyStronaZbudowana = False Then Return
    
	Log("Odebrane dane z bluetooth")
	' Spodziewamy się formatu np.: "24.50,15.234"
	Dim podzieloneDane() As String = Regex.Split(",", LiniaDanych)
    
	If podzieloneDane.Length = 2 Then
		Dim WartoscTemperatury As Double = podzieloneDane(0)
		Dim CzasSekundy As Double = podzieloneDane(1)
        
		DodajPunktDoPamieci(WartoscTemperatury, CzasSekundy, True)
	End If
End Sub

Private Sub DodajPunktDoPamieci(Temp As Double, Czas As Double, RysujWykres As Boolean)
	' ZABEZPIECZENIE przed dublowaniem
	If Czas <= NajnowszyCzasWPamieci And ListaCzasow.Size > 0 Then Return
    
	NajnowszyCzasWPamieci = Czas
	ListaTemperatur.Add(Temp)
	ListaCzasow.Add(Czas)
    
	' Auto-skalowanie osi Y
	If Temp >= RealTimeChart.YMaxValue - 1 Then RealTimeChart.YMaxValue = Temp + 5
	If Temp <= RealTimeChart.YMinValue + 1 Then RealTimeChart.YMinValue = Temp - 5
    
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
    
	Dim MaxPunktowWizualnych As Int = 100
	Dim LiczbaPodzialek As Int = 10
    
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
		Dim PokazPodpis As Boolean = False
        
		If LicznikNarysowanych Mod PunktyNaJednaPodzialke = 0 Then
			EtykietaOsiX = NumberFormat(CzasWzgledny, 1, 0) & "s"
			PokazPodpis = True
		End If
        
		RealTimeChart.AddLineMultiplePoints(EtykietaOsiX, Array As Double(Temp), PokazPodpis)
		LicznikNarysowanych = LicznikNarysowanych + 1
	Next
    
	RealTimeChart.DrawChart
End Sub

' ==============================================================
' STEROWANIE MODUŁEM (WYSYŁANIE KOMEND DO NodeMCU)
' ==============================================================
Private Sub btnWlacz_Click
	WyslijKomendeDoModulu("START")
	xui.MsgboxAsync("Wysłano żądanie rozpoczęcia pomiarów.", "Status")
End Sub

Private Sub btnWylacz_Click
	WyslijKomendeDoModulu("STOP")
	xui.MsgboxAsync("Wysłano żądanie zatrzymania pomiarów.", "Status")
End Sub

Private Sub btnNowyPomiar_Click
	xui.Msgbox2Async("Czy na pewno chcesz usunąć obecny wykres i zacząć nagrywać od nowa?", "Nowy eksperyment", "Tak, start", "", "Anuluj", Null)
	Wait For Msgbox_Result (Result As Int)
    
	If Result = xui.DialogResponse_Positive Then
		' Zatrzymujemy stary strumień
		WyslijKomendeDoModulu("STOP")
        
		' Czyścimy pamięć w telefonie
		ListaTemperatur.Clear
		ListaCzasow.Clear
		NajnowszyCzasWPamieci = -1
		RealTimeChart.ClearData
		RealTimeChart.AddLine("Temperatura [°C]", xui.Color_Red)
		RealTimeChart.DrawChart
        
		xui.MsgboxAsync("Wykres wyczyszczony. Pamiętaj, aby kliknąć 'Włącz', gdy będziesz gotowy rozpocząć nowy eksperyment.", "Gotowe")
	End If
End Sub

' Funkcja pomocnicza komunikująca się z główną stroną aplikacji
Private Sub WyslijKomendeDoModulu(Komenda As String)
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	' Zakładamy, że na stronie głównej masz metodę do wysyłania tekstu przez BT
	MainScreen.WyslijTekstBluetooth(Komenda)
	Log("Wysłano komendę BT: " & Komenda)
End Sub

' ==============================================================
' ZAPIS I EKSPORT (Pozostaje bez zmian)
' ==============================================================
Public Sub ZapiszKopieWTelefonie As String
	Dim sb As StringBuilder
	sb.Initialize
    
	For i = 0 To ListaTemperatur.Size - 1
		sb.Append(ListaTemperatur.Get(i)).Append(",").Append(ListaCzasow.Get(i)).Append(CRLF)
	Next
    
	Dim ZnacznikCzasu As String = DateTime.Date(DateTime.Now) & "_" & DateTime.Time(DateTime.Now)
	ZnacznikCzasu = ZnacznikCzasu.Replace("/", "-").Replace(":", "-")
    
	Dim NazwaPliku As String = "Raport_Termometr_" & ZnacznikCzasu & ".csv"
	File.WriteString(File.DirInternal, NazwaPliku, sb.ToString)
    
	Log("Zapisano kopię bezpieczeństwa w telefonie: " & NazwaPliku)
	Return NazwaPliku
End Sub

Private Sub btnPokazTabele_Click
	If ListaTemperatur.Size > 0 Then
		Dim NazwaZapisanegoPliku As String = ZapiszKopieWTelefonie
		Dim MainScreen As B4XMainPage = B4XPages.MainPage
        
		MainScreen.EkranTabeliTermometru.WczytajDane(ListaCzasow, ListaTemperatur)
		Dim SnapshotTermometru As B4XBitmap = RealTimeChart.mBase.Snapshot
		MainScreen.EkranTabeliTermometru.PokazWykres(SnapshotTermometru)
        
		xui.MsgboxAsync("Dane zostały zabezpieczone w pliku: " & NazwaZapisanegoPliku, "Eksport udany")
		B4XPages.ShowPage("StronaTabelaTermometr")
	Else
		xui.MsgboxAsync("Brak danych! Włącz pomiary, aby rozpocząć zbieranie danych.", "Pusto")
	End If
End Sub