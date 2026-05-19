B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
    
	' EKRAN
	Private EkranPrzewijany As ScrollView
    
	' TABELA TEMPERATURY
	Private TabelaTemperatury As B4XTable
    
	' SCHOWKI NA DANE
	Private mListaCzasow As List
	Private mListaTemperatur As List
    
	' PRZYCISKI I WIDOKI
	Private PobierzBtn As Button
	Private ImgWykres As B4XView ' Jeden wykres dla temperatury
End Sub

Public Sub Initialize As Object
	mListaCzasow.Initialize
	mListaTemperatur.Initialize
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	EkranPrzewijany.Initialize(1000dip) ' Wysokość dopasuj do layoutu
	Root.AddView(EkranPrzewijany, 0, 0, 100%x, 100%y)
    
	EkranPrzewijany.Panel.LoadLayout("TabelaTermoLayout")
	B4XPages.SetTitle(Me, "Raport Temperatury")
    
	' --- CZCIONKA WNĘTRZA TABELI ---
	TabelaTemperatury.AddColumn("Nr", TabelaTemperatury.COLUMN_TYPE_NUMBERS)
	TabelaTemperatury.AddColumn("Czas [s]", TabelaTemperatury.COLUMN_TYPE_TEXT)
	TabelaTemperatury.AddColumn("Temp [°C]", TabelaTemperatury.COLUMN_TYPE_TEXT)
	TabelaTemperatury.LabelsFont = xui.CreateFont(Typeface.LoadFromAssets("lmroman10-bold.otf"), 14)
	TabelaTemperatury.TextColor = xui.Color_Black
    
	' --- CZCIONKA DLA TYTUŁÓW ---
	UstawWlasnaCzcionke(EkranPrzewijany.Panel, "lmroman10-bold.otf")
End Sub

' Metoda wywoływana z głównej strony do przesłania danych
Public Sub WczytajDane(ListaCzasow As List, ListaTemperatur As List)
	mListaCzasow = ListaCzasow
	mListaTemperatur = ListaTemperatur
    
	If TabelaTemperatury.IsInitialized = False Then Return
    
	' --- PAKOWANIE DANYCH DO TABELI ---
	Dim DaneTabeli As List
	DaneTabeli.Initialize
	For i = 0 To mListaCzasow.Size - 1
		DaneTabeli.Add(Array As Object(i + 1, _
            NumberFormat(mListaCzasow.Get(i), 1, 2), _
            NumberFormat(mListaTemperatur.Get(i), 1, 2)))
	Next
	TabelaTemperatury.SetData(DaneTabeli)
End Sub

' Eksport do CSV (uproszczony dla temperatury)
Private Sub PobierzBtn_Click
	Dim CSV As StringBuilder
	CSV.Initialize
    
	' Nagłówki
	CSV.Append("Czas [s],Temperatura [°C]").Append(CRLF)
    
	' Wiersze danych
	For i = 0 To mListaCzasow.Size - 1
		Dim czas As String = NumberFormat(mListaCzasow.Get(i), 1, 2)
		Dim temp As String = NumberFormat(mListaTemperatur.Get(i), 1, 2)
		CSV.Append(czas).Append(",").Append(temp).Append(CRLF)
	Next
    
	' Zapis
	Dim NazwaPliku As String = "Pomiar_Temperatury_" & DateTime.Now & ".csv"
	Dim Sciezka As String = File.Combine(File.DirRootExternal, "Download")
    
	Try
		File.WriteString(Sciezka, NazwaPliku, CSV.ToString)
		xui.MsgboxAsync("Zapisano w folderze Pobrane jako:" & CRLF & NazwaPliku, "Sukces")
	Catch
		xui.MsgboxAsync("Błąd zapisu pliku: " & LastException, "Błąd")
	End Try
End Sub

' Wyświetlenie zrzutu wykresu
Public Sub PokazWykres(ObrazWykresu As B4XBitmap)
	If ImgWykres.IsInitialized Then
		ImgWykres.SetBitmap(ObrazWykresu)
	End If
End Sub

' --- NARZĘDZIA ---
Private Sub UstawWlasnaCzcionke(PanelGlowny As B4XView, NazwaPliku As String)
	Dim NowaCzcionka As Typeface = Typeface.LoadFromAssets(NazwaPliku)
	For Each v As B4XView In PanelGlowny.GetAllViewsRecursive
		If v Is Label Then
			v.Font = xui.CreateFont(NowaCzcionka, v.TextSize)
		End If
	Next
End Sub