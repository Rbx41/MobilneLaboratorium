B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	Private CzujnikKompasu As PhoneSensors
    
	' --- ZMIENNE WIZUALNE ---
	Private imgKompas As B4XView
	Private lblStopnie As Label
	Private lblKierunek As Label
	
	Private AktualnaRotacja As Float = 0
	Private Const WspolczynnikFiltracji As Float = 0.15 ' Wartość od 0.0 do 1.0
	
End Sub

Public Sub Initialize As Object
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("LayoutKompasu")
    
	B4XPages.SetTitle(Me, "Kompas Magnetyczny")
    
	' Inicjalizujemy czujnik orientacji przestrzennej
	CzujnikKompasu.Initialize(CzujnikKompasu.TYPE_ORIENTATION)
	imgKompas.SetBitmap(xui.LoadBitmap(File.DirAssets, "compass-rose.png"))
	
End Sub

Private Sub B4XPage_Appear
	' Startujemy nasłuch, gdy strona jest na ekranie (szybkość 3 = standardowa, dobra dla baterii)
	CzujnikKompasu.StartListening("Kompas")
End Sub

Private Sub B4XPage_Disappear
	' Wyłączamy sprzętowy czujnik, żeby oszczędzać baterię
	CzujnikKompasu.StopListening
End Sub
'
'' ==========================================
''  SERCE KOMPASU
'' ==========================================
'Private Sub Kompas_SensorChanged (Values() As Float)
'	If imgKompas.IsInitialized Then
'		' Odczytujemy Azymut z czujnika (Values(0) to odchylenie od północy)
'		Dim Azymut As Float = Values(0)
'        
'		' 1. OBRÓT GRAFIKI
'		' Dajemy minus (-), ponieważ tarcza musi obracać się w kierunku przeciwnym
'		' do ruchu telefonu, aby północ "stała w miejscu"
'		imgKompas.Rotation = -Azymut
'        
'		' 2. WYŚWIETLANIE STOPNI (Zaokrąglamy do pełnych liczb)
'		lblStopnie.Text = NumberFormat(Azymut, 1, 0) & "°"
'        
'		' 3. WYŚWIETLANIE KIERUNKU ŚWIATA (Przekazujemy azymut do naszej funkcji)
'		lblKierunek.Text = WyznaczKierunek(Azymut)
'	End If
'End Sub

Private Sub WyznaczKierunek(Katy As Float) As String
	' Dzielimy róże wiatrów na 8 równych kawałków (po 45 stopni każdy)
	If Katy >= 337.5 Or Katy < 22.5 Then
		Return "N (Północ)"
	Else If Katy >= 22.5 And Katy < 67.5 Then
		Return "NE (Północny Wschód)"
	Else If Katy >= 67.5 And Katy < 112.5 Then
		Return "E (Wschód)"
	Else If Katy >= 112.5 And Katy < 157.5 Then
		Return "SE (Południowy Wschód)"
	Else If Katy >= 157.5 And Katy < 202.5 Then
		Return "S (Południe)"
	Else If Katy >= 202.5 And Katy < 247.5 Then
		Return "SW (Południowy Zachód)"
	Else If Katy >= 247.5 And Katy < 292.5 Then
		Return "W (Zachód)"
	Else If Katy >= 292.5 And Katy < 337.5 Then
		Return "NW (Północny Zachód)"
	Else
		Return "Błąd odczytu"
	End If
End Sub

Private Sub Kompas_SensorChanged (Values() As Float)
    If imgKompas.IsInitialized Then
        ' 1. Odczytujemy DOCELOWY Azymut z czujnika
        Dim DocelowyAzymut As Float = Values(0)
        
        ' 2. MATEMATYKA FILTRU (Shortest Path Interpolation)
        Dim Roznica As Float = DocelowyAzymut - AktualnaRotacja
        
        ' Naprawa "Pułapki 360 stopni" (Szukamy najkrótszej drogi)
        ' Zamiast kręcić się o 358 stopni w tył, każemy mu przeskoczyć o 2 stopnie w przód.
        If Roznica > 180 Then Roznica = Roznica - 360
        If Roznica < -180 Then Roznica = Roznica + 360
        
        ' Zastosowanie filtru dolnoprzepustowego (Płynne doganianie celu)
        AktualnaRotacja = AktualnaRotacja + (Roznica * WspolczynnikFiltracji)
        
        ' Utrzymanie matematyki w ryzach 0-360
        If AktualnaRotacja < 0 Then AktualnaRotacja = AktualnaRotacja + 360
        If AktualnaRotacja >= 360 Then AktualnaRotacja = AktualnaRotacja - 360
        
        ' 3. OBRÓT GRAFIKI
        ' Dajemy minus (-), ponieważ tarcza obraca się w kierunku przeciwnym
        imgKompas.Rotation = -AktualnaRotacja
        
        ' 4. WYŚWIETLANIE TEKSTÓW (Używamy przefiltrowanej wartości, żeby tekst też nie skakał)
        lblStopnie.Text = NumberFormat(AktualnaRotacja, 1, 0) & "°"
        lblKierunek.Text = WyznaczKierunek(AktualnaRotacja)
    End If
End Sub

