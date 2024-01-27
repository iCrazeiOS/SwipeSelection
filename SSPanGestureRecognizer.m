#import "SSPanGestureRecognizer.h"

@implementation SSPanGestureRecognizer
-(BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
	if ([preventingGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && (![NSStringFromClass([preventingGestureRecognizer class]) isEqualToString:@"AKFlickGestureRecognizer"])) {
		return YES;
	}
	return NO;
}

-(BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
	return NO;
}
@end
