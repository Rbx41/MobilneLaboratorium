B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@




Sub Class_Globals
	Private xui As XUI
    
	Private mChart As xChart
	Private mCounter As Int
	Private mCzasZerowy As Double
    
	
	Private mTypWykresu As String
	Private mVmin As Double
	Private mVmax As Double
	Public mTauTeoretyczne As Double
    
	Public PomiaryWartosci As List
	Public PomiaryCzasu As List
End Sub

' 1. INICJALIZACJA 
Public Sub Initialize (WykresZWidoku As xChart, TypWykresu As String, OczekiwaneVmin As Double, OczekiwaneVmax As Double, TeoretyczneTau As Double)
	mChart = WykresZWidoku
	mTypWykresu = TypWykresu
	mVmin = OczekiwaneVmin
	mVmax = OczekiwaneVmax
	mTauTeoretyczne = TeoretyczneTau
    
	PomiaryWartosci.Initialize
	PomiaryCzasu.Initialize
	ResetujWykres
End Sub

' 2. RESET I USTAWIENIA 
Public Sub ResetujWykres
	mChart.ClearData
	mCounter = 0
	PomiaryWartosci.Clear
	PomiaryCzasu.Clear
    
	' !!! DODAJEMY DWIE LINIE DO WYKRESU !!!
	mChart.AddLine("Krzywa Teoretyczna", xui.Color_Yellow)
	mChart.AddLine("Krzywa Rzeczywista", xui.Color_Red)
	
	mChart.Title = mTypWykresu
	mChart.SubTitle = "Czerwona: Pomiar | Żółta: Teoria"
    
	mChart.AutomaticScale = False
	mChart.YMinValue = 0
	mChart.YMaxValue = 5.5
	mChart.XAxisName = "Czas [s]"
	mChart.YAxisName = "Napięcie [V]"
End Sub



' 3. DODAWANIE DANYCH 
Public Sub DodajPunkt(WartoscEksperyment As Double, CzasZMikrokontrolera As Double)
	Dim CzasWzgledny As Double
    
	If mCounter = 0 Then
		mCzasZerowy = CzasZMikrokontrolera
		CzasWzgledny = 0
	Else
		CzasWzgledny = CzasZMikrokontrolera - mCzasZerowy
	End If
    
	mCounter = mCounter + 1
    
	
	PomiaryWartosci.Add(WartoscEksperyment)
	PomiaryCzasu.Add(CzasWzgledny)
    
	' ========================================================
	' 2.  (Ochrona telefonu przed zacięciem)
	' ========================================================
  
	If mCounter Mod 4 = 0 Or mCounter = 1 Then
        
		' --- OBLICZANIE WYNIKU TEORETYCZNEGO (Tylko dla rysowanych punktów) ---
		Dim Amplituda As Double = mVmax - mVmin
		Dim WartoscTeoretyczna As Double
		Dim PotegaE As Double = Power(cE, -CzasWzgledny / mTauTeoretyczne)
		Dim Vin As Double = 3.33
        
		If mTypWykresu = "ŁADOWANIE" Then
			WartoscTeoretyczna = Vin + (mVmin - Vin) * PotegaE
		Else If mTypWykresu = "ROZŁADOWANIE" Then
			WartoscTeoretyczna = mVmax * PotegaE
		End If
		' ----------------------------------------------------------------------
        
	
		Dim pokazPodzialke As Boolean = (mCounter Mod 60 = 0 Or mCounter = 1)
		Dim CzasSformatowany As String = NumberFormat(CzasWzgledny, 1, 1)
        
		mChart.AddLineMultiplePoints(CzasSformatowany, Array As Double(WartoscTeoretyczna, WartoscEksperyment), pokazPodzialke)
	End If
 
 
	If mCounter Mod 16 = 0 Then
		mChart.DrawChart
	End If
    
End Sub



Public Sub DodajPunktMonitor(WartoscEksperyment As Double, CzasZMikrokontrolera As Double)
	Dim CzasWzgledny As Double
    
	' Efekt oscyloskopu: gdy dojdzie do 150 punktów, czyści brudnopis i rysuje od nowa
	If mCounter > 150 Then
		ResetujWykres
	End If
    
	If mCounter = 0 Then
		mCzasZerowy = CzasZMikrokontrolera
		CzasWzgledny = 0
	Else
		CzasWzgledny = CzasZMikrokontrolera - mCzasZerowy
	End If
    
	mCounter = mCounter + 1
    
	Dim pokazPodzialke As Boolean = (mCounter Mod 30 = 0 Or mCounter = 1)
	Dim CzasSformatowany As String = NumberFormat(CzasWzgledny, 1, 1)
    

	mChart.AddLineMultiplePoints(CzasSformatowany, Array As Double(WartoscEksperyment, WartoscEksperyment), pokazPodzialke)
	
	If mCounter Mod 3 = 0 Then
		mChart.DrawChart
	End If
End Sub

