
The code for this feature was adapted from [Polished Crystal by Rangi](https://github.com/Rangi42/polishedcrystal).

Using this feature, you can define a range of possible amounts of fruit to find on berry trees, determined at random.

This code should be compatible with any other features.

## 1. Add local constants to define the amount of Fruit we can find

Edit [engine\events\fruit_trees.asm](../blob/master/engine/events/fruit_trees.asm):

In this example, we can find between 3 and 5 berries per tree.

You can have any amount as long as you add extra code to test for each possible amount, and then the corresponding text to go with it.

```diff
+DEF FRUIT_TREE_3_MIN EQU 3
+DEF FRUIT_TREE_4     EQU 4
+DEF FRUIT_TREE_5_MAX EQU 5
```

## 2. Add the Random Amount of Found Berries to the Bag, and Print the Amount

In my example ranges provided, we can find either 3, 4, or 5 berries. So, after calling our new custom function ```GetFruitTreeCount``` we check the amount we got. In each case, we use ```giveitem ITEM_FROM_MEM, #``` to attemtp to give that amount into the bag. Using ```iffalse``` we can determine if ```giveitem``` failed, which should only ever happen if you would end up having more than 99 of the berry.


Going all the way down to 2, 1 and then 0, we will attempt to give one less berry to see if that will fit in the bag.

Keep this in mind if you make your own ranges, you need to add code to account for each amount from whatever you want ```FRUIT_TREE_#_MAX``` to be set to, all the way to 0.

Edit [engine\events\fruit_trees.asm](../blob/master/engine/events/fruit_trees.asm):
```diff
.fruit
-	writetext HeyItsFruitText
+	farwritetext _HeyItsFruitText
+	callasm GetFruitTreeCount
+	ifequal FRUIT_TREE_3_MIN, .try_three
+	ifequal FRUIT_TREE_4, .try_four
+	; only possible value left it could be is FRUIT_TREE_5_MAX
+	readmem wCurFruit
+	giveitem ITEM_FROM_MEM, $5
+	iffalse .try_four
+	promptbutton
+	writetext ObtainedFiveFruitText
+	sjump .continue
+.try_four
+	readmem wCurFruit
+	giveitem ITEM_FROM_MEM, $4
+	iffalse .try_three
+	promptbutton
+	writetext ObtainedFourFruitText
+	sjump .continue
+.try_three
+	readmem wCurFruit
+	giveitem ITEM_FROM_MEM, $3
+	iffalse .try_two
+	promptbutton
+	writetext ObtainedThreeFruitText
+	sjump .continue
+.try_two
+; if you somehow approach the limit of number of a single berry
+; and 3-5 will not fit in the bag but 2 will, it prints the "bag is full" text to let you know
+; but still gives you the 2 berry too
+; if 2 still wont fit, try 1
+	readmem wCurFruit
+	giveitem ITEM_FROM_MEM, $2
+	iffalse .try_one
+	promptbutton
+	writetext FruitPackIsFullText
+	promptbutton
+	writetext ObtainedTwoFruitText
+	sjump .continue
+.try_one
+; if you somehow approach the limit of number of a single berry
+; and 3-5 will not fit in the bag but 1 will, it prints the "bag is full" text to let you know
+; but still gives you the 1 berry too
+; if not even one berry will fit, print "bag is full text" and do not print ObtainedFruitText 
	readmem wCurFruit
	giveitem ITEM_FROM_MEM
	iffalse .packisfull
	promptbutton
+	writetext FruitPackIsFullText
+	promptbutton
	writetext ObtainedFruitText
+.continue
	callasm PickedFruitTree
	specialsound
	itemnotify
	sjump .end
```
## 3. Add Function to Determine Amount of Fruit that will be found

If we want to be able to find between 3 and 5 berries, we need ```call RandomRange``` to return a random number between 0 and 2, and then ```add 3``` (3 being our minamum amount possible to find) to this random number. 

```RandomRange``` uses ```a``` to determine the range of random numbers to return, also in ```a```. The range must start with 0, so ```a``` must be set to the non-inclusive end of the range. Since the max we want is 2, we are setting ```a``` to 3. 

We are also adding 3 to the result of ```call RandomRange```.

This is so that if ```call RandomRange``` returns 0, we will be finding 3 berries.
If ```call RandomRange``` returns 1, we will be finding 4 berries.
If ```call RandomRange``` returns 2, we will be finding 5 berries.

Edit [engine\events\fruit_trees.asm](../blob/master/engine/events/fruit_trees.asm):
```diff
+GetFruitTreeCount:
+; RandomRange returns a random number between 0 and 2
+; the range is in a, not inclusive
+; We want a possible range of 3-5 so we add 3 after
+	ld a, 3
+	call RandomRange
+	add 3
+	ld [wScriptVar], a
+	ret
+
GetCurTreeFruit:
```
## 4. Add New Text For Each Amount of Fruit Possible

First, go to towards the end of fruit_trees.asm and add the local references to our new text.

Edit [engine\events\fruit_trees.asm](../blob/master/engine/events/fruit_trees.asm):
```diff
	text_far _ObtainedFruitText
	text_end
+
+ObtainedTwoFruitText:
+	text_far _ObtainedTwoFruitText
+	text_end
+
+ObtainedThreeFruitText:
+	text_far _ObtainedThreeFruitText
+	text_end
+
+ObtainedFourFruitText:
+	text_far _ObtainedFourFruitText
+	text_end
+
+ObtainedFiveFruitText:
+	text_far _ObtainedFiveFruitText
+	text_end
+
FruitPackIsFullText:
```

And then, to add the actual text, edit [data\text\common_1.asm](../blob/master/data/text/common_1.asm):

```diff
_HeyItsFruitText::
-	text "Hey! It's"
+	text "Hey! Found"
	line "@"
	text_ram wStringBuffer3
-	text "!"
+	text "S!"
	done

_ObtainedFruitText::
	text "Obtained"
	line "@"
	text_ram wStringBuffer3
	text "!"
	done
+_ObtainedTwoFruitText::
+	text "Obtained two"
+	line "@"
+	text_ram wStringBuffer3
+	text "S!"
+	done
+_ObtainedThreeFruitText::
+	text "Obtained three"
+	line "@"
+	text_ram wStringBuffer3
+	text "S!"
+	done
+
+_ObtainedFourFruitText::
+	text "Obtained four"
+	line "@"
+	text_ram wStringBuffer3
+	text "S!"
+	done
+
+_ObtainedFiveFruitText::
+	text "Obtained five"
+	line "@"
+	text_ram wStringBuffer3
+	text "S!"
+	done
+
_FruitPackIsFullText::
```

That's it!
Let me know if you have any questions, you can find me in the discord server.


