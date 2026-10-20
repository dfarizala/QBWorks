'==============================================================
' QBWORKS 3.0 - Clon de AppleWorks 3.0 escrito en QB64
'--------------------------------------------------------------
' Archivos del proyecto (deben estar en la MISMA carpeta):
'   QBWORKS.BAS  -> este archivo (menus y Escritorio). Compile este.
'   FILES.BM     -> lectura/escritura de archivos en disco
'   WP.BM        -> procesador de textos
'   SS.BM        -> hoja de calculo
'   DB.BM        -> base de datos
'   CLIP.BM      -> portapapeles comun entre los tres modulos
'   PRINT.BM     -> impresion
'   SPELL.BM     -> corrector ortografico
'   THEME.BM     -> aspecto de la pantalla (monitor verde o ambar)
'   GFX.BM       -> ventana grafica con aspecto de monitor Apple II
'   (opcional)   PrintChar21.ttf -> fuente tipo Apple II para la ventana grafica
'
' Notas:
'  - Texto sin tildes ni enie en los menus (el modo texto usa CP437).
'  - Todas las barras miden 79 columnas para evitar que la
'    pantalla se desplace al escribir en la ultima celda.
'  - Los archivos se guardan como NOMBRE.QBW en la carpeta actual.
'==============================================================
DefInt A-Z

Const APPNAME$ = "QBWORKS"
Const MAXDESK = 12
Const MAXLINES = 1500 ' lineas maximas por documento
Const WPMAXLEN = 76 ' margen derecho (largo maximo de linea)
Const WPROWS = 21 ' filas de texto visibles (filas 4 a 24)
Const MAXROWS = 500 ' filas de la hoja de calculo
Const MAXCOLS = 26 ' columnas de la hoja (A a Z)
Const SSROWS = 21 ' filas de hoja visibles (filas 4 a 24)
Const MAXREC = 500 ' registros por base de datos
Const MAXCAT = 12 ' categorias por base de datos
Const DBROWS = 21 ' registros visibles en la tabla (filas 4 a 24)
Const HSIZE = 262139 ' tamano de la tabla del diccionario

Type DeskFile
    Nombre As String * 30
    Tipo As Integer ' 1 = textos, 2 = hoja, 3 = base de datos
    Modificado As Integer ' -1 si tiene cambios sin guardar
    EnDisco As Integer ' -1 si ya existe en disco (cargado o guardado)
    Slot As Integer ' casilla de datos del documento
End Type

Dim Shared Desk(1 To MAXDESK) As DeskFile
Dim Shared DeskCount
Dim Shared MenuItem$(1 To 12)
Dim Shared MenuCount
Dim Shared Cancelled
Dim Shared ErrFlag
Dim Shared ThemeSel, FullOn, GfxMode, GfxOn, ScanOn, CursorWanted
Dim Shared GfxFW, GfxFH, GfxTW, GfxTH, GfxVS, GfxSc, GfxMargin
Dim Shared textScr As Long, winScr As Long, scanImg As Long, gfxFont As Long

' Datos de documentos (una casilla por archivo del Escritorio)
Dim Shared SlotUsed(1 To MAXDESK)
Dim Shared WPText$(1 To MAXDESK, 1 To MAXLINES)
Dim Shared WPLines(1 To MAXDESK)
Dim Shared WPCurL(1 To MAXDESK)
Dim Shared WPCurC(1 To MAXDESK)
Dim Shared WPTop(1 To MAXDESK)

' Portapapeles comun a todos los archivos
Dim Shared Clip$(1 To MAXLINES)
Dim Shared ClipCount

' Datos de hojas de calculo (una casilla por archivo del Escritorio)
Dim Shared SSRaw$(1 To MAXDESK, 1 To MAXROWS, 1 To MAXCOLS)
Dim Shared SSVal(1 To MAXDESK, 1 To MAXROWS, 1 To MAXCOLS) As Double
Dim Shared SSErr(1 To MAXDESK, 1 To MAXROWS, 1 To MAXCOLS)
Dim Shared SSState(1 To MAXDESK, 1 To MAXROWS, 1 To MAXCOLS)
Dim Shared SSCurR(1 To MAXDESK), SSCurC(1 To MAXDESK)
Dim Shared SSTopR(1 To MAXDESK), SSLeftC(1 To MAXDESK)
Dim Shared SSColW(1 To MAXDESK), SSDec(1 To MAXDESK)

' Portapapeles de la hoja y estado del editor de hojas
Dim Shared SSClip$(1 To MAXROWS, 1 To MAXCOLS)
Dim Shared SSClipRows, SSClipCols, SSClipR0, SSClipC0
Dim Shared sIdx, sSlot, sR, sC, sTopR, sLeftC, sAnchR, sAnchC

' Estado del evaluador de formulas y de la carga de archivos
Dim Shared fS$, fP, fErr, fSlot
Dim Shared LoadKind

' Datos de bases de datos (una casilla por archivo del Escritorio)
Dim Shared DBData$(1 To MAXDESK, 1 To MAXREC, 1 To MAXCAT)
Dim Shared DBCatName$(1 To MAXDESK, 1 To MAXCAT)
Dim Shared DBCatW(1 To MAXDESK, 1 To MAXCAT)
Dim Shared DBCatCount(1 To MAXDESK), DBRecCount(1 To MAXDESK)
Dim Shared DBView(1 To MAXREC), DBIdx(1 To MAXREC)
Dim Shared DBTmp$(1 To MAXREC, 1 To MAXCAT)

' Estado del editor de bases de datos y destino de los informes
Dim Shared dIdx, dSlot, dPos, dCat, dTop, dLeft, dMode, dViewN
Dim Shared dFOn, dFCat, dFOp, dFVal$
Dim Shared rDest, rSlot, rFF, rCount, rTrunc, rCut

' Portapapeles comun entre modulos (cuadricula de texto)
Dim Shared GClip$(1 To MAXLINES, 1 To MAXCOLS)
Dim Shared GKind, GRows, GCols
Dim Shared GLine$(1 To MAXLINES), GLn
Dim Shared SplitCell$(1 To MAXCOLS), SplitN

' Impresion: opciones y lineas por imprimir
Dim Shared PrtLeft, PrtLines, PrtHeader$, PrtNum
Dim Shared PLine$(1 To MAXLINES), PCount

' Corrector ortografico: diccionario (tabla hash) y sugerencias
Dim Shared SpHash$(0 To HSIZE - 1)
Dim Shared SpCount As Long
Dim Shared SpLoaded
Dim Shared SugList$(1 To 5), SugN

' Estado del editor de textos
Dim Shared eIdx, eSlot, eL, eC, eTop, eGoal, eIns, eMark
Dim Shared FoundL, FoundC
Dim Shared StatusMsg$, LastFind$, LastRepl$

' Lista de archivos en disco
Dim Shared FList$(1 To 100)

'--------------------------- PROGRAMA PRINCIPAL ---------------
LoadTheme
If GfxMode Then InitGfx
If GfxOn = 0 Then
    Screen 0
    Width 80, 25
End If
_Title "QBWorks 3.0"
Locate , , 0
CursorWanted = 0
CursorWanted = 0
ApplyTheme ThemeSel
DeskCount = 0
PrtLeft = 5
PrtLines = 60
PrtHeader$ = ""
PrtNum = -1
MainMenu
System

' Manejador de errores de archivo (nivel principal, como exige QB64).
' Solo esta activo mientras FILES.BM ejecuta ON ERROR GOTO FileErr.
FileErr:
ErrFlag = -1
Resume Next

'==============================================================
'  ENTRADA DE TECLADO
'==============================================================
Function GetKey$
    Dim k$
    Do
        If GfxOn Then
            GfxPresent
            _Limit 40
        Else
            _Limit 60
        End If
        k$ = InKey$
    Loop While k$ = ""
    GetKey$ = k$
End Function

'==============================================================
'  DIBUJO BASICO
'==============================================================
Sub PrintAt (r, c, t$, fg, bg)
    Color fg, bg
    Locate r, c
    Print t$;
    Color 7, 0
End Sub

Sub TitleBar (t$)
    Dim l$, d$, p
    CursorWanted = 0
    l$ = " " + APPNAME$ + "  -  " + t$
    d$ = Date$ + " "
    p = 79 - Len(l$) - Len(d$)
    If p < 0 Then p = 0
    Color 0, 7
    Locate 1, 1
    Print Left$(l$ + Space$(p) + d$, 79);
    Color 7, 0
End Sub

Sub HelpBar (t$)
    Color 0, 7
    Locate 25, 1
    Print Left$(" " + t$ + Space$(79), 79);
    Color 7, 0
End Sub

Sub Box (r1, c1, r2, c2)
    Dim r
    If GfxOn Then
        GfxBox r1, c1, r2, c2
        Exit Sub
    End If
    Locate r1, c1
    Print Chr$(218); String$(c2 - c1 - 1, 196); Chr$(191);
    For r = r1 + 1 To r2 - 1
        Locate r, c1
        Print Chr$(179); Space$(c2 - c1 - 1); Chr$(179);
    Next
    Locate r2, c1
    Print Chr$(192); String$(c2 - c1 - 1, 196); Chr$(217);
End Sub

' Mensaje centrado; espera una tecla
Sub Msg (t$)
    Dim w, c, k$
    w = Len(t$)
    If w < 24 Then w = 24
    w = w + 4
    c = (79 - w) \ 2 + 1
    Locate , , 0
    CursorWanted = 0
    Color 14, 0
    Box 9, c, 14, c + w - 1
    Color 15, 0
    Locate 11, c + 2
    Print t$;
    Color 7, 0
    Locate 13, c + 2
    Print "[Presione una tecla]";
    k$ = GetKey$
End Sub

' Pregunta Si/No; devuelve -1 (si) o 0 (no)
Function Confirm (t$)
    Dim w, c, k$
    w = Len(t$)
    If w < 24 Then w = 24
    w = w + 4
    c = (79 - w) \ 2 + 1
    Locate , , 0
    CursorWanted = 0
    Color 14, 0
    Box 9, c, 14, c + w - 1
    Color 15, 0
    Locate 11, c + 2
    Print t$;
    Color 7, 0
    Locate 13, c + 2
    Print "[S] Si    [N] No";
    Do
        k$ = UCase$(GetKey$)
        If k$ = "S" Then
            Confirm = -1
            Exit Function
        End If
        If k$ = "N" Or k$ = Chr$(27) Then
            Confirm = 0
            Exit Function
        End If
    Loop
End Function

' Numero a texto sin espacio inicial
Function N2S$ (n)
    N2S$ = LTrim$(Str$(n))
End Function

'==============================================================
'  MENUS Y LINEA DE ENTRADA
'==============================================================
' Muestra MenuItem$(1..MenuCount) desde (rowT, colL).
' Devuelve el numero elegido, o 0 si se presiona Esc.
Function RunMenu (rowT, colL, startSel)
    Dim i, k$, w, cur
    cur = startSel
    w = 0
    For i = 1 To MenuCount
        If Len(MenuItem$(i)) > w Then w = Len(MenuItem$(i))
    Next
    Do
        For i = 1 To MenuCount
            Locate rowT + i - 1, colL
            If i = cur Then Color 0, 7 Else Color 7, 0
            Print " " + Left$(MenuItem$(i) + Space$(w), w) + " ";
        Next
        Color 7, 0
        k$ = GetKey$
        Select Case k$
            Case Chr$(0) + "H"
                cur = cur - 1
                If cur < 1 Then cur = MenuCount
            Case Chr$(0) + "P"
                cur = cur + 1
                If cur > MenuCount Then cur = 1
            Case Chr$(13)
                RunMenu = cur
                Exit Function
            Case Chr$(27)
                RunMenu = 0
                Exit Function
            Case "1" To "9"
                If Val(k$) <= MenuCount Then
                    RunMenu = Val(k$)
                    Exit Function
                End If
        End Select
    Loop
End Function

' Lee una linea de texto en (row, col). Si se presiona Esc,
' Cancelled = -1.
Function ReadLine$ (row, col, maxLen, initial$)
    Dim s$, k$
    s$ = initial$
    Cancelled = 0
    Do
        Color 0, 7
        Locate row, col
        Print s$ + Space$(maxLen - Len(s$));
        Color 7, 0
        Locate row, col + Len(s$), 1
        CursorWanted = -1
        k$ = GetKey$
        If k$ = Chr$(13) Then Exit Do
        If k$ = Chr$(27) Then
            Cancelled = -1
            Exit Do
        End If
        If k$ = Chr$(8) Then
            If Len(s$) > 0 Then s$ = Left$(s$, Len(s$) - 1)
        ElseIf Len(k$) = 1 Then
            If Asc(k$) >= 32 And Len(s$) < maxLen Then s$ = s$ + k$
        End If
    Loop
    Color 7, 0
    Locate , , 0
    CursorWanted = 0
    ReadLine$ = s$
End Function

'==============================================================
'  UTILIDADES DEL ESCRITORIO
'==============================================================
Function KindName$ (k)
    Select Case k
        Case 1: KindName$ = "Procesador de textos"
        Case 2: KindName$ = "Hoja de calculo"
        Case 3: KindName$ = "Base de datos"
        Case Else: KindName$ = "?"
    End Select
End Function

Function AnyModified
    Dim i
    AnyModified = 0
    For i = 1 To DeskCount
        If Desk(i).Modificado Then AnyModified = -1
    Next
End Function

Function NameExists (n$)
    Dim i
    NameExists = 0
    For i = 1 To DeskCount
        If UCase$(RTrim$(Desk(i).Nombre)) = UCase$(n$) Then NameExists = -1
    Next
End Function

Function BadName (n$)
    Dim i
    BadName = 0
    For i = 1 To Len(n$)
        If InStr("\/:*?<>|" + Chr$(34), Mid$(n$, i, 1)) > 0 Then BadName = -1
    Next
End Function

Function QuitOK
    If AnyModified Then
        QuitOK = Confirm("Hay archivos sin guardar. Salir de todos modos?")
    Else
        QuitOK = -1
    End If
End Function

' Reserva una casilla de datos libre (0 si no hay)
Function AllocSlot
    Dim i
    AllocSlot = 0
    For i = 1 To MAXDESK
        If SlotUsed(i) = 0 Then
            SlotUsed(i) = -1
            AllocSlot = i
            InitDoc i
            InitSheet i
            InitDB i
            Exit Function
        End If
    Next
End Function

Sub FreeSlot (s)
    If s >= 1 And s <= MAXDESK Then SlotUsed(s) = 0
End Sub

'==============================================================
'  PANTALLAS
'==============================================================
Sub MainMenu
    Dim sel, choice
    sel = 1
    Do
        Cls
        TitleBar "Menu principal"
        PrintAt 3, 3, "Que desea hacer?", 15, 0
        Box 4, 3, 12, 52
        MenuCount = 5
        MenuItem$(1) = "1. Agregar archivos al Escritorio"
        MenuItem$(2) = "2. Trabajar con un archivo del Escritorio"
        MenuItem$(3) = "3. Guardar archivos del Escritorio en disco"
        MenuItem$(4) = "4. Otras actividades"
        MenuItem$(5) = "5. Salir"
        PrintAt 14, 3, "Archivos en el Escritorio: " + N2S$(DeskCount) + " de " + N2S$(MAXDESK), 7, 0
        PrintAt 15, 3, "Carpeta actual: " + Left$(_CWD$, 60), 7, 0
        HelpBar "Flechas: mover   Enter: elegir   1-5: acceso directo   Esc: Escritorio"
        choice = RunMenu(6, 5, sel)
        If choice > 0 Then sel = choice
        Select Case choice
            Case 1: AddFilesMenu
            Case 2: DesktopScreen
            Case 3: SaveDesktop
            Case 4: OtherActivities
            Case 5
                If QuitOK Then Exit Sub
            Case 0
                If DeskCount > 0 Then DesktopScreen
        End Select
    Loop
End Sub

Sub AddFilesMenu
    Dim sel, choice
    sel = 1
    Do
        Cls
        TitleBar "Agregar archivos al Escritorio"
        PrintAt 3, 3, "Agregar archivos al Escritorio:", 15, 0
        MenuCount = 3
        MenuItem$(1) = "1. Crear un archivo nuevo"
        MenuItem$(2) = "2. Cargar un archivo del disco"
        MenuItem$(3) = "3. Volver al menu principal"
        HelpBar "Flechas: mover   Enter: elegir   Esc: volver"
        choice = RunMenu(5, 5, sel)
        If choice > 0 Then sel = choice
        Select Case choice
            Case 1: NewFileMenu
            Case 2: LoadFromDisk
            Case 0, 3: Exit Sub
        End Select
    Loop
End Sub

Sub NewFileMenu
    Dim choice, nm$, slot
    If DeskCount >= MAXDESK Then
        Msg "El Escritorio esta lleno (maximo 12 archivos)"
        Exit Sub
    End If
    Cls
    TitleBar "Crear un archivo nuevo"
    PrintAt 3, 3, "Crear un archivo nuevo para:", 15, 0
    MenuCount = 4
    MenuItem$(1) = "1. Procesador de textos"
    MenuItem$(2) = "2. Hoja de calculo"
    MenuItem$(3) = "3. Base de datos"
    MenuItem$(4) = "4. Cancelar"
    HelpBar "Flechas: mover   Enter: elegir   Esc: cancelar"
    choice = RunMenu(5, 5, 1)
    If choice = 0 Or choice = 4 Then Exit Sub

    PrintAt 11, 3, "Nombre del archivo (Esc cancela):", 7, 0
    nm$ = ReadLine$(12, 3, 30, "")
    If Cancelled Then Exit Sub
    nm$ = LTrim$(RTrim$(nm$))
    If nm$ = "" Then Exit Sub
    If BadName(nm$) Then
        Msg "El nombre tiene caracteres no permitidos"
        Exit Sub
    End If
    If NameExists(nm$) Then
        Msg "Ya hay un archivo con ese nombre en el Escritorio"
        Exit Sub
    End If
    slot = AllocSlot
    If slot = 0 Then
        Msg "No hay espacio en el Escritorio"
        Exit Sub
    End If

    DeskCount = DeskCount + 1
    Desk(DeskCount).Nombre = nm$
    Desk(DeskCount).Tipo = choice
    Desk(DeskCount).Modificado = 0
    Desk(DeskCount).EnDisco = 0
    Desk(DeskCount).Slot = slot
    OpenDeskFile DeskCount
End Sub

Sub DesktopScreen
    Dim sel, i, k$, mark$, ok
    If DeskCount = 0 Then
        Msg "El Escritorio esta vacio"
        Exit Sub
    End If
    sel = 1
    Do
        Cls
        TitleBar "Escritorio"
        PrintAt 3, 3, "Archivos en el Escritorio:", 15, 0
        PrintAt 5, 3, " No  " + Left$("Nombre" + Space$(30), 30) + "  " + Left$("Tipo" + Space$(20), 20) + "  M ", 14, 0
        For i = 1 To DeskCount
            If i = sel Then Color 0, 7 Else Color 7, 0
            mark$ = " "
            If Desk(i).Modificado Then mark$ = "*"
            Locate 6 + i, 3
            Print " " + Right$("  " + Str$(i), 2) + "  " + Desk(i).Nombre + "  " + Left$(KindName$(Desk(i).Tipo) + Space$(20), 20) + "  " + mark$ + " ";
        Next
        Color 7, 0
        PrintAt 20, 3, "* = tiene cambios sin guardar", 7, 0
        HelpBar "Enter: abrir   Supr/D: quitar del Escritorio   Esc: menu principal"
        k$ = GetKey$
        Select Case k$
            Case Chr$(0) + "H"
                sel = sel - 1
                If sel < 1 Then sel = DeskCount
            Case Chr$(0) + "P"
                sel = sel + 1
                If sel > DeskCount Then sel = 1
            Case Chr$(13)
                OpenDeskFile sel
            Case Chr$(0) + "S", "D", "d"
                ok = -1
                If Desk(sel).Modificado Then ok = Confirm("Tiene cambios sin guardar. Quitarlo igual?")
                If ok Then
                    FreeSlot Desk(sel).Slot
                    For i = sel To DeskCount - 1
                        Desk(i) = Desk(i + 1)
                    Next
                    DeskCount = DeskCount - 1
                    If DeskCount = 0 Then Exit Sub
                    If sel > DeskCount Then sel = DeskCount
                End If
            Case Chr$(27)
                Exit Sub
        End Select
    Loop
End Sub

' Abre el archivo del Escritorio en su modulo
Sub OpenDeskFile (i)
    Select Case Desk(i).Tipo
        Case 1: WPEdit i
        Case 2: SSEdit i
        Case 3: DBEdit i
        Case Else: ModuleStub i
    End Select
End Sub

' Pantalla provisional de los modulos aun no hechos (etapas 3 y 4)
Sub ModuleStub (i)
    Dim k$, st$
    Select Case Desk(i).Tipo
        Case 2: st$ = "Etapa 3"
        Case 3: st$ = "Etapa 4"
        Case Else: st$ = "una etapa posterior"
    End Select
    Do
        Cls
        TitleBar RTrim$(Desk(i).Nombre) + " (" + KindName$(Desk(i).Tipo) + ")"
        PrintAt 5, 5, "Archivo: " + RTrim$(Desk(i).Nombre), 15, 0
        PrintAt 6, 5, "Tipo:    " + KindName$(Desk(i).Tipo), 7, 0
        If Desk(i).Modificado Then
            PrintAt 7, 5, "Estado:  con cambios sin guardar", 7, 0
        Else
            PrintAt 7, 5, "Estado:  sin cambios", 7, 0
        End If
        PrintAt 10, 5, "Este modulo se implementa en la " + st$ + ".", 14, 0
        HelpBar "Esc: volver al Escritorio   M: marcar modificado (solo prueba)"
        k$ = UCase$(GetKey$)
        If k$ = Chr$(27) Then Exit Sub
        If k$ = "M" Then Desk(i).Modificado = Not Desk(i).Modificado
    Loop
End Sub

' Guarda en disco los archivos de texto que lo necesiten
Sub SaveDesktop
    Dim i, saved, other, m$
    If DeskCount = 0 Then
        Msg "No hay archivos en el Escritorio"
        Exit Sub
    End If
    saved = 0
    other = 0
    For i = 1 To DeskCount
        If Desk(i).Tipo >= 1 And Desk(i).Tipo <= 3 Then
            If Desk(i).Modificado Or Not Desk(i).EnDisco Then
                If SaveOne(i) Then saved = saved + 1
            End If
        Else
            If Desk(i).Modificado Then other = other + 1
        End If
    Next
    If saved = 0 And other = 0 Then
        Msg "No hay cambios que guardar"
    Else
        m$ = "Archivos guardados: " + N2S$(saved)
        If other > 0 Then m$ = m$ + "  (bases de datos: etapa 4)"
        Msg m$
    End If
End Sub

Sub OtherActivities
    Dim sel, choice
    sel = 1
    Do
        Cls
        TitleBar "Otras actividades"
        PrintAt 3, 3, "Otras actividades:", 15, 0
        MenuCount = 6
        MenuItem$(1) = "1. Cambiar la carpeta actual"
        MenuItem$(2) = "2. Aspecto de la pantalla (colores)"
        MenuItem$(3) = "3. Pantalla completa / ventana"
        MenuItem$(4) = "4. Ver fecha y hora"
        MenuItem$(5) = "5. Acerca de QBWorks"
        MenuItem$(6) = "6. Volver al menu principal"
        HelpBar "Flechas: mover   Enter: elegir   Esc: volver"
        choice = RunMenu(5, 5, sel)
        If choice > 0 Then sel = choice
        Select Case choice
            Case 1: ChangeFolder
            Case 2: ThemeMenu
            Case 3: ToggleFull
            Case 4: Msg "Fecha: " + Date$ + "     Hora: " + Time$
            Case 5: AboutScreen
            Case 0, 6: Exit Sub
        End Select
    Loop
End Sub

Sub ChangeFolder
    Dim p$
    Cls
    TitleBar "Cambiar la carpeta actual"
    PrintAt 4, 3, "Carpeta actual:", 15, 0
    PrintAt 5, 3, Left$(_CWD$, 74), 7, 0
    PrintAt 7, 3, "Nueva carpeta (Esc cancela):", 7, 0
    p$ = ReadLine$(8, 3, 74, "")
    If Cancelled Then Exit Sub
    p$ = LTrim$(RTrim$(p$))
    If p$ = "" Then Exit Sub
    If _DirExists(p$) Then
        ChDir p$
        Msg "Carpeta cambiada"
    Else
        Msg "Esa carpeta no existe"
    End If
End Sub

Sub AboutScreen
    Dim k$
    Cls
    TitleBar "Acerca de"
    PrintAt 5, 5, "QBWORKS 3.0", 15, 0
    PrintAt 7, 5, "Clon de AppleWorks 3.0 escrito en QB64.", 7, 0
    PrintAt 8, 5, "Modulos: procesador de textos, hoja de calculo", 7, 0
    PrintAt 9, 5, "y base de datos, con portapapeles compartido.", 7, 0
    HelpBar "Presione una tecla para volver"
    k$ = GetKey$
End Sub

'==============================================================
'  MODULOS (deben ir al final del archivo)
'==============================================================
'$INCLUDE:'FILES.BM'
'$INCLUDE:'WP.BM'
'$INCLUDE:'SS.BM'
'$INCLUDE:'DB.BM'
'$INCLUDE:'CLIP.BM'
'$INCLUDE:'PRINT.BM'
'$INCLUDE:'SPELL.BM'
'$INCLUDE:'THEME.BM'
'$INCLUDE:'GFX.BM'
