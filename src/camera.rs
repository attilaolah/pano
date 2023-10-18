use cgmath::{Deg, Rad, Zero};
use winit::event::{ElementState, KeyboardInput, VirtualKeyCode, WindowEvent};

pub struct Camera {
    // Azimuthal angle "phi".
    // Rotates the camera around the vertical axis (left/right).
    phi: Rad<f32>,
    // Polar angle "theta".
    // Rotates the camera around the horizontal axis (up/down).
    theta: Rad<f32>,
    // Vertical (Y) field of view.
    fovy: Rad<f32>,
    // Aspect ratio (width / height).
    aspect: f32,
}

pub struct CameraController {
    hold_up: bool,
    hold_down: bool,
    hold_left: bool,
    hold_right: bool,
    hold_plus: bool,
    hold_minus: bool,
    hold_zero: bool,
}

#[repr(C)]
#[derive(Debug, Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct CameraUniform {
    theta: f32,
    phi: f32,
    fovy: f32,
    aspect: f32,
}

impl Camera {
    pub fn new(aspect: f32) -> Self {
        Self {
            theta: Rad::zero(),
            phi: Rad::zero(),
            fovy: Deg(30.0).into(),
            aspect,
        }
    }
}

impl CameraController {
    pub fn new() -> Self {
        Self {
            hold_up: false,
            hold_down: false,
            hold_left: false,
            hold_right: false,
            hold_plus: false,
            hold_minus: false,
            hold_zero: false,
        }
    }

    pub fn process_events(&mut self, event: &WindowEvent) -> bool {
        match event {
            WindowEvent::KeyboardInput {
                input:
                    KeyboardInput {
                        state,
                        virtual_keycode: Some(keycode),
                        ..
                    },
                ..
            } => {
                let is_pressed = *state == ElementState::Pressed;
                match keycode {
                    VirtualKeyCode::Up => {
                        self.hold_up = is_pressed;
                        true
                    }
                    VirtualKeyCode::Left => {
                        self.hold_left = is_pressed;
                        true
                    }
                    VirtualKeyCode::Down => {
                        self.hold_down = is_pressed;
                        true
                    }
                    VirtualKeyCode::Right => {
                        self.hold_right = is_pressed;
                        true
                    }
                    VirtualKeyCode::Plus | VirtualKeyCode::NumpadAdd => {
                        self.hold_plus = is_pressed;
                        true
                    }
                    VirtualKeyCode::Minus | VirtualKeyCode::NumpadSubtract => {
                        self.hold_minus = is_pressed;
                        true
                    }
                    VirtualKeyCode::Numpad0 => {
                        self.hold_zero = is_pressed;
                        true
                    }
                    _ => false,
                }
            }
            _ => false,
        }
    }

    pub fn update_camera(&self, camera: &mut Camera) {
        if self.hold_up {
            camera.theta += Deg(1.0).into();
        }
        if self.hold_down {
            camera.theta -= Deg(1.0).into();
        }
        if self.hold_left {
            camera.phi -= Deg(1.0).into();
        }
        if self.hold_right {
            camera.phi += Deg(1.0).into();
        }
        if self.hold_minus {
            if camera.fovy <= Deg(85.0).into() {
                camera.fovy += Deg(5.0).into();
            }
        }
        if self.hold_plus {
            if camera.fovy >= Deg(10.0).into() {
                camera.fovy -= Deg(5.0).into();
            }
        }
        if self.hold_zero {
            // TODO: camera.reset()!
            camera.phi = Deg(0.0).into();
            camera.theta = Deg(0.0).into();
            camera.fovy = Deg(30.0).into();
        }
    }
}

impl CameraUniform {
    pub fn new() -> Self {
        Self {
            theta: 0.0,
            phi: 0.0,
            fovy: 0.0,
            aspect: 1.0,
        }
    }

    pub fn update(&mut self, camera: &Camera) {
        self.theta = camera.theta.0;
        self.phi = camera.phi.0;
        self.fovy = camera.fovy.0;
        self.aspect = camera.aspect;
    }
}
