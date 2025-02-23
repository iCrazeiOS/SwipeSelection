// **************************************************** //
// **************************************************** //
// **********        Design outline          ********** //
// **************************************************** //
// **************************************************** //
//
// 1 finger moves the cursour
// 2 fingers moves it one word at a time
//
// Should be able to move between 1 and 2 fingers without lifting your hand.
// If a selection has been made and you move right the selection starts moving from the end.
// - else it starts at the beginning.
//
// Holding shift selects text between the starting point and the destination.
// - the starting point is the reverse of the non selection movement.
// - - movement to the right starts at the start of existing selections.
//
// Movement upwards when in 2 finger mode should jump to the nearest word in the new line.
// - But another movement up again (without sideways movement) will jump to the nearest word to the originals x location,
// - - this ensures that the cursour doesn't jump about moving far away from it's start point.
//

#import "Tweak.h"

%hook UIKeyboardImpl
%property (nonatomic,strong) UIPanGestureRecognizer *SS_pan;

-(id)initWithFrame:(CGRect)rect {
	id orig = %orig;

	if (orig) {
		SSPanGestureRecognizer *pan = [[SSPanGestureRecognizer alloc] initWithTarget:self action:@selector(SS_KeyboardGestureDidPan:)];
		pan.cancelsTouchesInView = NO;
		[self addGestureRecognizer:pan];
		[self setSS_pan:pan];
	}

	return orig;
}

-(instancetype)initWithFrame:(CGRect)arg1 forCustomInputView:(BOOL)arg2 {
	id orig = %orig;

	if (orig) {
		SSPanGestureRecognizer *pan = [[SSPanGestureRecognizer alloc] initWithTarget:self action:@selector(SS_KeyboardGestureDidPan:)];
		pan.cancelsTouchesInView = NO;
		[self addGestureRecognizer:pan];
		[self setSS_pan:pan];
	}

	return orig;
}

%new
-(void)SS_KeyboardGestureDidPan:(UIPanGestureRecognizer *)gesture {
	// Location info (may change)
	static UITextRange *startingtextRange = nil;
	static CGPoint previousPosition;

	// Webview fix
	static CGFloat xOffset = 0;
	static CGPoint realPreviousPosition;

	// Basic info
	static BOOL shiftHeldDown = NO;
	static BOOL hasStarted = NO;
	static BOOL longPress = NO;
	static BOOL handWriting = NO;
	static BOOL haveCheckedHand = NO;
	static BOOL isFirstShiftDown = NO; // = first run of the code shift is held, then pick the pivot point
	static BOOL isMoreKey = NO;
	static BOOL isKanaKey = NO;
	static int touchesWhenShiting = 0;
	static BOOL cancelled = NO;

	int touchesCount = [gesture numberOfTouches];

	UIKeyboardImpl *keyboardImpl = self;

	if ([keyboardImpl respondsToSelector:@selector(isLongPress)]) {
		BOOL nLongTouch = [keyboardImpl isLongPress];
		if (nLongTouch) {
			longPress = nLongTouch;
		}
	}

	// Get current layout
	id currentLayout = nil;
	if ([keyboardImpl respondsToSelector:@selector(_layout)]) {
		currentLayout = [keyboardImpl _layout];
	}

	// Check more key, unless it's already ues
	if (!isMoreKey && [currentLayout respondsToSelector:@selector(SS_disableSwipes)]) {
		isMoreKey = [currentLayout SS_disableSwipes];
	}

	// Hand writing recognition
	if (!haveCheckedHand && [currentLayout respondsToSelector:@selector(handwritingPlane)]) {
		handWriting = [currentLayout handwritingPlane];
	} else if (!handWriting && !haveCheckedHand && [currentLayout respondsToSelector:@selector(subviews)]) {
		NSArray *subviews = [((UIView *)currentLayout) subviews];
		for (UIView *subview in subviews) {

			if ([subview respondsToSelector:@selector(subviews)]) {
				NSArray *arrayToCheck = [subview subviews];

				for (id view in arrayToCheck) {
					NSString *classString = [NSStringFromClass([view class]) lowercaseString];
					if ([classString rangeOfString:@"handwriting"].location != NSNotFound) {
						handWriting = YES;
						break;
					}
				}
			}
		}
		haveCheckedHand = YES;
	}
	haveCheckedHand = YES;

	// Check for shift key being pressed
	if ([currentLayout respondsToSelector:@selector(SS_shouldSelect)] && !shiftHeldDown) {
		shiftHeldDown = [currentLayout SS_shouldSelect];
		isFirstShiftDown = YES;
		touchesWhenShiting = touchesCount;
	}

	if ([currentLayout respondsToSelector:@selector(SS_isKanaKey)]) {
		isKanaKey = [currentLayout SS_isKanaKey];
	}

	// Get the text input
	id <UITextInputPrivate> privateInputDelegate = nil;
	if ([keyboardImpl respondsToSelector:@selector(privateInputDelegate)]) {
		privateInputDelegate = (id)keyboardImpl.privateInputDelegate;
	}
	if (!privateInputDelegate && [keyboardImpl respondsToSelector:@selector(inputDelegate)]) {
		privateInputDelegate = (id)keyboardImpl.inputDelegate;
	}

	// Viber custom text view, which is super buggy with the tockenizer stuff.
	if (privateInputDelegate != nil && [NSStringFromClass([privateInputDelegate class]) isEqualToString:@"VBEmoticonsContentTextView"]) {
		privateInputDelegate = nil;
		cancelled = YES; // Try disabling it
	}

	//
	// Start Gesture stuff
	//
	if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
		if (hasStarted) {
			if ([privateInputDelegate respondsToSelector:@selector(selectedTextRange)]) {
				UITextRange *range = [privateInputDelegate selectedTextRange];
				if (range && !range.empty) {
					UITextInteractionAssistant *assistant = [(UIResponder *)privateInputDelegate interactionAssistant];
					if (assistant) {
						[[assistant selectionView] showCalloutBarAfterDelay:0];
					} else {
						CGRect screenBounds = [UIScreen mainScreen].bounds;
						CGRect rect = CGRectMake(screenBounds.size.width * 0.5, screenBounds.size.height * 0.5, 1, 1);

						if ([privateInputDelegate respondsToSelector:@selector(firstRectForRange:)]) {
							rect = [privateInputDelegate firstRectForRange:range];
						}

						UIView *view = nil;
						if ([privateInputDelegate isKindOfClass:[UIView class]]) {
							view = (UIView *)privateInputDelegate;
						} else if ([privateInputDelegate respondsToSelector:@selector(inputDelegate)]) {
							id v = [keyboardImpl inputDelegate];
							if (v != privateInputDelegate) {
								if ([v isKindOfClass:[UIView class]]) {
									view = (UIView *)v;
								}
							}
						}
						// Should fix this to actually get the onscreen rect
						UIMenuController *menu = [UIMenuController sharedMenuController];
						[menu setTargetRect:rect inView:view];
						[menu setMenuVisible:YES animated:YES];
					}
				}
			}

			// Tell auto correct/suggestions the cursor has moved
			if ([keyboardImpl respondsToSelector:@selector(updateForChangedSelection)]) {
				[keyboardImpl updateForChangedSelection];
			}
		}

		shiftHeldDown = NO;
		isMoreKey = NO;
		longPress = NO;
		hasStarted = NO;
		handWriting = NO;
		haveCheckedHand = NO;
		cancelled = NO;

		touchesCount = 0;
		touchesWhenShiting = 0;
		gesture.cancelsTouchesInView = NO;
	} else if (longPress || handWriting || !privateInputDelegate || isMoreKey || isKanaKey || cancelled) {
		return;
	} else if (gesture.state == UIGestureRecognizerStateBegan) {
		xOffset = 0;

		previousPosition = [gesture locationInView:self];
		realPreviousPosition = previousPosition;

		if ([privateInputDelegate respondsToSelector:@selector(selectedTextRange)]) {
			startingtextRange = [privateInputDelegate selectedTextRange];
		}
	} else if (gesture.state == UIGestureRecognizerStateChanged) {
		UITextRange *currentRange = startingtextRange;
		if ([privateInputDelegate respondsToSelector:@selector(selectedTextRange)]) {
			currentRange = nil;
			currentRange = [privateInputDelegate selectedTextRange];
		}

		CGPoint position = [gesture locationInView:self];
		CGPoint delta = CGPointMake(position.x - previousPosition.x, position.y - previousPosition.y);

		// Should we even run?
		CGFloat deadZone = 18;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			deadZone = 30;
		}

		// If hasn't started, and it's either moved to little or the user swiped up (accents) kill it.
		if (hasStarted == NO && ABS(delta.y) > deadZone) {
			if (ABS(delta.y) > ABS(delta.x)) {
				cancelled = YES;
			}
		}
		if ((hasStarted == NO && delta.x < deadZone && delta.x > (-deadZone)) || cancelled) {
			return;
		}

		// We are running so shut other things off/down
		gesture.cancelsTouchesInView = YES;
		hasStarted = YES;

		// Make x & y positive for comparision
		CGFloat positiveX = ABS(delta.x);

		// Determine the direction it should be going in
		UITextDirection textDirection = delta.x < 0 ? UITextStorageDirectionBackward : UITextStorageDirectionForward;

		// Only do these new big 'jumps' if we've moved far enough
		CGFloat xMinimum = 10;

		CGFloat neededTouches = 2;
		if (shiftHeldDown && (touchesWhenShiting >= 2)) {
			neededTouches = 3;
		}

		UITextGranularity granularity = UITextGranularityCharacter;
		// Handle different touches
		if (touchesCount >= neededTouches) {
			// make it skip words
			granularity = UITextGranularityWord;
			xMinimum = 20;
		}

		// Should we move the cusour or extend the current range.
		BOOL extendRange = shiftHeldDown;

		static UITextPosition *pivotPoint = nil;

		// Get the new range
		UITextPosition *positionStart = currentRange.start;
		UITextPosition *positionEnd = currentRange.end;

		// The moving position is
		UITextPosition *_position = nil;

		// If this is the first run we are selecting then pick our pivot point
		if (isFirstShiftDown) {
			if (delta.x > 0 || delta.y < -20) {
				pivotPoint = positionStart;
			} else {
				pivotPoint = positionEnd;
			}
		}

		if (extendRange && pivotPoint) {
			// Find which position isn't our pivot and move that.
			BOOL startIsPivot = KH_positionsSame(privateInputDelegate, pivotPoint, positionStart);
			_position = (startIsPivot) ? positionEnd : positionStart;
		} else {
			_position = (delta.x > 0) ? positionEnd : positionStart;
			if (!pivotPoint) pivotPoint = _position;
		}

		// Is it right to left at the current selection point?
		if ([privateInputDelegate baseWritingDirectionForPosition:_position inDirection:UITextStorageDirectionForward] == UITextWritingDirectionRightToLeft) {
			// Flip the direction
			if (textDirection == UITextStorageDirectionForward) textDirection = UITextStorageDirectionBackward;
			else textDirection = UITextStorageDirectionForward;
		}

		// Try and get the tockenizer
		id <UITextInputTokenizer, UITextInput> tokenizer = nil;
		if ([privateInputDelegate respondsToSelector:@selector(positionFromPosition:toBoundary:inDirection:)]) {
			tokenizer = privateInputDelegate;
		} else if ([privateInputDelegate respondsToSelector:@selector(tokenizer)]) {
			tokenizer = (id <UITextInput, UITextInputTokenizer>)privateInputDelegate.tokenizer;
		}

		if (tokenizer) {
			// Move X
			if (positiveX >= 1) {
				UITextPosition *_position_old = _position;

				_position = KH_tokenizerMovePositionWithGranularitInDirection(tokenizer, _position, granularity, textDirection);

				// If I tried to move it and got nothing back reset it to what I had.
				if (!_position) _position = _position_old;

				// If I tried to move it a word at a time and nothing happened
				if (granularity == UITextGranularityWord && (KH_positionsSame(privateInputDelegate, currentRange.start, _position) && !KH_positionsSame(privateInputDelegate, privateInputDelegate.beginningOfDocument, _position))) {
					_position = KH_tokenizerMovePositionWithGranularitInDirection(tokenizer, _position, UITextGranularityCharacter, textDirection);
					xMinimum = 4;
				}

				// Another sanity check
				if (!_position || positiveX < xMinimum) _position = _position_old;
			}
		}

		if (!extendRange && _position) pivotPoint = _position;

		// Get a new text range
		UITextRange *textRange = startingtextRange = nil;
		if ([privateInputDelegate respondsToSelector:@selector(textRangeFromPosition:toPosition:)]) {
			if ([privateInputDelegate comparePosition:_position toPosition:pivotPoint] == NSOrderedAscending) {
				textRange = [privateInputDelegate textRangeFromPosition:_position toPosition:pivotPoint];
			} else {
				textRange = [privateInputDelegate textRangeFromPosition:pivotPoint toPosition:_position];
			}
		}

		CGPoint oldPrevious = previousPosition;
		// Should I change X?
		if (positiveX > xMinimum) previousPosition = position;

		isFirstShiftDown = NO;

		//
		// Handle Safari's broken UITextInput support
		//
		BOOL webView = [NSStringFromClass([privateInputDelegate class]) isEqualToString:@"WKContentView"];
		if (webView) {
			xOffset += (position.x - realPreviousPosition.x);

			if (ABS(xOffset) >= xMinimum) {
				BOOL positive = (xOffset > 0);
				int offset = (ABS(xOffset) / xMinimum);
				BOOL isSelecting = pivotPoint != _position;

				for (int i = 0; i < offset; i++) {
					if (positive) {
						[(WKContentView *)privateInputDelegate _moveRight:isSelecting withHistory:nil];
					} else {
						[(WKContentView *)privateInputDelegate _moveLeft:isSelecting withHistory:nil];
					}
				}

				xOffset += (positive ? -(offset * xMinimum) : (offset * xMinimum));
			}
			[self SS_revealSelection:(UIView *)privateInputDelegate];
		}

		//
		// Normal text input
		//
		if (textRange && (oldPrevious.x != previousPosition.x || oldPrevious.y != previousPosition.y)) {
			[privateInputDelegate setSelectedTextRange:textRange];
			[self SS_revealSelection:(UIView *)privateInputDelegate];
		}

		realPreviousPosition = position;
	}
}

%new
-(void)SS_revealSelection:(UIView *)inputView {
	UIFieldEditor *fieldEditor = [objc_getClass("UIFieldEditor") sharedFieldEditor];
	if (fieldEditor && [fieldEditor respondsToSelector:@selector(revealSelection)]) {
		[fieldEditor revealSelection];
	}

	if ([inputView respondsToSelector:@selector(_scrollRectToVisible:animated:)]) {
		if ([inputView respondsToSelector:@selector(caretRect)]) {
			CGRect caretRect = [inputView caretRect];
			[inputView _scrollRectToVisible:caretRect animated:NO];
		}
	} else if ([inputView respondsToSelector:@selector(scrollSelectionToVisible:)]) {
		[inputView scrollSelectionToVisible:YES];
	}
}

%end


%hook UIKeyboardLayoutStar
/*==============touchesBegan================*/
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];

	UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
	NSString *key = [[keyObject representedString] lowercaseString];

	isDeleteKey = [key isEqualToString:@"delete"];
	isMoreKey = [key isEqualToString:@"more"];
	isKanaKey = [kanaKeys containsObject:key];

	g_deleteOnlyOnce = NO;

	%orig;
}

/*==============touchesMoved================*/
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];

	UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
	NSString *key = [[keyObject representedString] lowercaseString];

	// Delete key (or the arabic key which is where the shift key would be)
	if ([key isEqualToString:@"delete"] || [key isEqualToString:@"ء"]) {
		shiftByOtherKey = YES;
	}

	isMoreKey = [key isEqualToString:@"more"];

	%orig;
}

-(void)touchesCancelled:(id)arg1 withEvent:(id)arg2 {
	%orig;

	shiftByOtherKey = NO;
	isLongPressed = NO;
	isMoreKey = NO;
}

/*==============touchesEnded================*/
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	%orig;

	isDeleteKey = NO;

	UITouch *touch = [touches anyObject];
	NSString *key = [[[self keyHitTest:[touch locationInView:touch.view]] representedString] lowercaseString];

	// Delete key
	if ([key isEqualToString:@"delete"] && !isLongPressed && !isKanaKey) {
		g_deleteOnlyOnce = YES;
		g_availableDeleteTimes = 1;
		UIKeyboardImpl *kb = [UIKeyboardImpl activeInstance];
		if ([kb respondsToSelector:@selector(handleDelete)]) {
			[kb handleDelete];
		} else if ([kb respondsToSelector:@selector(handleDeleteAsRepeat:)]) {
			[kb handleDeleteAsRepeat:NO];
		} else if ([kb respondsToSelector:@selector(handleDeleteWithNonZeroInputCount)]) {
			[kb handleDeleteWithNonZeroInputCount];
		}
	}

	shiftByOtherKey = NO;
	isLongPressed = NO;
	isMoreKey = NO;
}

%new
-(BOOL)SS_shouldSelect {
	return ([self isShiftKeyBeingHeld] || shiftByOtherKey);
}

%new
-(BOOL)SS_disableSwipes {
	return isMoreKey;
}

%new
-(BOOL)SS_isKanaKey {
	return isKanaKey;
}
%end


%hook UIKeyboardImpl
// Doesn't work to get long press on delete key but does for other keys.
-(BOOL)isLongPress {
	isLongPressed = %orig;
	return isLongPressed;
}

// Legacy support (doesn't effect iOS 7 + so harmless leaving in & helps iOS 6)
-(void)handleDelete {
	if (!(!isLongPressed && isDeleteKey)) %orig;
}

-(void)handleDeleteAsRepeat:(BOOL)repeat executionContext:(UIKeyboardTaskExecutionContext *)executionContext {
	// Long press is simply meant to indicate if it's should repeat delete so repeat will do.
	isLongPressed = repeat;
	if ((!isLongPressed && isDeleteKey) || (g_deleteOnlyOnce && g_availableDeleteTimes <= 0)) {
		if ([[self _layout] respondsToSelector:@selector(idiom)]) {
			if ([(UIKeyboardLayout *)[self _layout] idiom] == 2) {
				[[UIDevice currentDevice] _playSystemSound:1123LL];
			} else {
				if (IS_IOS_OR_NEWER(iOS_16_0)) [self playDeleteKeyFeedbackRepeat:repeat rapid:NO];
				else if (IS_IOS_OR_NEWER(iOS_14_0)) [self playDeleteKeyFeedback:repeat];
				else if (IS_IOS_OR_NEWER(iOS_13_0)) [self playKeyClickSound:repeat];
				else if (IS_IOS_OR_NEWER(iOS_11_0)) [[self feedbackGenerator] _playFeedbackForActionType:3 withCustomization:nil];
				else if (IS_IOS_OR_NEWER(iOS_10_0)) [[self feedbackBehavior] _playFeedbackForActionType:3 withCustomization:nil];
			}
		}
		[[executionContext executionQueue] finishExecution];
		return;
	}

	if (g_deleteOnlyOnce) g_availableDeleteTimes--;

	%orig;
}
%end


%hook _UIKeyboardTextSelectionInteraction
-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	id delegate = [[self owner] delegate];
	if ([delegate respondsToSelector:@selector(SS_pan)] && [[delegate SS_pan] state] == UIGestureRecognizerStateChanged) return NO;
	return %orig;
}
%end


%ctor {
	NSString *path = [[NSProcessInfo processInfo] arguments][0];
	BOOL isApp = [path rangeOfString:@"/Application"].location != NSNotFound;
	BOOL isSpringBoard = [path rangeOfString:@"SpringBoard.app"].location != NSNotFound;
	if (isApp || isSpringBoard) {
		kanaKeys = [NSSet setWithArray:@[@"あ",@"か",@"さ",@"た",@"な",@"は",@"ま",@"や",@"ら",@"わ",@"、"]];
		%init;
	}
}
