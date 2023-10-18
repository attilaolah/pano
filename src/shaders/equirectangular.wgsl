struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) tex_coords: vec2<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
};

// Cycle through [0, 1] with the given phase and shift.
// Phase should not be zero. A phase of 1 yields [0, 1, 0, 1, …].
fn cycle_01(i: u32, phase: u32, shift: u32) -> u32 {
    return ((i + shift) / phase) & 1u;
}

// Re-scale [0, 1] to [-1.0, 1.0].
fn scale_01(i: u32) -> f32 {
    return f32(i32(i) * 2 - 1);
}

@vertex
fn vs_main(
    model: VertexInput,
) -> VertexOutput {
    var out: VertexOutput;
    out.tex_coords = model.tex_coords;
    out.clip_position = vec4<f32>(model.position, 1.0);
    return out;
}

@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(0) @binding(1)
var s_diffuse: sampler;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return textureSample(t_diffuse, s_diffuse, in.tex_coords);
}
