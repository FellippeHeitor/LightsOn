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
    lastSwitch AS SINGLE
    lastHint AS SINGLE
END TYPE

DIM SHARED maxGridW AS INTEGER, maxGridH AS INTEGER

DIM SHARED lights(1 TO 20, 1 TO 20) AS obj
DIM SHARED start!, moves AS INTEGER, m$
DIM SHARED i AS INTEGER, j AS INTEGER, Level AS INTEGER
DIM LastActivity AS SINGLE, oldMouseX AS INTEGER, oldMouseY AS INTEGER
DIM Highlight AS _BYTE, HighlightX AS INTEGER, HighlightY AS INTEGER
DIM LastHighlightUpdate AS SINGLE

DIM k AS LONG, Alpha AS INTEGER
DIM maxW AS INTEGER, maxH AS INTEGER
DIM MinMoves AS INTEGER, Score AS _UNSIGNED LONG

IF LightOn < -1 AND LightOff < -1 THEN
    'Show intro
    _PUTIMAGE (_WIDTH / 2 - _WIDTH(LightOff) / 2, 0), LightOff
    _DELAY 1
    Alpha = 0
    IF Piano > 0 THEN _SNDPLAY Piano
    DO
        IF Alpha < 255 THEN Alpha = Alpha + 5 ELSE EXIT DO
        _SETALPHA Alpha, , LightOn
        _PUTIMAGE (_WIDTH / 2 - _WIDTH(LightOn) / 2, 0), LightOn

        COLOR _RGBA32(255, 255, 255, Alpha), _RGB32(0, 0, 0)
        _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH("Lights On") / 2, _HEIGHT - FontHeight * 4), "Lights On"
        _DISPLAY
        _LIMIT 20
    LOOP
    _DELAY 1
END IF

DO
    Level = Level + 1

    SELECT CASE Level
        CASE 1
            maxGridW = 1
            maxGridH = 2
            MinMoves = 2
        CASE 2
            maxGridW = 2
            maxGridH = 2
            MinMoves = 1
        CASE 3, 4
            maxGridW = 4
            maxGridH = 5
            MinMoves = 11
        CASE 5
            maxGridW = 5
            maxGridH = 7
            MinMoves = 65
        CASE 6
            maxGridW = 10
            maxGridH = 10
            MinMoves = 65
        CASE 7, 8
            maxGridW = 7
            maxGridH = 9
            MinMoves = 90
        CASE 9, 10
            maxGridW = 7
            maxGridH = 11
            MinMoves = 130
        CASE 11, 12
            maxGridW = 9
            maxGridH = 11
            MinMoves = 90
        CASE 13, 14
            maxGridW = 11
            maxGridH = 17
            MinMoves = 180
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
    LastActivity = TIMER
    moves = 0
    DO
        WHILE _MOUSEINPUT: WEND

        IF _MOUSEX <> oldMouseX OR _MOUSEY <> oldMouseY THEN
            LastActivity = TIMER
            oldMouseX = _MOUSEX
            oldMouseY = _MOUSEY
        END IF

        IF TIMER - LastActivity >= 10 AND Highlight = false THEN Highlight = true: HighlightY = maxGridH

        IF Highlight THEN
            FOR j = 1 TO maxGridW
                lights(j, HighlightY).lastHint = TIMER
            NEXT
            HighlightY = HighlightY - 1
            IF HighlightY < 1 THEN Highlight = false
            LastActivity = TIMER
        END IF

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
    _DEST 0
    _PUTIMAGE (0, 0), Arena

    DIM EndAnimationStep AS INTEGER, FinalBonus AS _BYTE
    DIM SlideOpen AS INTEGER, SlideVelocity AS SINGLE
    DIM Snd1 AS _BYTE, Snd2 AS _BYTE, Snd3 AS _BYTE
    DIM FinalLamp1!, FinalLamp2!, FinalLamp3!
    DIM SkipEndAnimation AS _BYTE

    Snd1 = false: Snd2 = false: Snd3 = false
    FinalBonus = false

    IF LightOn < -1 THEN _SETALPHA 255, , LightOn

    _DEST SonicPassed
    COLOR _RGB32(0, 0, 0), 0
    CLS
    m$ = "Lights On!"
    _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 - 80 - FontHeight * 3), m$

    m$ = "Moves used:" + STR$(moves)
    _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 + FontHeight * 2.5), m$

    m$ = "Click anywhere to continue"
    _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT - FontHeight * 1.5), m$
    _DEST 0

    Alpha = 0
    EndAnimationStep = 1
    SkipEndAnimation = false
    IF Piano > 0 THEN _SNDPLAY Piano
    DO
        SELECT CASE EndAnimationStep
            CASE 1
                IF Alpha < 255 THEN Alpha = Alpha + 10 ELSE EndAnimationStep = 2: SlideOpen = 0: SlideVelocity = 30: Alpha = 0: CLS
                LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(255, 255, 0, Alpha), BF
                LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(255, 255, 255, Alpha), BF
                _PUTIMAGE (0, 0), SonicPassed
                _DISPLAY
            CASE 2
                LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(255, 255, 255, 30), BF
                SlideVelocity = SlideVelocity - .2
                IF SlideVelocity < 1 THEN SlideVelocity = 1
                IF SlideOpen < 600 THEN
                    SlideOpen = SlideOpen + SlideVelocity
                ELSE
                    SlideOpen = 600
                    EndAnimationStep = 3
                    i = _WIDTH / 2 - (SlideOpen / 3.5)
                    j = _HEIGHT / 2 - SlideOpen / 5 + FontHeight * 1.5
                END IF

                _PUTIMAGE (0, 0), SonicPassed
                DIM b AS INTEGER
                b = map(SlideOpen, 0, 600, 255, 0)
                LINE (0, _HEIGHT / 2 - 120 + FontHeight * 1.5)-STEP(SlideOpen, 120), _RGB32(b, b, b), BF
                _DISPLAY
            CASE IS >= 3
                EndAnimationStep = EndAnimationStep + 1
                LINE (0, 0)-(_WIDTH, _HEIGHT), _RGB32(255, 255, 255), BF
                _PUTIMAGE (0, 0), SonicPassed
                LINE (0, _HEIGHT / 2 - 120 + FontHeight * 1.5)-STEP(SlideOpen, 120), _RGB32(0, 0, 0), BF

                IF LightOff < -1 THEN
                    _PUTIMAGE (i, j)-STEP(SlideOpen / 5, SlideOpen / 5), LightOff
                    _PUTIMAGE (i + SlideOpen / 5, j)-STEP(SlideOpen / 5, SlideOpen / 5), LightOff
                    _PUTIMAGE (i + (SlideOpen / 5) * 2, j)-STEP(SlideOpen / 5, SlideOpen / 5), LightOff
                END IF

                IF EndAnimationStep >= 3 THEN
                    IF MinMoves <= MinMoves * 3 THEN
                        IF Ding > 0 AND Snd1 = false THEN _SNDPLAYCOPY Ding: Snd1 = true
                        IF EndAnimationStep = 4 THEN FinalLamp1! = TIMER: Score = Score + 20

                        IF EndAnimationStep <= 20 THEN
                            Score = Score + 10
                            IF Switch > 0 THEN _SNDPLAYCOPY Switch
                        END IF

                        IF LightOn < -1 THEN
                            _SETALPHA constrain(map(TIMER - FinalLamp1!, 0, .3, 0, 255), 0, 255), , LightOn
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
                        IF EndAnimationStep = 21 THEN FinalLamp2! = TIMER: Score = Score + 20

                        IF EndAnimationStep <= 40 THEN
                            Score = Score + 10
                            IF Switch > 0 THEN _SNDPLAYCOPY Switch
                        END IF

                        IF LightOn < -1 THEN
                            _SETALPHA constrain(map(TIMER - FinalLamp2!, 0, .3, 0, 255), 0, 255), , LightOn
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
                        IF EndAnimationStep = 41 THEN FinalLamp3! = TIMER: Score = Score + 20

                        IF EndAnimationStep <= 60 THEN
                            Score = Score + 10
                            IF Switch > 0 THEN _SNDPLAYCOPY Switch
                        END IF

                        IF LightOn < -1 THEN
                            _SETALPHA constrain(map(TIMER - FinalLamp3!, 0, .3, 0, 255), 0, 255), , LightOn
                            _PUTIMAGE (i + (SlideOpen / 5) * 2, j)-STEP(SlideOpen / 5, SlideOpen / 5), LightOn
                        ELSE
                            LINE (i + (SlideOpen / 5) * 2, j)-STEP(SlideOpen / 5, SlideOpen / 5), _RGB32(111, 227, 39), BF
                            LINE (i + (SlideOpen / 5) * 2, j)-STEP(SlideOpen / 5, SlideOpen / 5), _RGB32(0, 0, 0), B
                        END IF
                    END IF
                END IF

                m$ = "Score:" + STR$(Score)
                _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 + FontHeight * 3.5), m$

                IF EndAnimationStep > 60 THEN
                    IF FinalBonus = false THEN
                        FinalBonus = true
                        IF moves < MinMoves THEN
                            Score = Score + 50
                            IF Ding > 0 THEN _SNDPLAYCOPY Ding
                        END IF
                    ELSE
                        IF moves < MinMoves THEN
                            m$ = "Strategy master! +50 bonus points!"
                            _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 + FontHeight * 5.5), m$
                        END IF
                    END IF
                END IF

                _DISPLAY
        END SELECT

        k = _KEYHIT

        IF k = 13 AND EndAnimationStep > 60 THEN EXIT DO
        IF k = 27 THEN SYSTEM

        WHILE _MOUSEINPUT: WEND

        IF _MOUSEBUTTON(1) AND EndAnimationStep > 60 THEN
            WHILE _MOUSEBUTTON(1): i = _MOUSEINPUT: WEND
            EXIT DO
        ELSEIF _MOUSEBUTTON(1) THEN
            SkipEndAnimation = true
        END IF

        IF NOT SkipEndAnimation THEN _LIMIT 30
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
            IF LightOff < -1 THEN
                _PUTIMAGE (lights(i, j).x + lights(i, j).w / 2 - imgWidth / 2, lights(i, j).y)-STEP(imgWidth, lights(i, j).h), LightOff
            END IF
            IF lights(i, j).IsOn THEN
                IF LightOn < -1 THEN
                    _SETALPHA constrain(map(TIMER - lights(i, j).lastSwitch, 0, .3, 0, 255), 0, 255), , LightOn
                    _PUTIMAGE (lights(i, j).x + lights(i, j).w / 2 - imgWidth / 2, lights(i, j).y)-STEP(imgWidth, lights(i, j).h), LightOn
                ELSE
                    LINE (lights(i, j).x, lights(i, j).y)-STEP(lights(i, j).w, lights(i, j).h), _RGB32(111, 227, 39), BF
                END IF
            ELSE
                IF LightOn < -1 THEN
                    _SETALPHA constrain(map(TIMER - lights(i, j).lastHint, 0, 1, 100, 0), 0, 80), , LightOn
                    _PUTIMAGE (lights(i, j).x + lights(i, j).w / 2 - imgWidth / 2, lights(i, j).y)-STEP(imgWidth, lights(i, j).h), LightOn
                END IF
            END IF
            IF Hovering(lights(i, j)) THEN
                LINE (lights(i, j).x, lights(i, j).y)-STEP(lights(i, j).w, lights(i, j).h), _RGBA32(255, 255, 255, 100), BF
                CheckState lights(i, j)
            END IF
            LINE (lights(i, j).x, lights(i, j).y)-STEP(lights(i, j).w, lights(i, j).h), , B
        NEXT
    NEXT
END SUB

SUB UpdateScore
    m$ = "Level:" + STR$(Level) + " (" + LTRIM$(STR$(maxGridW)) + "x" + LTRIM$(STR$(maxGridH)) + ")    Moves:" + STR$(moves) + "    Time elapsed:" + STR$(INT(TIMER - start!)) + "s"

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
    ioff = -1
    joff = 0
    IF object.i + ioff > 0 AND object.i + ioff < maxGridW + 1 AND object.j + joff > 0 AND object.j + joff < maxGridH + 1 THEN
        lights(object.i + ioff, object.j + joff).IsOn = NOT lights(object.i + ioff, object.j + joff).IsOn
        lights(object.i + ioff, object.j + joff).lastSwitch = TIMER
    END IF

    ioff = 1
    joff = 0
    IF object.i + ioff > 0 AND object.i + ioff < maxGridW + 1 AND object.j + joff > 0 AND object.j + joff < maxGridH + 1 THEN
        lights(object.i + ioff, object.j + joff).IsOn = NOT lights(object.i + ioff, object.j + joff).IsOn
        lights(object.i + ioff, object.j + joff).lastSwitch = TIMER
    END IF

    ioff = 0
    joff = -1
    IF object.i + ioff > 0 AND object.i + ioff < maxGridW + 1 AND object.j + joff > 0 AND object.j + joff < maxGridH + 1 THEN
        lights(object.i + ioff, object.j + joff).IsOn = NOT lights(object.i + ioff, object.j + joff).IsOn
        lights(object.i + ioff, object.j + joff).lastSwitch = TIMER
    END IF

    ioff = 0
    joff = 1
    IF object.i + ioff > 0 AND object.i + ioff < maxGridW + 1 AND object.j + joff > 0 AND object.j + joff < maxGridH + 1 THEN
        lights(object.i + ioff, object.j + joff).IsOn = NOT lights(object.i + ioff, object.j + joff).IsOn
        lights(object.i + ioff, object.j + joff).lastSwitch = TIMER
    END IF
END SUB

FUNCTION Hovering%% (object AS obj)
    Hovering%% = _MOUSEX > object.x AND _MOUSEX < object.x + object.w AND _MOUSEY > object.y AND _MOUSEY < object.y + object.h
END FUNCTION

'functions below are borrowed from p5js.bas:
FUNCTION map! (value!, minRange!, maxRange!, newMinRange!, newMaxRange!)
    map! = ((value! - minRange!) / (maxRange! - minRange!)) * (newMaxRange! - newMinRange!) + newMinRange!
END FUNCTION

FUNCTION min! (a!, b!)
    IF a! < b! THEN min! = a! ELSE min! = b!
END FUNCTION

FUNCTION max! (a!, b!)
    IF a! > b! THEN max! = a! ELSE max! = b!
END FUNCTION

FUNCTION constrain! (n!, low!, high!)
    constrain! = max(min(n!, high!), low!)
END FUNCTION
