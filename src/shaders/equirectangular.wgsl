struct CameraUniform {
    view_proj: mat4x4<f32>,
};
@group(1) @binding(0)
var<uniform> camera: CameraUniform;

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
fn vert_main(
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

// Simple equirectangular-to-rectilinear camera.

// Theta rotates left-right around the vertical axis.
// Normalised to represent [-180°, 180°] as [-1.0, 1.0].
const THETA: f32 = 0.0;
// Phi rotates up/down around the horizontal axis.
// Normalised to represent [-90°, 90°] as [-1.0, 1.0].
const PHI: f32 = 0.0;
// The aspect ratio is simply width / height;
const aspect: f32 = 1.77777777; // = 16.0 / 9.0;

const PI: f32 = 3.14159265;
const TAU: f32 = 6.28318531;

// Convert normalised [-1., 1.] to UV [0, 1] space.
fn uv2(xy: vec2<f32>) -> vec2<f32> {
    return vec2<f32>((xy[0] + 1.0) / 2.0);
}

@fragment
fn frag_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let u: f32 = in.tex_coords[0];
    let v: f32 = in.tex_coords[1];

    // Vertical field of view to maintain.
    // Hor+ scaling: the horizontal field of view changes depending on the aspect ratio.
    let fovy: f32 = PI * 90.0 / 180.0;
    let f: f32 = 0.5 / tan(fovy / 2.0);
    let a: f32 = atan(-(0.5 - u) / f);
    let b: f32 = atan(-(0.5 - v) / f);
    //let eqr_u: f32 = 0.5 - (THETA + (a / TAU) * aspect);
    let eqr_u: f32 = (THETA + (a / TAU * aspect)) + 0.5;
    let eqr_v: f32 = (PHI + (b / PI)) + 0.5;

    return textureSample(t_diffuse, s_diffuse, vec2<f32>(
        eqr_u,
        eqr_v,
    ));
}
