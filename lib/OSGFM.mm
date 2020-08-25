// OSGFM.cpp

#include <osgfm/OSGFM.h>

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MTKView.h>

#include <optional>
#include <utility>

@interface View : MTKView<NSWindowDelegate, MTKViewDelegate> {
    osgfm::DrawFunction d_draw_function;
    osgfm::MouseEventFunction d_mouse_event_function;
    osgfm::KeyboardEventFunction d_keyboard_event_function;
    simd::float2 d_mouse_move_client_position;
}
- (id) initWithFrame: (NSRect)frame device: (id<MTLDevice>)device;
- (void) setDrawFunction: (osgfm::DrawFunction)function;
- (void) setMouseEventFunction: (osgfm::MouseEventFunction)function;
- (void) setKeyboardEventFunction: (osgfm::KeyboardEventFunction)function;
- (void) mouseDraggedImpl: (NSEvent *)event;
- (void) mouseDownImpl: (NSEvent *)event;
- (void) mouseUpImpl: (NSEvent *)event;
@end

@implementation View
- (id) initWithFrame: (NSRect)frame device: (id<MTLDevice>)device
{
    [super initWithFrame: frame device: device];
    [super setDelegate: self];

    return self;
}

// `NSWindowDelegate` overrides:
- (void) windowWillClose: (NSNotification *)notification
{
    [NSApp stop: self];
}

// `MTKViewDelegate` overrides:
- (void) mtkView: (MTKView *)s_view drawableSizeWillChange: (CGSize)size
{
    //llair_example_resize(size);
}

- (void) drawInMTKView: (MTKView *)s_view
{
    if (!d_draw_function) {
        return;
    }

    d_draw_function(s_view.currentDrawable, s_view.currentDrawable.texture);
}

// `NSResponder` overrides:
- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseMoved: (NSEvent *)event
{
    auto client_position = [event locationInWindow];

    auto last_mouse_move_client_position = std::exchange(
        d_mouse_move_client_position, simd::float2{ (float)client_position.x, (float)client_position.y });

    if (!d_mouse_event_function) {
        return;
    }

    auto buttons = [NSEvent pressedMouseButtons];
    auto screen_position = [NSEvent mouseLocation];

    d_mouse_event_function({
        osgfm::MouseEvent::Move{ d_mouse_move_client_position - last_mouse_move_client_position },
        (unsigned)buttons,
        simd::float2{ (float)screen_position.x, (float)screen_position.y },
        d_mouse_move_client_position
    });
}

- (void)mouseDraggedImpl: (NSEvent *)event
{
    auto client_position = [event locationInWindow];

    auto last_mouse_move_client_position = std::exchange(
        d_mouse_move_client_position, simd::float2{ (float)client_position.x, (float)client_position.y });

    if (!d_mouse_event_function) {
        return;
    }

    auto buttons = [NSEvent pressedMouseButtons];
    auto screen_position = [NSEvent mouseLocation];

    d_mouse_event_function({
        osgfm::MouseEvent::Move{ d_mouse_move_client_position - last_mouse_move_client_position },
        (unsigned)buttons,
        simd::float2{ (float)screen_position.x, (float)screen_position.y },
        d_mouse_move_client_position
    });
}

- (void)mouseDownImpl: (NSEvent *)event
{
    if (!d_mouse_event_function) {
        return;
    }

    auto buttons = [NSEvent pressedMouseButtons];
    auto screen_position = [NSEvent mouseLocation];

    d_mouse_event_function({
        osgfm::MouseEvent::ButtonDown{ (unsigned)[event buttonNumber] },
        (unsigned)buttons,
        simd::float2{ (float)screen_position.x, (float)screen_position.y },
        d_mouse_move_client_position
    });
}

- (void)mouseUpImpl: (NSEvent *)event
{
    if (!d_mouse_event_function) {
        return;
    }

    auto buttons = [NSEvent pressedMouseButtons];
    auto screen_position = [NSEvent mouseLocation];

    d_mouse_event_function({
        osgfm::MouseEvent::ButtonUp{ (unsigned)[event buttonNumber] },
        (unsigned)buttons,
        simd::float2{ (float)screen_position.x, (float)screen_position.y },
        d_mouse_move_client_position
    });
}

- (void)mouseDragged: (NSEvent *)event
{
    [self mouseDraggedImpl: event];
}

- (void)mouseDown: (NSEvent *)event
{
    [self mouseDownImpl: event];
}

- (void)mouseUp: (NSEvent *)event
{
    [self mouseUpImpl: event];
}

- (void)rightMouseDragged: (NSEvent *)event
{
    [self mouseDraggedImpl: event];
}

- (void)rightMouseDown: (NSEvent *)event
{
    [self mouseDownImpl: event];
}

- (void)rightMouseUp: (NSEvent *)event
{
    [self mouseUpImpl: event];
}

- (void)otherMouseDragged: (NSEvent *)event
{
    [self mouseDraggedImpl: event];
}

- (void)otherMouseDown: (NSEvent *)event
{
    [self mouseDownImpl: event];
}

- (void)otherMouseUp: (NSEvent *)event
{
    [self mouseUpImpl: event];
}

- (void)keyDown: (NSEvent *)event
{
    if (!d_keyboard_event_function) {
        return;
    }

    auto code = [event keyCode];
    auto key = [event characters];

    d_keyboard_event_function({
        osgfm::KeyboardEvent::KeyDown{},
        code,
        std::string([key UTF8String])
    });
}

- (void)keyUp: (NSEvent *)event
{
    if (!d_keyboard_event_function) {
        return;
    }

    auto code = [event keyCode];
    auto key = [event characters];

    d_keyboard_event_function({
        osgfm::KeyboardEvent::KeyUp{},
        code,
        std::string([key UTF8String])
    });
}

// Public methods:
- (void) setDrawFunction: (osgfm::DrawFunction) function
{
    d_draw_function = function;
}

- (void) setMouseEventFunction: (osgfm::MouseEventFunction) function
{
    d_mouse_event_function = function;
}

- (void) setKeyboardEventFunction: (osgfm::KeyboardEventFunction) function
{
    d_keyboard_event_function = function;
}
@end

namespace osgfm {

namespace {

id<MTLDevice> s_device;
NSWindow *s_window;
View *s_view;

void Cleanup() {
    [s_device release];
    [s_view release];
    [s_window release];
}

}

id<MTLDevice>
Initialize(unsigned width, unsigned height) {
    @autoreleasepool {
        [NSApplication sharedApplication];

        [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps: YES];

        // Create the s_window:
        auto window_style = NSWindowStyleMaskTitled    |
                            NSWindowStyleMaskClosable  |
                            NSWindowStyleMaskResizable;

        auto window_rect = NSMakeRect(0, 0, width, height);

        s_window = [[NSWindow alloc] initWithContentRect: window_rect
                       styleMask: window_style
                       backing: NSBackingStoreBuffered
                       defer: NO];

        [s_window setAcceptsMouseMovedEvents: YES];
        [s_window center];

        // Initialize Metal:
        s_device = MTLCreateSystemDefaultDevice();

        // Create the MTKView:
        s_view = [[View alloc] initWithFrame: window_rect device: s_device];

        s_view.framebufferOnly = NO;
        [s_window setContentView: s_view];
        [s_window setDelegate: s_view];

        [s_window makeKeyAndOrderFront: nil];

        [s_window retain];
        [s_device retain];
        [s_view retain];

        atexit(Cleanup);
    }

    return s_device;
}

id<MTLDevice> GetDevice() {
    return s_device;
}

NSWindow *GetWindow() {
    return s_window;
}

MTKView *GetView() {
    return s_view;
}

void SetDrawFunction(DrawFunction draw_function) {
    [s_view setDrawFunction: draw_function];
}

void SetMouseEventFunction(MouseEventFunction mouse_event_function) {
    [s_view setMouseEventFunction: mouse_event_function];
}

void SetKeyboardEventFunction(KeyboardEventFunction mouse_event_function) {
    [s_view setKeyboardEventFunction: mouse_event_function];
}

void
Run() {
    @autoreleasepool {
        [NSApp run];
    }
}

void
Exit() {
    [NSApp stop: nil];
}

} // End namespace osgfm