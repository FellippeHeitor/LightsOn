'Lights On
'A game by Fellippe Heitor - @FellippeHeitor - fellippe@qb64.org
'
'Light bulb images from https://blog.1000bulbs.com/home/flip-the-switch-how-an-incandescent-light-bulb-works
'End level bg from http://blog-sap.com/analytics/2013/06/14/sap-lumira-new-software-update-general-availability-of-cloud-version-and-emeauk-flash-sale-at-bi2013/
'Ding sound: https://www.freesound.org/people/Flo_Rayen/sounds/191835/
'Bonus sound: http://freesound.org/people/LittleRobotSoundFactory/sounds/274183/
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

DIM SHARED Arena AS LONG, SonicPassed AS LONG, Bg AS LONG
DIM SHARED LightOn AS LONG, LightOff AS LONG
DIM SHARED Ding AS LONG, Piano AS LONG, Switch AS LONG, Bonus AS LONG
DIM SHARED Arial AS LONG, FontHeight AS INTEGER

Arena = _NEWIMAGE(600, 600, 32)

'Load assets:
'Arial = _LOADFONT("arial.ttf", 24)
LightOn = _LOADIMAGE("assets/lighton.png", 32)
LightOff = _LOADIMAGE("assets/lightoff.png", 32)
Bg = _LOADIMAGE("assets/bg.jpg", 32)
Ding = _SNDOPEN("assets/ding.wav", "sync")
Piano = _SNDOPEN("assets/piano.ogg", "sync")
Switch = _SNDOPEN("assets/switch.wav", "sync")
Bonus = _SNDOPEN("assets/bonus.ogg", "sync")

IF Bg < -1 THEN _SETALPHA 30, , Bg
IF Arial > 0 THEN FontHeight = _FONTHEIGHT(Arial) ELSE FontHeight = 16

SCREEN _NEWIMAGE(600, 600 + FontHeight * 2, 32)
DO UNTIL _SCREENEXISTS: _LIMIT 30: LOOP
_TITLE "Lights On" + CHR$(0)

SonicPassed = _NEWIMAGE(_WIDTH / 2, _HEIGHT / 2, 32)

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

DIM k AS LONG, Alpha AS INTEGER
DIM maxW AS INTEGER, maxH AS INTEGER
DIM MinMoves AS INTEGER, Score AS _UNSIGNED LONG
DIM TryAgain AS _BYTE

DIM Button(1 TO 2) AS obj, Caption(1 TO 2) AS STRING
Caption(1) = "Try again"
Button(1).y = _HEIGHT / 2 + FontHeight * 11.5
Button(1).w = _PRINTWIDTH(Caption(1)) + 40
Button(1).x = _WIDTH / 2 - 10 - Button(1).w
Button(1).h = 40

Caption(2) = "Next level"
Button(2).y = _HEIGHT / 2 + FontHeight * 11.5
Button(2).w = _PRINTWIDTH(Caption(2)) + 40
Button(2).x = _WIDTH / 2 + 10
Button(2).h = 40


IF LightOn < -1 AND LightOff < -1 THEN
    'Show intro
    _DEST SonicPassed
    CLS , 0
    COLOR _RGB32(255, 255, 255), 0
    _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH("Lights On!") / 2, _HEIGHT - FontHeight * 2), "Lights On!"
    _DEST 0

    _PUTIMAGE (_WIDTH / 2 - _WIDTH(LightOff) / 2, 0), LightOff
    _DELAY 1
    Alpha = 0
    IF Piano > 0 THEN _SNDPLAY Piano
    DO
        IF Alpha < 255 THEN Alpha = Alpha + 5 ELSE EXIT DO
        _SETALPHA Alpha, , SonicPassed
        _CLEARCOLOR _RGB32(0, 0, 0), SonicPassed
        _SETALPHA Alpha, , LightOn

        _PUTIMAGE (_WIDTH / 2 - _WIDTH(LightOn) / 2, 0), LightOn
        _PUTIMAGE , SonicPassed

        _DISPLAY
        _LIMIT 20
    LOOP
END IF

DO
    IF NOT TryAgain THEN Level = Level + 1

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
    moves = 0
    DO
        WHILE _MOUSEINPUT: WEND

        UpdateArena

        _DEST 0
        UpdateScore
        _PUTIMAGE (0, 0), Arena

        _DISPLAY

        k = _KEYHIT

        IF k = 27 THEN EXIT DO: SYSTEM

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
    DIM BgXOffset AS SINGLE, BgYOffset AS SINGLE
    DIM BgXSpeed AS SINGLE, BgYSpeed AS SINGLE

    Snd1 = false: Snd2 = false: Snd3 = false
    FinalBonus = false

    IF LightOn < -1 THEN _SETALPHA 255, , LightOn

    Alpha = 0
    TryAgain = false
    EndAnimationStep = 1
    SkipEndAnimation = false

    BgXSpeed = .5
    BgYSpeed = .3
    BgXOffset = _WIDTH(Bg) - _WIDTH * 1.5
    BgYOffset = _HEIGHT(Bg) - _HEIGHT * 1.5

    IF Piano > 0 THEN _SNDPLAY Piano
    DO
        WHILE _MOUSEINPUT: WEND

        IF EndAnimationStep < 70 THEN
            _DEST SonicPassed
            CLS , 0
            m$ = "Level" + STR$(Level) + " - All Lights On!"
            COLOR _RGB32(0, 0, 0), 0
            _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2 + 1, _HEIGHT / 2 - 80 - FontHeight + 1), m$
            COLOR _RGB32(255, 255, 255), 0
            _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 - 80 - FontHeight), m$

            m$ = "Moves used:" + STR$(moves)
            COLOR _RGB32(0, 0, 0), 0
            _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2 + 1, _HEIGHT / 2 + FontHeight * 2.5 + 1), m$
            COLOR _RGB32(255, 255, 255), 0
            _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 + FontHeight * 2.5), m$

            m$ = "Score:" + STR$(Score)
            COLOR _RGB32(0, 0, 0), 0
            _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2 + 1, _HEIGHT / 2 + FontHeight * 3.5 + 1), m$
            COLOR _RGB32(255, 255, 255), 0
            _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 + FontHeight * 3.5), m$
        END IF

        _DEST 0

        BgXOffset = BgXOffset + BgXSpeed
        BgYOffset = BgYOffset + BgYSpeed
        IF BgXOffset < 0 OR BgXOffset + _WIDTH - 1 > _WIDTH(Bg) THEN BgXSpeed = BgXSpeed * -1
        IF BgYOffset < 0 OR BgYOffset + _HEIGHT - 1 > _HEIGHT(Bg) THEN BgYSpeed = BgYSpeed * -1
        IF Bg < -1 THEN _PUTIMAGE (0, 0)-STEP(_WIDTH - 1, _HEIGHT - 1), Bg, , (BgXOffset, BgYOffset)-STEP(_WIDTH - 1, _HEIGHT - 1)
        SELECT CASE EndAnimationStep
            CASE 1
                IF Alpha < 255 THEN Alpha = Alpha + 10 ELSE EndAnimationStep = 2: SlideOpen = 0: SlideVelocity = 30: Alpha = 0
                IF NOT Bg < -1 THEN
                    LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(255, 255, 0, Alpha), BF
                    LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(255, 255, 255, Alpha), BF
                END IF
                _PUTIMAGE , SonicPassed
            CASE 2
                IF NOT Bg < -1 THEN LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(255, 255, 255, 30), BF
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

                _PUTIMAGE , SonicPassed
                DIM b AS INTEGER
                b = map(SlideOpen, 0, 600, 255, 0)
                LINE (0, _HEIGHT / 2 - 125 + FontHeight * 1.5)-STEP(SlideOpen, 130), _RGB32(255, 255, 255), BF
                LINE (0, _HEIGHT / 2 - 120 + FontHeight * 1.5)-STEP(SlideOpen, 120), _RGB32(b * 1.5, b * 1.5 - 50, 0), BF
            CASE IS >= 3
                EndAnimationStep = EndAnimationStep + 1
                IF NOT Bg < -1 THEN LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(255, 255, 255, 40), BF
                _PUTIMAGE , SonicPassed
                LINE (0, _HEIGHT / 2 - 125 + FontHeight * 1.5)-STEP(SlideOpen, 130), _RGB32(255, 255, 255), BF
                LINE (0, _HEIGHT / 2 - 120 + FontHeight * 1.5)-STEP(SlideOpen, 120), _RGB32(b, b - 20, 0), BF

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
                            IF Switch > 0 AND NOT SkipEndAnimation THEN _SNDPLAYCOPY Switch
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
                            IF Switch > 0 AND NOT SkipEndAnimation THEN _SNDPLAYCOPY Switch
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
                            IF Switch > 0 AND NOT SkipEndAnimation THEN _SNDPLAYCOPY Switch
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

                IF EndAnimationStep > 60 THEN
                    IF FinalBonus = false THEN
                        FinalBonus = true
                        IF moves < MinMoves THEN
                            Score = Score + 50
                            IF Bonus > 0 THEN _SNDPLAYCOPY Bonus
                        END IF
                    ELSE
                        IF moves < MinMoves THEN
                            m$ = "Strategy master! +50 bonus points!"
                            COLOR _RGB32(0, 0, 0), 0
                            _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2 + 1, _HEIGHT / 2 + FontHeight * 9.5 + 1), m$
                            COLOR _RGB32(255, 255, 255), 0
                            _PRINTSTRING (_WIDTH / 2 - _PRINTWIDTH(m$) / 2, _HEIGHT / 2 + FontHeight * 9.5), m$
                        END IF
                    END IF
                END IF
        END SELECT

        'Buttons
        IF EndAnimationStep > 60 THEN
            DIM ii AS INTEGER
            FOR ii = 1 TO 2
                IF Hovering(Button(ii)) THEN
                    LINE (Button(ii).x + 5, Button(1).y + 5)-STEP(Button(ii).w, Button(ii).h), _RGB32(0, 0, 0), BF
                    LINE (Button(ii).x, Button(1).y)-STEP(Button(ii).w, Button(ii).h), _RGB32(255, 255, 255), BF
                ELSE
                    LINE (Button(ii).x, Button(ii).y)-STEP(Button(ii).w, Button(ii).h), _RGBA32(255, 255, 255, 30), BF
                END IF
                'COLOR _RGB32(255, 255, 255), 0
                '_PRINTSTRING (Button(ii).x + Button(ii).w / 2 - _PRINTWIDTH(Caption(ii)) / 2 + 1, Button(ii).y + Button(ii).h / 2 - FontHeight / 2 + 1), Caption(ii)
                COLOR _RGB32(0, 0, 0), 0
                _PRINTSTRING (Button(ii).x + Button(ii).w / 2 - _PRINTWIDTH(Caption(ii)) / 2, Button(ii).y + Button(ii).h / 2 - FontHeight / 2), Caption(ii)
            NEXT
        END IF

        _DISPLAY

        k = _KEYHIT

        IF k = 13 AND EndAnimationStep > 60 THEN EXIT DO
        IF k = 27 THEN SYSTEM

        IF _MOUSEBUTTON(1) AND EndAnimationStep > 60 THEN
            WHILE _MOUSEBUTTON(1): ii = _MOUSEINPUT: WEND
            IF Hovering(Button(1)) THEN
                TryAgain = true
                EXIT DO
            ELSEIF Hovering(Button(2)) THEN
                EXIT DO
            END IF
        ELSEIF _MOUSEBUTTON(1) THEN
            SkipEndAnimation = true
        END IF

        IF NOT SkipEndAnimation THEN _LIMIT 30
    LOOP
LOOP

SUB UpdateArena
    DIM imgWidth AS INTEGER, imgHeight AS INTEGER
    DIM FoundHover AS _BYTE

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
                    IF TIMER - lights(i, j).lastSwitch < .3 THEN
                        _SETALPHA constrain(map(TIMER - lights(i, j).lastSwitch, 0, .3, 0, 255), 0, 255), , LightOn
                    ELSE
                        _SETALPHA 255, , LightOn
                    END IF
                    _PUTIMAGE (lights(i, j).x + lights(i, j).w / 2 - imgWidth / 2, lights(i, j).y)-STEP(imgWidth, lights(i, j).h), LightOn
                ELSE
                    LINE (lights(i, j).x, lights(i, j).y)-STEP(lights(i, j).w, lights(i, j).h), _RGB32(111, 227, 39), BF
                END IF
            END IF
            IF Hovering(lights(i, j)) AND FoundHover = false THEN
                FoundHover = true
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

