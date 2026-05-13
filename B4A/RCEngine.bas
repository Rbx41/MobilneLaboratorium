B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=13.4
@EndOfDesignText@
' Definiujemy zdarzenia, które klasa może wysłać na zewnątrz
#Event: TauWynik (TypOperacji As String, CzasTau As Double)
#Event: ProgOsiagniety (JakiProg As String)

Sub Class_Globals
	' Zmienne do komunikacji z układem wizualnym (StronaRC)
	Private mCallback As Object
	Private mEventName As String
    
	' Parametry fizyczne
	Private Vmax As Double
	Private Vmin As Double
    
	' Zmienne stoperów (dawniej w StronaRC)
	Private StartLadowaniaZlapany As Boolean = False
	Private StartRozladowaniaZlapany As Boolean = False
	Private CzasStartuLadowania As Double
	Private CzasStartuRozladowania As Double
	Private TauLadowaniaObliczone As Boolean = False
	Private TauRozladowaniaObliczone As Boolean = False
	
	
	

End Sub

' Inicjalizacja z podaniem kto nas słucha i jakie są progi napięć
Public Sub Initialize (Callback As Object, EventName As String, OczekiwaneVmin As Double, OczekiwaneVmax As Double)
	mCallback = Callback
	mEventName = EventName
	Vmin = OczekiwaneVmin
	Vmax = OczekiwaneVmax
End Sub

' Reset przed każdym nowym kliknięciem START
Public Sub ResetujStopery
	StartLadowaniaZlapany = False
	StartRozladowaniaZlapany = False
	TauLadowaniaObliczone = False
	TauRozladowaniaObliczone = False
End Sub






Public Sub PrzetworzLadowanie(WartoscAnalogowa As Double, CzasZMikrokontrolera As Double)
	If StartLadowaniaZlapany = False And WartoscAnalogowa >= Vmin Then
		CzasStartuLadowania = CzasZMikrokontrolera
		StartLadowaniaZlapany = True
	End If
    
	Dim Amplituda As Double = Vmax - Vmin
	Dim progTau As Double = Vmin + (Amplituda * 0.632)
    
	' Jeśli policzyliśmy Tau, WYCHODZIMY Z WYNIKIEM NA ZEWNĄTRZ
	If StartLadowaniaZlapany = True And WartoscAnalogowa >= progTau And TauLadowaniaObliczone = False Then
		Dim CzasTau As Double = CzasZMikrokontrolera - CzasStartuLadowania
		TauLadowaniaObliczone = True
        
		' Wywołujemy funkcję w StronaRC
		If SubExists(mCallback, mEventName & "_TauWynik") Then
			CallSub3(mCallback, mEventName & "_TauWynik", "ŁADOWANIE", CzasTau)
		End If
	End If
    
	' Jeśli osiągnięto sufit napięcia
	If WartoscAnalogowa >= Vmax Then
		If SubExists(mCallback, mEventName & "_ProgOsiagniety") Then
			CallSub2(mCallback, mEventName & "_ProgOsiagniety", "VMAX")
		End If
	End If
End Sub


Public Sub PrzetworzRozladowanie(WartoscAnalogowa As Double, CzasZMikrokontrolera As Double)
	If StartRozladowaniaZlapany = False And WartoscAnalogowa <= Vmax Then
		CzasStartuRozladowania = CzasZMikrokontrolera
		StartRozladowaniaZlapany = True
	End If
    
	Dim Amplituda As Double = Vmax - Vmin
	Dim progTau As Double = Vmin + (Amplituda * 0.368)
    
	If StartRozladowaniaZlapany = True And WartoscAnalogowa <= progTau And TauRozladowaniaObliczone = False Then
		Dim CzasTau As Double = CzasZMikrokontrolera - CzasStartuRozladowania
		TauRozladowaniaObliczone = True
        
		' Wywołujemy funkcję w StronaRC
		If SubExists(mCallback, mEventName & "_TauWynik") Then
			CallSub3(mCallback, mEventName & "_TauWynik", "ROZŁADOWANIE", CzasTau)
		End If
	End If
    
	If WartoscAnalogowa <= Vmin Then
		If SubExists(mCallback, mEventName & "_ProgOsiagniety") Then
			CallSub2(mCallback, mEventName & "_ProgOsiagniety", "VMIN")
		End If
	End If
End Sub


