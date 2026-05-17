B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI

	Private btnOff As Button
	Private btnOn As Button
	Private RealTimeChart As xChart
	Private RealTimeChart2 As xChart
	Private btnStart As Button

	Private const TOPIC_RELAY As String = "lab/rc/relay"
    
	' --- Deklaracja obiektów odpowiadających za kontrole wykresu ---
	Private WykresLadowania As ChartController
	Private WykresRozladowania As ChartController
    
	' --- STANY ---
	Private Const Charging As Int  = 1
	Private Const Discharging As Int  = 2
	Private Const Idle As Int = 3
	Private Const Finished As Int = 4 ' <--- PRZYWRÓCONY STAN ZAKOŃCZENIA
	Private State As Int
    
	Private EkranPrzewijany As ScrollView
	Private RInput As EditText
	Private CInput As EditText
	Private CzyStronaZbudowana As Boolean = False
	Private ProbInput As EditText
    
	Private LabelRCLadowanie As Label
	Private LabelRCRozladowanie As Label
	Private btnPokazTabele As Button
	Private VmaxInput As EditText
	Private VminInput As EditText
    
	Private OstatnieNapiecie As Double = 0
	Private Const Vstart As Double = 0.09
	Private Const VmaxRange As Double = 3.25
	Private Const VminRange As Double = 0.06
	Private Const RCMax As Double = 50.0
	Private Const RCMin As Double = 5.0
    
	Private Const ProbMax As Double = 800.0
	Private Const ProbMin As Double = 60.0
    
	Private Vmax As Double
	Private Vmin As Double
End Sub

Public Sub Initialize As Object
	State = Idle
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
    
	EkranPrzewijany.Initialize(1200dip)
	Root.AddView(EkranPrzewijany, 0, 0, 100%x, 100%y)

	EkranPrzewijany.Panel.LoadLayout("MainRC")
    
	B4XPages.SetTitle(Me, "Eksperyment Układu RC")
	Log("Moduł RC uruchomiony...")

	WykresLadowania.Initialize(RealTimeChart, "ŁADOWANIE", 0.10, 3.26, 6.6)
	WykresRozladowania.Initialize(RealTimeChart2, "ROZŁADOWANIE", 0.10, 3.26, 6.6)
    
	CzyStronaZbudowana = True
	UstawWlasnaCzcionke(EkranPrzewijany.Panel, "lmroman10-bold.otf")
End Sub

Public Sub OdbierzDaneZSieci (Topic As String, Payload() As Byte)
	If CzyStronaZbudowana = False Then Return
	Dim msg As String = BytesToString(Payload, 0, Payload.Length, "UTF8")
    
	' 1. ODBIÓR DANYCH DO WYKRESU
	If Topic = "lab/rc/voltage" Then
		Dim podzieloneDane() As String = Regex.Split(",", msg)
		If podzieloneDane.Length = 2 Then
			Dim WartoscAnalogowa As Double = podzieloneDane(0)
			Dim CzasZMikrokontrolera As Double = podzieloneDane(1)
            
			Select State
				Case Charging
					WykresLadowania.DodajPunkt(WartoscAnalogowa, CzasZMikrokontrolera)
				Case Discharging
					WykresRozladowania.DodajPunkt(WartoscAnalogowa, CzasZMikrokontrolera)
				Case Idle
					WykresLadowania.DodajPunktMonitor(WartoscAnalogowa, CzasZMikrokontrolera)
					WykresRozladowania.DodajPunktMonitor(WartoscAnalogowa, CzasZMikrokontrolera)
                    
					' Zapisujemy napięcie do pamięci globalnej
					OstatnieNapiecie = WartoscAnalogowa
                    
					Dim AktualneVmin As Double = 0.1
					If IsNumber(VminInput.Text) Then AktualneVmin = VminInput.Text
                    
					' Przycisk JEST ZAWSZE AKTYWNY, żeby nie blokować użytkownika
					btnStart.Enabled = True
                    
					If WartoscAnalogowa <= (AktualneVmin + 0.05) Then
						btnStart.Text = "START"
					Else
						' Układ utknął na wyższym napięciu - proponujemy start z tego miejsca
						btnStart.Text = "START (" & NumberFormat(WartoscAnalogowa, 1, 2) & "V)"
					End If
                    
				Case Finished ' <--- LOGIKA ZAMROŻENIA WYKRESU
					' Wykres zamarza (nie rysujemy po nim), ale odświeżamy pamięć napięcia
					OstatnieNapiecie = WartoscAnalogowa
			End Select
		End If
        
		' 2. ODBIÓR GOTOWEGO WYNIKU TAU
	Else If Topic = "lab/rc/tau" Then
		Dim podzieloneTau() As String = Regex.Split(",", msg)
		If podzieloneTau.Length = 2 Then
			Dim Tryb As String = podzieloneTau(0)
			Dim CzasTau As Double = podzieloneTau(1)
            
			Dim WynikText As String = "Stała RC z Edge: " & NumberFormat(CzasTau, 1, 3) & " s"
            
			If Tryb = "LADOWANIE" Then
				Log("Edge Tau (Ladowanie): " & NumberFormat(CzasTau, 1, 3) & " s")
				LabelRCLadowanie.Text = WynikText
                
			Else If Tryb = "ROZLADOWANIE" Then
				Log("Edge Tau (Rozladowanie): " & NumberFormat(CzasTau, 1, 3) & " s")
				LabelRCRozladowanie.Text = WynikText
			End If
		End If
        
		' 3. ODBIÓR ZDARZEŃ (Sufit / Podłoga)
	Else If Topic = "lab/rc/event" Then
		If msg = "VMAX" Then
			SwitchOffRelay
			State = Discharging
		Else If msg = "VMIN" Then
			State = Finished ' <--- PRZEJŚCIE DO NOWEGO STANU
			ZablokujInterfejs(False)
			btnPokazTabele.Enabled = True
			Log("Koniec pomiaru. Układ gotowy do nowej próby.")
            
			btnStart.Text = "PONÓW EKSPERYMENT"
			btnStart.Enabled = True
		End If
	End If
End Sub

Private Sub btnStart_Click
    
	If  ZatwierdzProgiNapiecia(VminInput.Text, VmaxInput.Text) = False Then
		Return
	End If
        
	Vmin = VminInput.Text
	Vmax = VmaxInput.Text
    
	' === TUTAJ BRAKOWAŁO AUTOKOREKTY (KROK 3) ===
	' Jeśli sprzęt utknął wyżej niż założyliśmy (z marginesem 0.05V)
	If OstatnieNapiecie > (Vmin + 0.05) Then
		Vmin = OstatnieNapiecie ' Akceptujemy fizyczną rzeczywistość
		VminInput.Text = NumberFormat(Vmin, 1, 2) ' Podmieniamy tekst w polu na ekranie
		xui.MsgboxAsync("Układ nie mógł osiągnąć wpisanego Vmin. Zaktualizowano dolny próg do fizycznie możliwego: " & NumberFormat(Vmin, 1, 2) & "V", "Autokorekta")
	End If
    
	If ZatwierdzRC(RInput.Text, CInput.Text) = False Then
		Return
	End If

	Dim WpisaneR As Double = RInput.Text
	Dim WpisaneC As Double = CInput.Text
	Dim WpisaneTau As Double = (WpisaneR * WpisaneC) / 1000.0
    
	If ZatwierdzProbkowanie(ProbInput.Text) = False Then
		Return
	End If
    
	Dim Prob As String = ProbInput.Text
    
	btnPokazTabele.Enabled = False
	btnStart.Enabled = False
	btnStart.Text = "POMIAR..."
	ZablokujInterfejs(True)
    
	LabelRCLadowanie.Text = "Stała RC wyznaczona doświadczalnie: ---"
	LabelRCRozladowanie.Text = "Stała RC wyznaczona doświadczalnie: ---"
    
	WykresLadowania.mTauTeoretyczne = WpisaneTau
	WykresRozladowania.mTauTeoretyczne = WpisaneTau
    
	WykresLadowania.ResetujWykres
	WykresRozladowania.ResetujWykres
    
	State = Charging ' <--- Ustawienie stanu na Ładowanie resetuje stan Finished
    
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		MainScreen.mqtt.Publish("lab/rc/vmin", NumberFormat(Vmin, 1, 2).GetBytes("UTF8"))
		MainScreen.mqtt.Publish("lab/rc/vmax", NumberFormat(Vmax, 1, 2).GetBytes("UTF8"))
		MainScreen.mqtt.Publish("lab/rc/interval", Prob.GetBytes("UTF8"))
        
		MainScreen.mqtt.Publish(TOPIC_RELAY, "1".GetBytes("UTF8"))
		Log("Wysłano: ŁADOWANIE (ON) - Pomiary Edge w toku...")
	End If
End Sub

Private Sub ZatwierdzRC(RInput_ As String, CInput_ As String)
	If IsNumber(RInput_) = False Or RInput_.Trim = "" Then
		xui.MsgboxAsync("Wprowadź poprawną wartość liczbową rezystancji w kiloOhmach!", "Błąd wejścia")
		Return False
	End If
    
	If IsNumber(CInput_) = False Or CInput_.Trim = "" Then
		xui.MsgboxAsync("Wprowadź poprawną wartość liczbową pojemności w mikroFaradach!", "Błąd wejścia")
		Return False
	End If
    
	Dim R As Double = RInput_
	Dim C As Double = CInput_
	Dim WpisaneTau As Double = (R * C) / 1000.0
    
	If WpisaneTau < RCMin Or WpisaneTau > RCMax Then
		xui.MsgboxAsync("Obliczona stała czasowa RC wynosi " & NumberFormat(WpisaneTau, 1, 2) & " s." & CRLF & _
        "Wartość ta musi mieścić się w przedziale od 5 do 30 sekund!" & CRLF & _
        "Dobierz inne wartości rezystora i kondensatora.", "Nieprawidłowa stała RC")
		Return False
	End If
    
	Return True
End Sub

Private Sub ZatwierdzProgiNapiecia(VminInput_ As String, VmaxInput_ As String)
	If IsNumber(VminInput_) = False Or VminInput_.Trim = "" Then
		xui.MsgboxAsync("Wprowadzona wartość nie jest liczbą", "Błąd wejścia")
		Return False
	End If
    
	If IsNumber(VmaxInput_) = False Or VmaxInput_.Trim = "" Then
		xui.MsgboxAsync("Wprowadzona wartość nie jest liczbą", "Błąd wejścia")
		Return False
	End If
    
	Dim Vmin_ As Double = VminInput_
	Dim Vmax_ As Double = VmaxInput_
    
	If Vmin_ < VminRange Or Vmin_ > VmaxRange Then
		xui.MsgboxAsync("Niewłaściwy zakres dla Vmin. Najmniejszy dozwolony zakres Vmin "& VminRange, "Błąd wejścia")
		Return False
	End If
    
	If Vmax_ < VminRange Or Vmax_ > VmaxRange Then
		xui.MsgboxAsync("Niewłaściwy zakres dla Vmax. Największy dozwolony zakres Vmax "& VmaxRange, "Błąd wejścia")
		Return False
	End If
    
	If Vmax_ < Vmin_ Then
		xui.MsgboxAsync("Wartość Vmin nie może przekraczać Vmax", "Błąd wejścia")
		Return False
	End If
    
	Return True
End Sub

Private Sub ZatwierdzProbkowanie(ProbInput_ As String) As Boolean
	If IsNumber(ProbInput_) = False Or ProbInput_.Trim = "" Then
		xui.MsgboxAsync("Wprowadź poprawną liczbę milisekund!", "Błąd formatu")
		Return False
	End If
    
	Dim Wartosc As Int = ProbInput_
    
	' Sprawdzanie zakresu
	If Wartosc < ProbMin Or Wartosc > ProbMax Then
		xui.MsgboxAsync("Okres próbkowania musi mieścić się w zakresie od " & ProbMin &" do "& ProbMax  &" ms!", "Niepoprawny zakres")
		Return False ' ZWRACAMY FAŁSZ - zatrzymaj wszystko!
	End If
    
	Return True
End Sub

Private Sub btnOn_Click
	SwitchOnRelay
End Sub

Private Sub btnOff_Click
	SwitchOffRelay
End Sub

Private Sub SwitchOffRelay
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		MainScreen.mqtt.Publish(TOPIC_RELAY, "0".GetBytes("UTF8"))
		Log("Wysłano: ROZŁADOWANIE (OFF)")
	End If
End Sub

Private Sub SwitchOnRelay
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.mqtt.Connected Then
		MainScreen.mqtt.Publish(TOPIC_RELAY, "1".GetBytes("UTF8"))
		Log("Wysłano: ŁADOWANIE (ON)")
	End If
End Sub

Private Sub ZablokujInterfejs (Zablokowane As Boolean)
	btnOn.Enabled = Not(Zablokowane)
	btnOff.Enabled = Not(Zablokowane)
    
	RInput.Enabled = Not(Zablokowane)
	CInput.Enabled = Not(Zablokowane)
	ProbInput.Enabled = Not(Zablokowane)
	VminInput.Enabled = Not(Zablokowane)
	VmaxInput.Enabled = Not(Zablokowane)
End Sub

Private Sub UstawWlasnaCzcionke(PanelGlowny As B4XView, NazwaPliku As String)
	Dim NowaCzcionka As Typeface = Typeface.LoadFromAssets(NazwaPliku)
    
	For Each v As B4XView In PanelGlowny.GetAllViewsRecursive
		If v Is Label Or v Is Button Or v Is EditText Then
			v.Font = xui.CreateFont(NowaCzcionka, v.TextSize)
		End If
	Next
End Sub

Private Sub btnPokazTabele_Click
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
        
	If WykresLadowania.PomiaryCzasu.Size > 0 Then
		' 1. Wysłanie danych liczbowych
		MainScreen.EkranTabeli.WczytajDane(WykresLadowania.PomiaryCzasu, WykresLadowania.PomiaryWartosci, WykresRozladowania.PomiaryCzasu, WykresRozladowania.PomiaryWartosci)
        
		' 2. ZROBIENIE "ZDJĘCIA" WYKRESOM (Snapshot)
		Dim SnapshotLadowania As B4XBitmap = RealTimeChart.mBase.Snapshot
		Dim SnapshotRozladowania As B4XBitmap = RealTimeChart2.mBase.Snapshot
        
		' 3. Przekazanie obrazków do nowej strony
		MainScreen.EkranTabeli.PokazWykresy(SnapshotLadowania, SnapshotRozladowania)
        
		' 4. Pokazanie strony podsumowania
		B4XPages.ShowPage("StronaTabela")
	Else
		xui.MsgboxAsync("Brak danych do wyświetlenia!", "Błąd")
	End If
End Sub