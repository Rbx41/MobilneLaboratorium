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
	imgKompas.SetBitmap(xui.LoadBitmap(File.DirAssets, "compass_img2.png"))
	
End Sub

Private Sub B4XPage_Appear
	' Startujemy nasłuch, gdy strona jest na ekranie (szybkość 3 = standardowa, dobra dla baterii)
	CzujnikKompasu.StartListening("Kompas")
End Sub

Private Sub B4XPage_Disappear
	' Wyłączamy sprzętowy czujnik, żeby oszczędzać baterię
	CzujnikKompasu.StopListening
End Sub

' ==========================================
'  SERCE KOMPASU
' ==========================================
Private Sub Kompas_SensorChanged (Values() As Float)
	If imgKompas.IsInitialized Then
		' Odczytujemy Azymut z czujnika (Values(0) to odchylenie od północy)
		Dim Azymut As Float = Values(0)
        
		' 1. OBRÓT GRAFIKI
		' Dajemy minus (-), ponieważ tarcza musi obracać się w kierunku przeciwnym
		' do ruchu telefonu, aby północ "stała w miejscu"
		imgKompas.Rotation = -Azymut
        
		' 2. WYŚWIETLANIE STOPNI (Zaokrąglamy do pełnych liczb)
		lblStopnie.Text = NumberFormat(Azymut, 1, 0) & "°"
        
		' 3. WYŚWIETLANIE KIERUNKU ŚWIATA (Przekazujemy azymut do naszej funkcji)
		lblKierunek.Text = WyznaczKierunek(Azymut)
	End If
End Sub

' ==========================================
'  FUNKCJA MATEMATYCZNA: Zmiana stopni na tekst
' ==========================================
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