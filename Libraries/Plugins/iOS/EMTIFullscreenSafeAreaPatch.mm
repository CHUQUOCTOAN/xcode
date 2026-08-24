#if UNITY_IOS
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "PluginBase/AppDelegateListener.h"
#import "UnityAppController.h"
#import "UI/UnityView.h"
#import "Unity/UnityInterface.h"

static UIEdgeInsets EMTIUnityViewSafeAreaInsetsZero(id self, SEL _cmd)
{
    return UIEdgeInsetsZero;
}

@interface EMTIFullscreenSafeAreaPatch : NSObject<AppDelegateListener>
@end

@implementation EMTIFullscreenSafeAreaPatch

static EMTIFullscreenSafeAreaPatch* sFullscreenPatch;

+ (void)load
{
    sFullscreenPatch = [EMTIFullscreenSafeAreaPatch new];
    UnityRegisterAppDelegateListener(sFullscreenPatch);
}

- (void)didFinishLaunching:(NSNotification*)notification
{
    [self applyFullscreenPatchAsync];
}

- (void)didBecomeActive:(NSNotification*)notification
{
    [self applyFullscreenPatchAsync];
}

- (void)willEnterForeground:(NSNotification*)notification
{
    [self applyFullscreenPatchAsync];
}

- (void)applicationWillChangeStatusBarOrientation:(NSNotification*)notification
{
    [self applyFullscreenPatchAsync];
}

- (void)applyFullscreenPatchAsync
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self applyFullscreenPatchNow];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self applyFullscreenPatchNow];
        });
    });
}

- (void)applyFullscreenPatchNow
{
    [self installUnitySafeAreaOverride];

    UnityAppController* controller = GetAppController();
    UIWindow* window = controller.window;
    UIViewController* rootController = UnityGetGLViewController();
    UIView* unityView = UnityGetGLView();

    if (window == nil || unityView == nil)
    {
        return;
    }

    CGRect bounds = window.bounds;

    window.autoresizesSubviews = YES;

    if (rootController != nil)
    {
        rootController.additionalSafeAreaInsets = UIEdgeInsetsZero;
        if (rootController.view != nil)
        {
            rootController.view.frame = bounds;
            rootController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            rootController.view.layoutMargins = UIEdgeInsetsZero;
            if (@available(iOS 11.0, *))
            {
                rootController.view.insetsLayoutMarginsFromSafeArea = NO;
            }
        }
    }

    unityView.frame = bounds;
    unityView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    unityView.layoutMargins = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *))
    {
        unityView.insetsLayoutMarginsFromSafeArea = NO;
    }

    [window setNeedsLayout];
    [window layoutIfNeeded];
    [unityView setNeedsLayout];
    [unityView layoutIfNeeded];

    ReportSafeAreaChangeForView(unityView);
    [(UnityView*)unityView boundsUpdated];
}

- (void)installUnitySafeAreaOverride
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method safeAreaMethod = class_getInstanceMethod([UIView class], @selector(safeAreaInsets));
        const char* encoding = safeAreaMethod != nil ? method_getTypeEncoding(safeAreaMethod) : "{UIEdgeInsets=dddd}16@0:8";
        class_replaceMethod([UnityView class], @selector(safeAreaInsets), (IMP)EMTIUnityViewSafeAreaInsetsZero, encoding);
    });
}

@end
#endif
