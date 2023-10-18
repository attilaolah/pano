use cgmath::{Deg, Matrix4, Point3, Vector3};

pub const OPENGL_TO_WGPU_MATRIX: cgmath::Matrix4<f32> = cgmath::Matrix4::new(
    1.0, 0.0, 0.0, 0.0, //
    0.0, 1.0, 0.0, 0.0, //
    0.0, 0.0, 0.5, 0.5, //
    0.0, 0.0, 0.0, 1.0, //
);

pub struct Camera {
    target: Point3<f32>,
    aspect: f32,
}

#[repr(C)]
#[derive(Debug, Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct CameraUniform {
    // We can't use cgmath with bytemuck directly.
    view_proj: [[f32; 4]; 4],
}

impl Camera {
    pub fn new(target: Point3<f32>, aspect: f32) -> Self {
        Self { target, aspect }
    }
    fn view_projection_matrix(&self) -> Matrix4<f32> {
        const FOVY: f32 = 45.0;
        const ZNEAR: f32 = 0.1;
        const ZFAR: f32 = 100.0;

        let view = Matrix4::look_at_rh(
            // This camera is always at the origin.
            (0.0, 0.0, 0.0).into(),
            // Looking at the target.
            self.target,
            // Up is +y.
            Vector3::unit_y(),
        );
        let proj = cgmath::perspective(Deg(FOVY), self.aspect, ZNEAR, ZFAR);
        return OPENGL_TO_WGPU_MATRIX * proj * view;
    }
}

impl CameraUniform {
    pub fn new() -> Self {
        use cgmath::SquareMatrix;
        Self {
            view_proj: cgmath::Matrix4::identity().into(),
        }
    }

    pub fn update_view_proj(&mut self, camera: &Camera) {
        self.view_proj = camera.view_projection_matrix().into();
    }
}
