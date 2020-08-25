#include <osgfm/OSGFM.h>

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#include <iostream>
#include <string>

namespace {

std::string s_triangle_metal = R"(// GPU functions for the `triangle` example

#include <metal_stdlib>

struct Vertex {
    metal::float2 position;
    metal::float4 color;
};

struct RasterizerData {
    metal::float4 position [[ position ]];
    metal::float4 color;
};

vertex RasterizerData
VertexMain(constant Vertex       *vertices [[ buffer(0) ]],
           constant metal::uint2 *viewport [[ buffer(1) ]],
           uint vertex_id                  [[ vertex_id ]]) {
    return {
        metal::float4(vertices[vertex_id].position.xy / float2(*viewport) / 2.0, 0.0, 1.0),
        vertices[vertex_id].color
    };
}

fragment float4
FragmentMain(RasterizerData rasterizer_data [[stage_in]]) {
    return rasterizer_data.color;
})";

} // End namespace

int
main(int argc, char **argv) {
@autoreleasepool {
    simd::uint2 size = { 960, 540 };

    osgfm::Initialize(size[0], size[1]);

    auto device = osgfm::GetDevice();
    auto queue = [device newCommandQueue];

    NSError *err = nil;

    auto source = [[NSString alloc] initWithBytesNoCopy: s_triangle_metal.data() length: s_triangle_metal.size() encoding: NSASCIIStringEncoding freeWhenDone: NO];
    auto library = [device newLibraryWithSource: source options: nil error: &err];

    if (!library) {
        std::cerr << "Error occurred when creating library: " << [err code] << std::endl;
        std::exit(-1);
    }

    auto pipeline_descriptor = [MTLRenderPipelineDescriptor new];

    auto vertex_function = [library newFunctionWithName: @"VertexMain"];

    if (!vertex_function) {
        std::cerr << "Failed to get vertex function" << std::endl;
        std::exit(-1);
    }

    pipeline_descriptor.vertexFunction = vertex_function;

    auto fragment_function = [library newFunctionWithName: @"FragmentMain"];

    if (!fragment_function) {
        std::cerr << "Failed to get fragment function" << std::endl;
        std::exit(-1);
    }

    pipeline_descriptor.fragmentFunction = fragment_function;

    pipeline_descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    //
    MTLAutoreleasedRenderPipelineReflection reflection;

    auto pipeline_state = [device newRenderPipelineStateWithDescriptor: pipeline_descriptor
                                   error: &err];

    if (!pipeline_state) {
        std::cerr << "Error occurred when creating pipeline: " << [err code] << std::endl;
        std::exit(-1);
    }

    osgfm::SetDrawFunction([size, queue, pipeline_state](id<MTLDrawable> drawable, id<MTLTexture> texture) -> void {
        auto render_pass = [MTLRenderPassDescriptor renderPassDescriptor];
        render_pass.colorAttachments[0].texture = texture;
        render_pass.colorAttachments[0].loadAction = MTLLoadActionClear;
        render_pass.colorAttachments[0].clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);

        auto command_buffer = [queue commandBuffer];
        auto command_encoder = [command_buffer renderCommandEncoderWithDescriptor: render_pass];

        struct Vertex {
            simd::float2 position;
            simd::float4 color;
        };

        static const Vertex vertices[] = {
            { {  250,  -250 }, { 1, 0, 0, 1 } },
            { { -250,  -250 }, { 0, 1, 0, 1 } },
            { {    0,   250 }, { 0, 0, 1, 1 } }
        };

        [command_encoder setRenderPipelineState: pipeline_state];

        [command_encoder setVertexBytes: &vertices[0]
                        length: sizeof(vertices)
                        atIndex: 0];

        [command_encoder setVertexBytes: &size
                        length: sizeof(simd::uint2)
                        atIndex: 1];

        [command_encoder drawPrimitives: MTLPrimitiveTypeTriangle
                        vertexStart: 0 vertexCount: 3];

        [command_encoder endEncoding];

        [command_buffer presentDrawable: drawable];
        [command_buffer commit];
    });

    osgfm::Run();
}
}