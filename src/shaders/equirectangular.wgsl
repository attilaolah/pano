// Simple equirectangular-to-rectilinear camera.

struct CameraUniform {
    theta: f32,
    phi: f32,
    fovy: f32,
    aspect: f32,
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

const PI: f32 = 3.14159265;
const TAU: f32 = 6.28318531;
const UP: vec3<f32> = vec3<f32>(0.0, 1.0, 0.0);

// Create a rotation matrix that rotates up/down, around the X axis.
fn rot_x(by: f32) -> mat3x3<f32> {
    let cby = cos(by);
    let sby = sin(by);

    return mat3x3<f32>(
        1.0, 0.0,  0.0,
        0.0, cby, -sby,
        0.0, sby,  cby,
    );
}

// Create a rotation matrix that rotates left/right, around the Y axis.
fn rot_y(by: f32) -> mat3x3<f32> {
    let cby = cos(by);
    let sby = sin(by);

    return mat3x3<f32>(
         cby, 0.0, sby,
         0.0, 1.0, 0.0,
        -sby, 0.0, cby,
    );
}

// Create a rotation matrix that rotates around any axis.
fn rot_around(axis: vec3<f32>, by: f32) -> mat3x3<f32> {
    let cby = cos(by);
    let sby = sin(by);
    let cbn = 1.0 - cby;

    let x = axis.x;
    let y = axis.y;
    let z = axis.z;

    // Only ChatGPT knows how this works.
    return mat3x3<f32>(
        cby + cbn * x * x,     cbn * x * y - sby * z, cbn * x * z + sby * y,
        cbn * y * x + sby * z, cby + cbn * y * y,     cbn * y * z - sby * x,
        cbn * z * x - sby * y, cbn * z * y + sby * x, cby + cbn * z * z,
    );
}

// Convert a direction to polar coordinates.
fn to_polar(dir: vec3<f32>) -> vec2<f32> {
    // Azimuthal angle (angle around the vertical axis).
    let phi = atan2(dir.z, dir.x);

    // Polar angle (angle around the horizontal axis).
    let theta = atan2(length(dir.xz), dir.y);

    return vec2<f32>(phi, theta);
}

@fragment
fn frag_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let u: f32 = in.tex_coords[0];
    let v: f32 = in.tex_coords[1];

    // Vertical field of view to maintain.
    // Hor+ scaling: the horizontal field of view changes depending on the aspect ratio.
    let f = 0.5 / tan(camera.fovy / 2.0);

    // Camera orientation.
    let cam_phi = rot_y(-camera.phi);
    let cam_theta = rot_x(camera.theta);
    let cam_rot = cam_phi * cam_theta;

    // The direction the camera is facing. The "zero" position is +z.
    let cam_dir = cam_rot * vec3<f32>(0.0, 0.0, 1.0);

    // Camera rotation axes.
    let cam_x = cam_rot * vec3<f32>(1.0, 0.0, 0.0);
    let cam_y = cam_rot * vec3<f32>(0.0, 1.0, 0.0);

    // Horizontal and vertictal angle from the camera direction.
    let a = atan((0.5 - u) * camera.aspect / f);
    let b = atan((0.5 - v) / f);

    // Rotate the camera direction towards the current pixel value.
    let dir = (rot_around(cam_x, b) * rot_around(cam_y, a)) * cam_dir;
    let dir_polar = to_polar(normalize(dir));

    let eqr_u = -degrees(dir_polar.x) / 360.0 + 0.75;
    let eqr_v = degrees(dir_polar.y) / 180.0;

    return textureSample(t_diffuse, s_diffuse, vec2<f32>(
        eqr_u,
        eqr_v,
    ));
}
