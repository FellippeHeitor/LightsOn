'Lights On
'A game by Fellippe Heitor - @FellippeHeitor - fellippe@qb64.org
'
'Light bulb images from https://blog.1000bulbs.com/home/flip-the-switch-how-an-incandescent-light-bulb-works
'Ding sound: https://www.freesound.org/people/Flo_Rayen/sounds/191835/
'Piano sound: https://www.freesound.org/people/FoolBoyMedia/sounds/352655/
'Switch sound: https://www.freesound.org/people/Mindloop/sounds/253659/
'App icon: http://www.iconarchive.com/show/small-n-flat-icons-by-paomedia/light-bulb-icon.html
'
'Original concept by Avi Olti, Gyora Benedek, Zvi Herman, Revital Bloomberg, Avi Weiner and Michael Ganor
'https://en.wikipedia.org/wiki/Lights_Out_(game)

OPTION _EXPLICIT

$EXEICON:'./assets/lightson.ico'
_ICON

CONST true = -1, false = NOT true

RANDOMIZE TIMER

DIM SHARED Arena AS LONG, SonicPassed AS LONG
DIM SHARED LightOn AS LONG, LightOff AS LONG
DIM SHARED Ding AS LONG, Piano AS LONG, Switch AS LONG
DIM SHARED Arial AS LONG, FontHeight AS INTEGER

Arena = _NEWIMAGE(600, 600, 32)

'Load assets:
LightOn = _LOADIMAGE("assets/lighton.png", 32)
LightOff = _LOADIMAGE("assets/lightoff.png", 32)
Ding = _SNDOPEN("assets/ding.wav", "sync")
Piano = _SNDOPEN("assets/piano.ogg", "sync")
Switch = _SNDOPEN("assets/switch.wav", "sync")
'Arial = _LOADFONT("arial.ttf", 24)

IF Arial > 0 THEN FontHeight = _FONTHEIGHT(Arial) ELSE FontHeight = 16

SCREEN _NEWIMAGE(600, 600 + FontHeight * 2, 32)
DO UNTIL _SCREENEXISTS: _LIMIT 30: LOOP
_TITLE "Lights On" + CHR$(0)

SonicPassed = _NEWIMAGE(_WIDTH, _HEIGHT, 32)

IF Arial > 0 THEN
    _FONT Arial
    _DEST SonicPassed
    _FONT Arial
    _DEST 0
END IF

TYPE obj
    i AS INTEGER
    j AS INTEGER
    x AS INTEGER
    y AS INTEGER
    w AS INTEGER
    h AS INTEGER
    IsOn AS _BYTE
END TYPE

DIM SHARED maxGridW AS INTEGER, maxGridH AS INTEGER

DIM SHARED lights(1 TO 20, 1 TO 20) AS obj
DIM SHARED start!, moves AS INTEGER, m$
DIM SHARED i AS INTEGER, j AS INTEGER, Level AS INTEGER
DIM k AS LONG, Alpha AS INTEGER
DIM maxW AS INTEGER, maxH AS INTEGER
DIM MinMoves AS INTEGER

IF LightOn < -1 AND LightOff < -1 THEN
    'Show intro
    _PUTIMAGE (_WIDTH / 2 - _WIDTH(LightOff) / 2, _HEIGHT / 2 - _HEIGHT(LightOff) / 2 - FontHeight), LightOff
    _DELAY 1
    Alpha = 0
    IF Piano > 0 THEN _SNDPLAY Piano
    DO
        IF Alpha < 255 THEN Alpha = Alpha + 5 ELSE EXIT DO
        _SETALPHA Alpha, , LightOn
        _PUTIMAGE (_WIDTH / 2 - _WIDTH(LightOn) / 2, _HEIGHT / 2 - _HEIGHT(LightOn) / 2 - FontHeight), LightOn

        COLOR _RGBA32(255, 255, 255, Alpha), _RGB32(0, 0, 0)
        _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH("Lights On") / 2, _HEIGHT - FontHeight * 2), "Lights On"
        _DISPLAY
        _LIMIT 20
    LOOP
    _DELAY 1
END IF

DO
    Level = Level + 1

    SELECT CASE Level
        CASE 1, 2
            maxGridW = 4
            maxGridH = 5
            MinMoves = 11
        CASE 3, 4
            maxGridW = 5
            maxGridH = 7
            MinMoves = 65
        CASE 5, 6
            maxGridW = 10
            maxGridH = 10
            MinMoves = 65
        CASE 7, 8
            maxGridW = 7
            maxGridH = 9
            MinMoves = 90
        CASE ELSE
            maxGridW = 20
            maxGridH = 20
            MinMoves = 230
    END SELECT

    maxW = _WIDTH(Arena) / maxGridW
    maxH = _HEIGHT(Arena) / maxGridH

    FOR i = 1 TO maxGridW
        FOR j = 1 TO maxGridH
            lights(i, j).x = i * maxW - maxW
            lights(i, j).y = j * maxH - maxH
            lights(i, j).w = maxW - 1
            lights(i, j).h = maxH - 1
            lights(i, j).i = i
            lights(i, j).j = j
            lights(i, j).IsOn = false
        NEXT
    NEXT

    DIM rndState AS INTEGER
    FOR rndState = 1 TO maxGridW / 3
        i = _CEIL(RND * maxGridW)
        j = _CEIL(RND * maxGridH)
        SetState lights(i, j)
    NEXT

    start! = TIMER
    moves = 0
    DO
        WHILE _MOUSEINPUT: WEND

        UpdateArena

        _DEST 0
        UpdateScore
        _PUTIMAGE (0, 0), Arena

        _DISPLAY

        k = _KEYHIT

        IF k = 27 THEN SYSTEM

        _LIMIT 30
    LOOP UNTIL Victory

    UpdateArena

    DIM EndAnimationStep AS INTEGER
    DIM SlideOpen AS INTEGER
    DIM Snd1 AS _BYTE, Snd2 AS _BYTE, Snd3 AS _BYTE
    Snd1 = false: Snd2 = false: Snd3 = false

    _DEST SonicPassed
    COLOR _RGB32(0, 0, 0), 0
    CLS
    m$ = "You Passed!"
    _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 - 80 - FontHeight * 3), m$

    m$ = "Moves used:" + STR$(moves)
    _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 - 80 - FontHeight * 2), m$

    m$ = "Click anywhere to continue"
    _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 + 80 + FontHeight * 3), m$
    _DEST 0

    Alpha = 0
    EndAnimationStep = 1
    IF Piano > 0 THEN _SNDPLAY Piano
    DO
        SELECT CASE EndAnimationStep
            CASE 1
                _PUTIMAGE (0, 0), Arena
                IF Alpha < 255 THEN Alpha = Alpha + 10 ELSE EndAnimationStep = 2: SlideOpen = 0: Alpha = 0: CLS
                LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(255, 255, 0, Alpha), BF
                LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(255, 255, 255, Alpha), BF
                _PUTIMAGE (0, 0), SonicPassed
                _DISPLAY
            CASE 2
                LINE (0, 0)-(_WIDTH, _HEIGHT), _RGB32(255, 255, 255), BF
                IF SlideOpen < 400 THEN SlideOpen = SlideOpen + 15 ELSE EndAnimationStep = 3
                _PUTIMAGE (0, 0), SonicPassed
                LINE (_WIDTH / 2 - SlideOpen / 2, _HEIGHT / 2 - SlideOpen / 5 + FontHeight * 1.5)-STEP(SlideOpen, SlideOpen / 5), _RGB32(0, 0, 0), BF
                _DISPLAY
            CASE IS >= 3
                EndAnimationStep = EndAnimationStep + 1
                LINE (0, 0)-(_WIDTH, _HEIGHT), _RGB32(255, 255, 255), BF
                _PUTIMAGE (0, 0), SonicPassed
                LINE (_WIDTH / 2 - SlideOpen / 2, _HEIGHT / 2 - SlideOpen / 5 + FontHeight * 1.5)-STEP(SlideOpen, SlideOpen / 5), _RGB32(0, 0, 0), BF

                IF EndAnimationStep > 3 THEN
                    IF MinMoves <= MinMoves * 3 THEN
                        IF Ding > 0 AND Snd1 = false THEN _SNDPLAYCOPY Ding: Snd1 = true
                        i = _WIDTH / 2 - (SlideOpen / 3.5)
                        j = _HEIGHT / 2 - SlideOpen / 5 + FontHeight * 1.5
                        IF LightOn < -1 THEN
                            _PUTIMAGE (i, j)-STEP(SlideOpen / 5, SlideOpen / 5), LightOn
                        ELSE
                            LINE (i, j)-STEP(SlideOpen / 5, SlideOpen / 5), _RGB32(111, 227, 39), BF
                            LINE (i, j)-STEP(SlideOpen / 5, SlideOpen / 5), _RGB32(0, 0, 0), B
                        END IF
                    END IF
                END IF

                IF EndAnimationStep > 20 THEN
                    IF moves <= MinMoves * 2 THEN
                        IF Ding > 0 AND Snd2 = false THEN _SNDPLAYCOPY Ding: Snd2 = true
                        IF LightOn < -1 THEN
                            _PUTIMAGE (i + SlideOpen / 5, j)-STEP(SlideOpen / 5, SlideOpen / 5), LightOn
                        ELSE
                            LINE (i + SlideOpen / 5, j)-STEP(SlideOpen / 5, SlideOpen / 5), _RGB32(111, 227, 39), BF
                            LINE (i + SlideOpen / 5, j)-STEP(SlideOpen / 5, SlideOpen / 5), _RGB32(0, 0, 0), B
                        END IF
                    END IF
                END IF

                IF EndAnimationStep > 40 THEN
                    IF moves <= MinMoves THEN
                        IF Ding > 0 AND Snd3 = false THEN _SNDPLAYCOPY Ding: Snd3 = true
                        IF LightOn < -1 THEN
                            _PUTIMAGE (i + (SlideOpen / 5) * 2, j)-STEP(SlideOpen / 5, SlideOpen / 5), LightOn
                        ELSE
                            LINE (i + (SlideOpen / 5) * 2, j)-STEP(SlideOpen / 5, SlideOpen / 5), _RGB32(111, 227, 39), BF
                            LINE (i + (SlideOpen / 5) * 2, j)-STEP(SlideOpen / 5, SlideOpen / 5), _RGB32(0,0,0), B
                        END IF
                    END IF
                END IF

                _DISPLAY
        END SELECT

        k = _KEYHIT

        IF k = 13 THEN EXIT DO
        IF k = 27 THEN SYSTEM

        WHILE _MOUSEINPUT: WEND

        IF _MOUSEBUTTON(1) THEN
            WHILE _MOUSEBUTTON(1): i = _MOUSEINPUT: WEND
            EXIT DO
        END IF

        _LIMIT 30
    LOOP
LOOP

SUB UpdateArena
    DIM imgWidth AS INTEGER, imgHeight AS INTEGER

    imgHeight = lights(1, 1).h
    imgWidth = imgHeight

    _DEST Arena
    CLS
    FOR i = 1 TO maxGridW
        FOR j = 1 TO maxGridH
            IF lights(i, j).IsOn THEN
                IF LightOn < -1 THEN
                    _PUTIMAGE (lights(i, j).x + lights(i, j).w / 2 - imgWidth / 2, lights(i, j).y)-STEP(imgWidth, lights(i, j).h), LightOn, , , _SMOOTH
                ELSE
                    LINE (lights(i, j).x, lights(i, j).y)-STEP(lights(i, j).w, lights(i, j).h), _RGB32(111, 227, 39), BF
                END IF
            ELSE
                IF LightOff < -1 THEN
                    _PUTIMAGE (lights(i, j).x + lights(i, j).w / 2 - imgWidth / 2, lights(i, j).y)-STEP(imgWidth, lights(i, j).h), LightOff, , , _SMOOTH
                END IF
            END IF
            IF Hovering(lights(i, j)) THEN
                LINE (lights(i, j).x, lights(i, j).y)-STEP(lights(i, j).w, lights(i, j).h), _RGBA32(28, 194, 255, 100), BF
                CheckState lights(i, j)
            END IF
            LINE (lights(i, j).x, lights(i, j).y)-STEP(lights(i, j).w, lights(i, j).h), , B
        NEXT
    NEXT
END SUB

SUB UpdateScore
    m$ = "Level:" + STR$(Level) + "    Moves:" + STR$(moves) + "    Time elapsed:" + STR$(INT(TIMER - start!)) + "s"

    COLOR _RGB32(0, 0, 0), _RGB32(255, 255, 255)
    CLS

    _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT - FontHeight * 1.5), m$
END SUB

FUNCTION Victory%%
    DIM i AS INTEGER, j AS INTEGER
    FOR i = 1 TO maxGridW
        FOR j = 1 TO maxGridH
            IF lights(i, j).IsOn = false THEN EXIT FUNCTION
        NEXT
    NEXT

    Victory%% = true
END FUNCTION

SUB CheckState (object AS obj)
    DIM i AS INTEGER
    IF _MOUSEBUTTON(1) THEN
        IF Switch > 0 THEN _SNDPLAYCOPY Switch
        moves = moves + 1
        SetState object

        WHILE _MOUSEBUTTON(1): i = _MOUSEINPUT: WEND
    END IF
END SUB

SUB SetState (object AS obj)
    DIM ioff AS INTEGER, joff AS INTEGER
    'ioff = 0
    'joff = 0
    'IF object.i + ioff > 0 AND object.i + ioff < maxGridW + 1 AND object.j + joff > 0 AND object.j + joff < maxGridH + 1 THEN
    '    lights(object.i + ioff, object.j + joff).IsOn = NOT lights(object.i + ioff, object.j + joff).IsOn
    'END IF

    ioff = -1
    joff = 0
    IF object.i + ioff > 0 AND object.i + ioff < maxGridW + 1 AND object.j + joff > 0 AND object.j + joff < maxGridH + 1 THEN
        lights(object.i + ioff, object.j + joff).IsOn = NOT lights(object.i + ioff, object.j + joff).IsOn
    END IF

    ioff = 1
    joff = 0
    IF object.i + ioff > 0 AND object.i + ioff < maxGridW + 1 AND object.j + joff > 0 AND object.j + joff < maxGridH + 1 THEN
        lights(object.i + ioff, object.j + joff).IsOn = NOT lights(object.i + ioff, object.j + joff).IsOn
    END IF

    ioff = 0
    joff = -1
    IF object.i + ioff > 0 AND object.i + ioff < maxGridW + 1 AND object.j + joff > 0 AND object.j + joff < maxGridH + 1 THEN
        lights(object.i + ioff, object.j + joff).IsOn = NOT lights(object.i + ioff, object.j + joff).IsOn
    END IF

    ioff = 0
    joff = 1
    IF object.i + ioff > 0 AND object.i + ioff < maxGridW + 1 AND object.j + joff > 0 AND object.j + joff < maxGridH + 1 THEN
        lights(object.i + ioff, object.j + joff).IsOn = NOT lights(object.i + ioff, object.j + joff).IsOn
    END IF
END SUB

FUNCTION Hovering%% (object AS obj)
    Hovering%% = _MOUSEX > object.x AND _MOUSEX < object.x + object.w AND _MOUSEY > object.y AND _MOUSEY < object.y + object.h
END FUNCTION
