After clearing the Slowpoke Well and Kurt gives you the sample Lure Ball, he will instantly make any Apricorn Balls.

(The code for this feature was adapted from [Polished Crystal by Rangi](https://github.com/Rangi42/polishedcrystal).)

This code should be compatible with any other features.

## 1. Edit the Map Script in .GotLureBall

Edit [maps\KurtsHouse.asm](../blob/master/maps/KurtsHouse.asm):

We're just removing two lines, a check for the event flag that we're waiting for Kurt to finish, and the jump to the label we don't need anymore.

```diff
	setevent EVENT_KURT_GAVE_YOU_LURE_BALL
.GotLureBall:
-	checkevent EVENT_TEMPORARY_UNTIL_MAP_RELOAD_1
-	iftrue .WaitForApricorns
	checkevent EVENT_GAVE_KURT_RED_APRICORN
```



## 2. Edit the Map Script in .GaveKurtApricorns

Now we're removing the ```setflag ENGINE_KURT_MAKING_BALLS``` and ```.WaitForApricorn``` label along with the now unneeded "It'll take a day" text.
Instead, Kurt is going to say he'll begin work immediately, the screen will fade to black and reload the player in Kurt's house. Then the script is completely normal, with Kurt delivering the finished Apricorn balls. 

```diff
.GaveKurtApricorns:
	setevent EVENT_TEMPORARY_UNTIL_MAP_RELOAD_1
-	setflag ENGINE_KURT_MAKING_BALLS
-.WaitForApricorns:
+	writetext KurtsHouseKurtGetStartedText
+	waitbutton
-	writetext KurtsHouseKurtItWillTakeADayText
-	waitbutton
	closetext
+	special FadeBlackQuickly
+	special ReloadSpritesNoPalettes
+	playsound SFX_WARP_TO
+	waitsfx
+	pause 35
+	sjump Kurt1	
	end

.Cancel:
```
## 3. Add New Text that we referenced
Edit [maps\KurtsHouse.asm](../blob/master/maps/KurtsHouse.asm):

```diff
KurtsHouseKurtGoAroundPlayerThenExitHouseMovement:
	big_step RIGHT
	big_step DOWN
	big_step DOWN
	big_step DOWN
	big_step DOWN
	big_step DOWN
	step_end
+
+KurtsHouseKurtGetStartedText:
+	text "Kurt: I'll get"
+	line "started right now!"
+	done
+
KurtsHouseKurtMakingBallsMustWaitText:
	text "Hm? Who are you?"
```
And a little farther down in the same file, we can safely remove the text data we don't need anymore.
```diff
	line "into a BALL."
	done

-KurtsHouseKurtItWillTakeADayText:
-	text "KURT: It'll take a"
-	line "day to make you a"
-
-	para "BALL. Come back"
-	line "for it later."
-	done
-
KurtsHouseKurtThatsALetdownText:
```
That's it!
Let me know if you have any questions, you can find me in the discord server.

![fastkurt](https://user-images.githubusercontent.com/110363717/188763419-0e34204a-1e8a-456e-a9be-c316071cfbdf.png)
