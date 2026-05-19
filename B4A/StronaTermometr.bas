B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	' Elementy z Visual Designera (ze zrzutu ekranu)
	Private RealTimeChart As xChart
	Private btnPokazTabele As Button
    
	' Zmienna bezpieczeństwa
	Private CzyStronaZbudowana As Boolean = False
    
	' Zmienne do przechowywania historii (przydatne do tabeli)
	Private ListaCzasow As List
	Private ListaTemperatur As List
End Sub

Public Sub Initialize As Object
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
    
	' PAMIĘTAJ: Zmień nazwę w cudzysłowie, jeśli zapisałeś ten layout pod inną nazwą!
	Root.LoadLayout("Temp")
	B4XPages.SetTitle(Me, "Pomiary Temperatury")
    
	' Inicjalizacja list do zapisywania danych w tle
	ListaCzasow.Initialize
	ListaTemperatur.Initialize
    
	' --- KONFIGURACJA WYKRESU ---
	RealTimeChart.ClearData
	RealTimeChart.AddLine("Temperatura [°C]", xui.Color_Red)
    
	' Wstępne ramy wykresu (zmienią się dynamicznie)
	RealTimeChart.AutomaticScale = False ' Musimy wyłączyć automat wbudowany, by nasz działał
	RealTimeChart.YMinValue = 15.0
	RealTimeChart.YMaxValue = 35.0
    
	RealTimeChart.XAxisName = "Czas [s]"
	RealTimeChart.YAxisName = "°C"
	RealTimeChart.DrawChart
    
	CzyStronaZbudowana = True
	Log("Strona Termometru gotowa!")
End Sub

' ==============================================================
' ODBIÓR DANYCH Z MQTT (Przekazane przez B4XMainPage)
' ==============================================================
Public Sub OdbierzDaneZSieci (Topic As String, Payload() As Byte)
	If CzyStronaZbudowana = False Then Return
    
	Dim msg As String = BytesToString(Payload, 0, Payload.Length, "UTF8")
    
	Log("Wiadomosc ")
	' Upewniamy się, że to nasz temat
	If Topic = "lab/temperatura" Then
		Log("Wiadomosc temperatura")
        
		' Spodziewamy się formatu np: "24.50,15.200"
		Dim podzieloneDane() As String = Regex.Split(",", msg)
        
		If podzieloneDane.Length = 2 Then
			Dim WartoscTemperatury As Double = podzieloneDane(0)
			Dim CzasSekundy As Double = podzieloneDane(1)
            
			' Zapisujemy dane do pamięci (żeby móc je potem wyświetlić w Tabeli)
			ListaTemperatur.Add(WartoscTemperatury)
			ListaCzasow.Add(CzasSekundy)
            
			' --- AUTO-SKALOWANIE OSI Y ---
			' Jeśli temperatura rośnie poza skalę, podnosimy sufit
			If WartoscTemperatury >= RealTimeChart.YMaxValue - 1 Then
				RealTimeChart.YMaxValue = WartoscTemperatury + 5
			End If
            
			' Jeśli temperatura spada poza skalę, obniżamy podłogę
			If WartoscTemperatury <= RealTimeChart.YMinValue + 1 Then
				RealTimeChart.YMinValue= WartoscTemperatury - 5
			End If
            
			' --- RYSOWANIE NA WYKRESIE ---
			' Jako tekst osi X podajemy czas zaokrąglony do 1 miejsca po przecinku
			Dim CzasOsX As String = NumberFormat(CzasSekundy, 1, 1)
            
			' Dodajemy nowy punkt i odświeżamy wykres
			RealTimeChart.AddLineMultiplePoints(CzasOsX, Array As Double(WartoscTemperatury), False)
			RealTimeChart.DrawChart
            
		End If
	End If
End Sub

' ==============================================================
' OBSŁUGA PRZYCISKÓW
' ==============================================================
Private Sub btnPokazTabele_Click
	' Ten kod możesz później rozbudować analogicznie do układu RC,
	' aby przesyłał zapisane Listy (ListaCzasow i ListaTemperatur)
	' do Twojego ekranu StronaTabela.
    
	If ListaTemperatur.Size > 0 Then
		xui.MsgboxAsync("Zebrano dotychczas " & ListaTemperatur.Size & " pomiarów temperatury.", "Informacja")
		' Tutaj wrzucisz kod przerzucający do tabeli!
	Else
		xui.MsgboxAsync("Brak danych! Poczekaj na pierwsze pomiary z czujnika.", "Pusto")
	End If
End Sub