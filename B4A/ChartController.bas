B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@





Sub Class_Globals
	Private xui As XUI
    
	Private Wykres As xChart
	Private Licznik As Int
	

	Private TytulWykresu As String
	
	Private WartosciCzasu As List
	Private Krzywe As List
	Private LiczbaKrzywych As Double
	
	Private XMinValue As Double
	Private XMaxValue As Double
	
	Private YMinValue As Double
	Private YMaxValue As Double
	
	Public CzestPodzialki As Int = 60
	Public CzestPunkt As Int = 4
	Public CzestRys As Int = 16

	
End Sub



Public Sub Initialize (TytulWykresu_ As String ,WykresZWidoku As xChart)
	TytulWykresu = TytulWykresu_ 
	Wykres = WykresZWidoku
	LiczbaKrzywych = 0
	Wykres.Title = TytulWykresu_
	Krzywe.Initialize	
End Sub





Public Sub DodajKrzywa(Etykieta_ As String ,Kolor_ As Int)
	LiczbaKrzywych = LiczbaKrzywych + 1
	Dim Krzywa As Krzywa
	Krzywa.Initialize(Etykieta_ ,Kolor_ , LiczbaKrzywych)
	Krzywe.Add(Krzywa)
	Wykres.AddLine(Etykieta_, Kolor_)
End Sub



Public Sub UstawPrzedzialOsiX(XMin_ As Double, XMax_ As Double)
	Wykres.XMinValue = XMin_
	Wykres.XMaxValue = XMax_
End Sub


Public Sub UstawPrzedzialOsiY(YMin_ As Double, YMax_ As Double)
	Wykres.YMinValue = YMin_
	Wykres.YMaxValue = YMax_
End Sub

Public Sub UstawNazwyOsi(OsX As String, OsY As String)
	Wykres.XAxisName = OsX
	Wykres.YAxisName = OsY
End Sub

Public Sub UstawAutoSkalowanie(Wartosc As Boolean)
	Wykres.AutomaticScale = Wartosc
End Sub

Public Sub UstawPodTytul(Podtytul As String)
	Wykres.Subtitle = Podtytul
End Sub

' Wartośći w liscie muszą byc ustawione w parach (x1,y1) , (x2,y2)
Public Sub DodajPunkty(Czas As Double, Punkty() As Double )
	If Punkty.Length > LiczbaKrzywych Then
		Log("Liczba punktów nie jest parzysta")
		Return
	End If
	
	Licznik  = Licznik + 1
    
	
	If Licznik Mod CzestPunkt= 0 Or Licznik = 1 Then
		Dim pokazPodzialke As Boolean = (Licznik Mod CzestPodzialki = 0 Or Licznik = 1)
		Dim CzasSformatowany As String = NumberFormat(Czas , 1, 1)
		
		Wykres.AddLineMultiplePoints(CzasSformatowany, Punkty, pokazPodzialke)
	End If
	 
	If Licznik Mod CzestRys = 0 Then
		Wykres.DrawChart
	End If

	
End Sub


' 2. RESET I USTAWIENIA 
Public Sub ResetujWykres
	Wykres.ClearData
	Licznik = 0

	
	For i = 0 To LiczbaKrzywych - 1 Step 1
		Dim Krzywa_ As Krzywa = Krzywe.Get(i)
		Wykres.AddLine(Krzywa_.Etykieta, Krzywa_.Kolor)

	Next

End Sub





Public Sub DodajPunktMonitor(WartoscEksperyment As Double, CzasZMikrokontrolera As Double)
	Dim CzasWzgledny As Double
    
	If Licznik > 150 Then
		ResetujWykres
	End If
    
	Licznik = Licznik + 1
    
	Dim pokazPodzialke As Boolean = (Licznik Mod 30 = 0 Or Licznik = 1)
	Dim CzasSformatowany As String = NumberFormat(CzasWzgledny, 1, 1)
    
	Wykres.AddLineMultiplePoints(CzasSformatowany, Array As Double(WartoscEksperyment, WartoscEksperyment), pokazPodzialke)
    
	If Licznik Mod 3 = 0 Then
		Wykres.DrawChart
	End If
End Sub




