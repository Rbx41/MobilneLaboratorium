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
	Private WykresTemperatur As ChartController
	Private btnPokazTabele As Button
	Private btnNowyPomiar As Button
	Private btnWlacz As Button
	Private btnWylacz As Button
    
	Private NajnowszyCzasWPamieci As Double = -1
	Private CzyStronaZbudowana As Boolean = False
    
	' Zmienne do przechowywania historii (współdzielone z tabelą)
'	Public ListaCzasow As List
'	Public ListaTemperatur As List
	
	Public CzasWzgledny As Double
	Public PierwszyPomiar As Boolean
	Public CzasZerowy As Double
End Sub

Public Sub Initialize As Object
	CzasZerowy = 0
	PierwszyPomiar = True
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("Temp")
	B4XPages.SetTitle(Me, "Pomiary Temperatury")
	SkonfigurujWykresy    
	CzyStronaZbudowana = True
End Sub




Public Sub SkonfigurujWykresy()
	WykresTemperatur.Initialize ("Pomiar stygniecia cieczy",  RealTimeChart)
	WykresTemperatur.DodajKrzywa("Krzywa stygniecia", xui.Color_Red)
	WykresTemperatur.UstawPrzedzialOsiY(10,45.0)
	WykresTemperatur.UstawNazwyOsi("Czas [s]", "°C")
	WykresTemperatur.UstawAutoSkalowanie(False)
	WykresTemperatur.CzestRys = 1
	WykresTemperatur.CzestPunkt = 1
End Sub


Public Sub OdbierzDaneBluetooth (LiniaDanych As String)
	If CzyStronaZbudowana = False Then Return
	Dim podzieloneDane() As String = Regex.Split(",", LiniaDanych)
	Dim Temperatura As Double = podzieloneDane(0)
	Dim CzasSekundy As Double = podzieloneDane(1)
	ObliczCzasWzgledny(CzasSekundy)
	Dim Tablica() As Double = Array As Double(Temperatura)
	WykresTemperatur.DodajPunkty(CzasWzgledny, Tablica)
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	MainScreen.EkranTabeliTermometru.DodajDane(CzasWzgledny, Temperatura )
End Sub


Public Sub ObliczCzasWzgledny(CzasZMikrokontrolera_ As Double)
	If PierwszyPomiar = True Then
		CzasZerowy = CzasZMikrokontrolera_
		PierwszyPomiar = False
		CzasWzgledny = 0
	Else
		CzasWzgledny = CzasZMikrokontrolera_ - CzasZerowy
	End If
End Sub



Private Sub btnNowyPomiar_Click
	xui.Msgbox2Async("Czy na pewno chcesz usunąć obecny wykres i zacząć nagrywać od nowa?", "Nowy eksperyment", "Tak, start", "", "Anuluj", Null)
	Wait For Msgbox_Result (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		WyslijKomendeDoModulu("STOP")
		WykresTemperatur.ResetujWykres
		PierwszyPomiar = True
		xui.MsgboxAsync("Wykres wyczyszczony. Pamiętaj, aby kliknąć 'Włącz', gdy będziesz gotowy rozpocząć nowy eksperyment.", "Gotowe")
	End If
End Sub

Private Sub btnWlacz_Click
	WyslijKomendeDoModulu("START")
	xui.MsgboxAsync("Wysłano żądanie rozpoczęcia pomiarów.", "Status")
End Sub
Private Sub btnWylacz_Click
	WyslijKomendeDoModulu("STOP")
	xui.MsgboxAsync("Wysłano żądanie zatrzymania pomiarów.", "Status")
End Sub



Private Sub btnPokazTabele_Click
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	If MainScreen.EkranTabeliTermometru.DanePelne = True Then
		Dim SnapshotTermometru As B4XBitmap = RealTimeChart.mBase.Snapshot
		MainScreen.EkranTabeliTermometru.ZapiszWykres(SnapshotTermometru)
		B4XPages.ShowPage("StronaTabelaTermometr")
	Else
		xui.MsgboxAsync("Brak danych! Włącz pomiary, aby rozpocząć zbieranie danych.", "Pusto")
	End If
End Sub





Private Sub WyslijKomendeDoModulu(Komenda As String)
	Dim MainScreen As B4XMainPage = B4XPages.MainPage
	' Zakładamy, że na stronie głównej masz metodę do wysyłania tekstu przez BT
	MainScreen.WyslijTekstBluetooth(Komenda)
	Log("Wysłano komendę BT: " & Komenda)
End Sub

