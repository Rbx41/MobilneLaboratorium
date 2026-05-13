B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	' ZMIENNE EKRANU PRZEWIJANEGO
	Private EkranPrzewijany As ScrollView
    
	' NASZE DWIE OSOBNE TABELE
	Private TabelaLadowanie As B4XTable
	Private TabelaRozladowanie As B4XTable
    
	' SCHOWKI NA DANE
	Private mCzasL, mNapiecieL, mCzasR, mNapiecieR As List
	
	' Zmienna dla naszego przycisku przenoszącego do układu RC
	Private PobierzBtn As Button
End Sub

Public Sub Initialize As Object
	mCzasL.Initialize
	mNapiecieL.Initialize
	mCzasR.Initialize
	mNapiecieR.Initialize
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	EkranPrzewijany.Initialize(1400dip)
	Root.AddView(EkranPrzewijany, 0, 0, 100%x, 100%y)
    
	EkranPrzewijany.Panel.LoadLayout("TabelaLayout")
	B4XPages.SetTitle(Me, "Raport Pomiarowy RC")
    
	' --- CZCIONKA WNĘTRZA TABELI 1 ---
	TabelaLadowanie.AddColumn("Nr", TabelaLadowanie.COLUMN_TYPE_NUMBERS)
	TabelaLadowanie.AddColumn("Czas [s]", TabelaLadowanie.COLUMN_TYPE_TEXT)
	TabelaLadowanie.AddColumn("Napięcie [V]", TabelaLadowanie.COLUMN_TYPE_TEXT)
	TabelaLadowanie.LabelsFont = xui.CreateFont(Typeface.LoadFromAssets("lmroman10-bold.otf"), 14) ' <--- To zmienia czcionkę wierszy
	TabelaLadowanie.TextColor = xui.Color_Black
    
	' --- CZCIONKA WNĘTRZA TABELI 2 ---
	TabelaRozladowanie.AddColumn("Nr", TabelaRozladowanie.COLUMN_TYPE_NUMBERS)
	TabelaRozladowanie.AddColumn("Czas [s]", TabelaRozladowanie.COLUMN_TYPE_TEXT)
	TabelaRozladowanie.AddColumn("Napięcie [V]", TabelaRozladowanie.COLUMN_TYPE_TEXT)
	TabelaRozladowanie.LabelsFont = xui.CreateFont(Typeface.LoadFromAssets("lmroman10-bold.otf"), 14) ' <--- To zmienia czcionkę wierszy
	TabelaRozladowanie.TextColor = xui.Color_Black
    
	' --- ZMIANA CZCIONKI DLA ZWYKŁYCH ETYKIET (TYTUŁÓW) ---
	UstawWlasnaCzcionke(EkranPrzewijany.Panel, "lmroman10-bold.otf")
    
	' Ekran załadowany!
	WczytajDane(mCzasL, mNapiecieL, mCzasR, mNapiecieR)
End Sub


Public Sub WczytajDane(CzasL As List, NapiecieL As List, CzasR As List, NapiecieR As List)
	' Aktualizujemy schowek
	mCzasL = CzasL
	mNapiecieL = NapiecieL
	mCzasR = CzasR
	mNapiecieR = NapiecieR
    
	' Zabezpieczenie: czy tabele już fizycznie istnieją
	If TabelaLadowanie.IsInitialized = False Then Return
    
	' --- PAKOWANIE DANYCH DO TABELI 1: ŁADOWANIE ---
	Dim DaneLadowania As List
	DaneLadowania.Initialize
	For i = 0 To CzasL.Size - 1
		DaneLadowania.Add(Array As Object(i + 1, NumberFormat(CzasL.Get(i), 1, 2), NumberFormat(NapiecieL.Get(i), 1, 3)))
	Next
	TabelaLadowanie.SetData(DaneLadowania)
    
	' --- PAKOWANIE DANYCH DO TABELI 2: ROZŁADOWANIE ---
	Dim DaneRozladowania As List
	DaneRozladowania.Initialize
	For i = 0 To CzasR.Size - 1
		DaneRozladowania.Add(Array As Object(i + 1, NumberFormat(CzasR.Get(i), 1, 2), NumberFormat(NapiecieR.Get(i), 1, 3)))
	Next
	TabelaRozladowanie.SetData(DaneRozladowania)
End Sub

Private Sub PobierzBtn_Click
	' 1. Inicjalizacja budowniczego tekstu
	Dim CSV As StringBuilder
	CSV.Initialize
    
	' 2. Nagłówki oddzielone PRZECINKIEM (standard międzynarodowy)
	CSV.Append("Czas Ladowania [s],Napiecie Ladowania [V],Czas Rozladowania [s],Napiecie Rozladowania [V]").Append(CRLF)
    
	' 3. SZUKAMY ABSOLUTNIE NAJDŁUŻSZEJ LISTY
	Dim MaxRows As Int = Max(Max(mCzasL.Size, mNapiecieL.Size), Max(mCzasR.Size, mNapiecieR.Size))
    
	' 4. Pętla przez wszystkie pomiary
	For i = 0 To MaxRows - 1
		Dim cL As String = ""
		Dim nL As String = ""
		Dim cR As String = ""
		Dim nR As String = ""
        
		' 5. POBIERANIE DANYCH
		' Usunąłem ".Replace", zostawiamy amerykańskie kropki dziesiętne, które Google Sheets uwielbia!
		If i < mCzasL.Size Then cL = NumberFormat(mCzasL.Get(i), 1, 3)
		If i < mNapiecieL.Size Then nL = NumberFormat(mNapiecieL.Get(i), 1, 3)
		If i < mCzasR.Size Then cR = NumberFormat(mCzasR.Get(i), 1, 3)
		If i < mNapiecieR.Size Then nR = NumberFormat(mNapiecieR.Get(i), 1, 3)
        
		' Sklejamy wiersz używając PRZECINKÓW zamiast średników
		CSV.Append(cL).Append(",").Append(nL).Append(",").Append(cR).Append(",").Append(nR).Append(CRLF)
	Next
    
	' 6. Zapis
	Dim NazwaPliku As String = "Pomiary_Laboratorium_RC.csv"
	Dim Sciezka As String = File.Combine(File.DirRootExternal, "Download")
    
	Try
		File.WriteString(Sciezka, NazwaPliku, CSV.ToString)
		xui.MsgboxAsync("Plik CSV został zapisany w folderze Pobrane (Downloads) jako:" & CRLF & NazwaPliku, "Sukces")
	Catch
		xui.MsgboxAsync("Nie udało się zapisać pliku. Sprawdź, czy aplikacja ma uprawnienia.", "Błąd zapisu")
		Log(LastException)
	End Try
End Sub





' ==========================================
'  ZMIANA CZCIONKI DLA ETYKIET NA EKRANIE
' ==========================================
Private Sub UstawWlasnaCzcionke(PanelGlowny As B4XView, NazwaPliku As String)
	Dim NowaCzcionka As Typeface = Typeface.LoadFromAssets(NazwaPliku)
	For Each v As B4XView In PanelGlowny.GetAllViewsRecursive
		If v Is Label Then
			v.Font = xui.CreateFont(NowaCzcionka, v.TextSize)
		End If
	Next
End Sub