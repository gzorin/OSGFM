#ifndef OSGFM_H
#define OSGFM_H

#include <functional>
#include <string>
#include <variant>

#import <Cocoa/Cocoa.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLDrawable.h>
#import <Metal/MTLTexture.h>
#import <MetalKit/MTKView.h>

#include <simd/simd.h>

namespace osgfm {

id<MTLDevice> Initialize(unsigned, unsigned);

id<MTLDevice> GetDevice();
NSWindow *GetWindow();
MTKView *GetView();

using DrawFunction = std::function<void(id<MTLDrawable>, id<MTLTexture>)>;

void SetDrawFunction(DrawFunction);

struct MouseEvent {
    struct Move { simd::float2 delta; };
    struct ButtonDown { unsigned button = 0; };
    struct ButtonUp { unsigned button = 0; };

    std::variant<Move, ButtonDown, ButtonUp> detail;

    unsigned buttons = 0;
    simd::float2 screen_position, client_position;
};

using MouseEventFunction = std::function<void(const MouseEvent&)>;

void SetMouseEventFunction(MouseEventFunction);

struct KeyboardEvent {
    struct KeyDown {};
    struct KeyUp {};

    std::variant<KeyDown, KeyUp> detail;

    unsigned code = 0;
    std::string key;
};

using KeyboardEventFunction = std::function<void(const KeyboardEvent&)>;

void SetKeyboardEventFunction(KeyboardEventFunction);

void Run();

void Exit();

} // End namespace osgfm

#endif
