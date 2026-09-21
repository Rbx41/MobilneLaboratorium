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
    
    
	Private NumerPomiaru As Double
	Private DanePomiarowe As List
	

	Private PobierzBtn As Button

	
	Private TymczasowyWykres As B4XBitmap
	Private ImgTemperatura As ImageView
End Sub

Public Sub Initialize As Object
	DanePomiarowe.Initialize
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
    
	UstawWlasnaCzcionke(EkranPrzewijany.Panel, "lmroman10-bold.otf")
	
	
	
	
End Sub


Private Sub B4XPage_Appear
	WczytajDane
	ImgTemperatura.Bitmap = TymczasowyWykres
	
End Sub

Public Sub ZapiszWykres(Wykres As B4XBitmap)
	
	TymczasowyWykres = Wykres
End Sub

' Metoda wywoływana z głównej strony do przesłania danych
Public Sub WczytajDane()

	TabelaTemperatury.SetData(DanePomiarowe)
End Sub


Public Sub DanePelne() As Boolean
	If DanePomiarowe.Size > 0 Then
		Return True
	End If
	
	Return False
End Sub

Public Sub DodajDane(Czas As Double, Temperatura As Double)
	 
	NumerPomiaru = NumerPomiaru + 1
	DanePomiarowe.Add(Array As Object(NumerPomiaru, NumberFormat(Czas, 1, 2), NumberFormat(Temperatura, 1, 3)))

End Sub

' Eksport do CSV (uproszczony dla temperatury)
Private Sub PobierzBtn_Click
	Dim CSV As StringBuilder
	CSV.Initialize
    
	
	CSV.Append("Czas [s],Temperatura [°C]").Append(CRLF)
	
	
    
'	' Wiersze danych
'	For i = 0 To mListaCzasow.Size - 1
'		Dim czas As String = NumberFormat(mListaCzasow.Get(i), 1, 2)
'		Dim temp As String = NumberFormat(mListaTemperatur.Get(i), 1, 2)
'		CSV.Append(czas).Append(",").Append(temp).Append(CRLF)
'	Next
    
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


' --- NARZĘDZIA ---
Private Sub UstawWlasnaCzcionke(PanelGlowny As B4XView, NazwaPliku As String)
	Dim NowaCzcionka As Typeface = Typeface.LoadFromAssets(NazwaPliku)
	For Each v As B4XView In PanelGlowny.GetAllViewsRecursive
		If v Is Label Then
			v.Font = xui.CreateFont(NowaCzcionka, v.TextSize)
		End If
	Next
End Sub