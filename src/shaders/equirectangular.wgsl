struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
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
    @builtin(vertex_index) in_vertex_index: u32,
) -> VertexOutput {
    var out: VertexOutput;
    let x = scale_01(cycle_01(in_vertex_index, 1u, 0u));
    let y = scale_01(cycle_01(in_vertex_index, 3u, 2u));
    out.clip_position = vec4<f32>(x, y, 0.0, 1.0);
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return vec4<f32>(0.0, 1.0, 0.0, 1.0);
}
