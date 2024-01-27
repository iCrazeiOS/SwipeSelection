#import "SSPanGestureRecognizer.h"

@class UIKeyboardTaskExecutionContext;

@interface UIKeyboardTaskQueue : NSObject
@property(retain, nonatomic) UIKeyboardTaskExecutionContext *executionContext;
-(BOOL)isMainThreadExecutingTask;
-(void)performTask:(id)arg1;
-(void)waitUntilAllTasksAreFinished;
-(void)addDeferredTask:(id)arg1;
-(void)addTask:(id)arg1;
-(void)promoteDeferredTaskIfIdle;
-(void)performDeferredTaskIfIdle;
-(void)performTaskOnMainThread:(id)arg1 waitUntilDone:(void)arg2;
-(void)finishExecution;
-(void)continueExecutionOnMainThread;
-(void)unlock;
-(BOOL)tryLockWhenReadyForMainThread;
-(void)lockWhenReadyForMainThread;
-(void)lock;
@end

@interface UIKeyboardTaskExecutionContext : NSObject
@property(readonly, nonatomic) UIKeyboardTaskQueue *executionQueue;
-(void)transferExecutionToMainThreadWithTask:(id)arg1;
-(void)returnExecutionToParent;
-(id)childWithContinuation:(id)arg1;
-(id)initWithParentContext:(id)arg1 continuation:(id)arg2;
-(id)initWithExecutionQueue:(id)arg1;
@end

@protocol UITextInputPrivate <UITextInput, UITextInputTokenizer>
-(BOOL)shouldEnableAutoShift;
-(NSRange)selectionRange;
-(CGRect)rectForNSRange:(NSRange)nsrange;
-(NSRange)_markedTextNSRange;
-(void)moveBackward:(unsigned)backward;
-(void)moveForward:(unsigned)forward;
-(unsigned short)characterBeforeCaretSelection;
-(id)wordContainingCaretSelection;
-(id)wordRangeContainingCaretSelection;
-(id)markedText;
-(void)setMarkedText:(id)text;
-(BOOL)hasContent;
-(void)selectAll;
-(id)textColorForCaretSelection;
-(id)fontForCaretSelection;
-(BOOL)hasSelection;
@end

/** iOS 5-6 **/
@interface UIKBShape : NSObject
@end

@interface UIKBKey : UIKBShape
@property(copy) NSString * name;
@property(copy) NSString * representedString;
@property(copy) NSString * displayString;
@property(copy) NSString * displayType;
@property(copy) NSString * interactionType;
@property(copy) NSString * variantType;
@property(copy) NSString * overrideDisplayString;
@property(copy) NSString * clientVariantRepresentedString;
@property(copy) NSString * clientVariantActionName;
@property BOOL visible;
@property BOOL hidden;
@property BOOL disabled;
@property BOOL isGhost;
@property int splitMode;
@end

/** iOS 7 **/
@interface UIKBTree : NSObject <NSCopying>
@property(retain, nonatomic) NSString *layoutTag;
@property(retain, nonatomic) NSMutableDictionary *cache;
@property(retain, nonatomic) NSMutableArray *subtrees;
@property(retain, nonatomic) NSMutableDictionary *properties;
@property(retain, nonatomic) NSString *name;
@property(nonatomic) int type;
+(id)keyboard;
+(id)key;
+(id)shapesForControlKeyShapes:(id)arg1 options:(int)arg2;
+(id)mergeStringForKeyName:(id)arg1;
+(BOOL)shouldSkipCacheString:(id)arg1;
+(id)stringForType:(int)arg1;
+(id)treeOfType:(int)arg1;
+(id)uniqueName;
-(int)flickDirection;
-(BOOL)isLeafType;
-(BOOL)usesKeyCharging;
-(BOOL)usesAdaptiveKeys;
-(BOOL)modifiesKeyplane;
-(BOOL)avoidsLanguageIndicator;
-(BOOL)isAlphabeticPlane;
-(BOOL)noLanguageIndicator;
-(BOOL)isLetters;
-(BOOL)subtreesAreOrdered;
@end

@interface UIKeyboardLayout : UIView
-(UIKBKey *)keyHitTest:(CGPoint)point;
-(long long)idiom;
@end

@interface UIKeyboardLayoutStar : UIKeyboardLayout
-(id)keyHitTest:(CGPoint)arg1;
-(id)keyHitTestWithoutCharging:(CGPoint)arg1;
-(id)keyHitTestClosestToPoint:(CGPoint)arg1;
-(id)keyHitTestContainingPoint:(CGPoint)arg1;
-(BOOL)SS_shouldSelect;
-(BOOL)SS_disableSwipes;
-(BOOL)SS_isKanaKey;
-(BOOL)isShiftKeyBeingHeld;
-(void)deleteAction;
@end

@interface UIKeyboardImpl : UIView
@property (readonly, assign, nonatomic) UIResponder <UITextInputPrivate> *privateInputDelegate;
@property (readonly, assign, nonatomic) UIResponder <UITextInput> *inputDelegate;
@property (nonatomic,strong) UIPanGestureRecognizer *SS_pan;
@property (nonatomic,retain) id feedbackBehavior; // iOS 10
@property (nonatomic,retain) id feedbackGenerator; // iOS11 12
+(UIKeyboardImpl *)sharedInstance;
+(UIKeyboardImpl *)activeInstance;
-(BOOL)isLongPress;
-(id)_layout;
-(BOOL)callLayoutIsShiftKeyBeingHeld;
-(void)handleDelete;
-(void)handleDeleteAsRepeat:(BOOL)repeat;
-(void)handleDeleteWithNonZeroInputCount;
-(void)stopAutoDelete;
-(BOOL)handwritingPlane;
-(void)updateForChangedSelection;
-(void)playKeyClickSound:(BOOL)arg1; // iOS 13
-(void)playDeleteKeyFeedback:(BOOL)arg1; // iOS 14
-(void)playDeleteKeyFeedbackRepeat:(BOOL)arg1 rapid:(BOOL)arg2; // iOS 16
-(void)SS_revealSelection:(UIView *)inputView;
@end

@interface UIFieldEditor : NSObject
+(UIFieldEditor *)sharedFieldEditor;
-(void)revealSelection;
@end

@interface UIView (Private_text) <UITextInput>
-(void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;
-(void)scrollSelectionToVisible:(BOOL)visible;
-(CGRect)caretRect;
-(void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;
-(NSRange)selectedRange;
-(NSRange)selectionRange;
-(void)setSelectedRange:(NSRange)range;
-(void)setSelectionRange:(NSRange)range;
-(void)scrollSelectionToVisible:(BOOL)arg1;
-(CGRect)rectForSelection:(NSRange)range;
-(CGRect)textRectForBounds:(CGRect)rect;
@end

@interface WKContentView : UIView
-(void)moveByOffset:(NSInteger)offset;
-(id)_moveLeft:(BOOL)arg1 withHistory:(id)arg2;
-(id)_moveRight:(BOOL)arg1 withHistory:(id)arg2;
@end

@interface UIResponder()
-(id)interactionAssistant;
@end

@interface UITextInteractionAssistant : NSObject
-(id)selectionView;
@end

@interface UITextSelectionView
-(void)showCalloutBarAfterDelay:(double)arg1;
@end

@interface UIDevice()
-(void)_playSystemSound:(unsigned)arg1;
@end

@interface _UIKeyboardFeedbackGenerator : NSObject
-(void)_playFeedbackForActionType:(long long)arg1 withCustomization:(id)arg2;
@end

@interface _UIFeedbackKeyboardBehavior : NSObject
-(void)_playFeedbackForActionType:(long long)arg1 withCustomization:(id)arg2;
@end

@interface _UIKeyboardTextSelectionInteraction
-(id)owner;
@end

UITextPosition *KH_tokenizerMovePositionWithGranularitInDirection(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *startPosition, UITextGranularity granularity, UITextDirection direction) {
	if (tokenizer && startPosition) {
		return [tokenizer positionFromPosition:startPosition toBoundary:granularity inDirection:direction];
	}
	return nil;
}

BOOL KH_positionsSame(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *position1, UITextPosition *position2) {
	if ([tokenizer isKindOfClass:[NSClassFromString(@"WKContentView") class]]) return position1 == position2;
	return ([tokenizer comparePosition:position1 toPosition:position2] == NSOrderedSame);
}

static BOOL shiftByOtherKey = NO;
static BOOL isLongPressed = NO;
static BOOL isDeleteKey = NO;
static BOOL isMoreKey = NO;
static BOOL isKanaKey = NO;
static BOOL g_deleteOnlyOnce;
static int g_availableDeleteTimes;
static NSSet *kanaKeys;
