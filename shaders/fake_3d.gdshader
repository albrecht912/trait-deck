// Hey this is Hei! This shader "fakes" a 3D-camera perspective on CanvasItems.
// Integrated with a runtime noise dissolve threshold pass.
// License: MIT

shader_type canvas_item;

// --- Perspective Uniforms ---
uniform float fov : hint_range(1, 179) = 90;
uniform bool cull_back = true;
uniform float y_rot : hint_range(-180, 180) = 0.0;
uniform float x_rot : hint_range(-180, 180) = 0.0;
uniform float inset : hint_range(0, 1) = 0.0;

// --- Dissolve Uniforms ---
// Godot 4 hint update: hint_albedo changed to hint_default_black
uniform sampler2D dissolve_texture : hint_default_black;
uniform float dissolve_value : hint_range(0, 1) = 1.0; // 1.0 = fully visible, 0.0 = completely burned away

varying flat vec2 o;
varying vec3 p;

void vertex(){
    float sin_b = sin(y_rot / 180.0 * PI);
    float cos_b = cos(y_rot / 180.0 * PI);
    float sin_c = sin(x_rot / 180.0 * PI);
    float cos_c = cos(x_rot / 180.0 * PI);
    
    mat3 inv_rot_mat;
    inv_rot_mat[0][0] = cos_b;
    inv_rot_mat[0][1] = 0.0;
    inv_rot_mat[0][2] = -sin_b;
    
    inv_rot_mat[1][0] = sin_b * sin_c;
    inv_rot_mat[1][1] = cos_c;
    inv_rot_mat[1][2] = cos_b * sin_c;
    
    inv_rot_mat[2][0] = sin_b * cos_c;
    inv_rot_mat[2][1] = -sin_c;
    inv_rot_mat[2][2] = cos_b * cos_c;
    
    float t = tan(fov / 360.0 * PI);
    p = inv_rot_mat * vec3((UV - 0.5), 0.5 / t);
    float v = (0.5 / t) + 0.5;
    p.xy *= v * inv_rot_mat[2].z;
    o = v * inv_rot_mat[2].xy;

    VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * t * (1.0 - inset);
}

void fragment(){
    if (cull_back && p.z <= 0.0) discard;
    
    // Calculate the perspective-warped UV mapping coordinate
    vec2 uv = (p.xy / p.z).xy - o;
    vec2 final_uv = uv + 0.5;
    
    // Fetch texture color map using distorted UV data
    vec4 main_texture = texture(TEXTURE, final_uv);
    vec4 noise_texture = texture(dissolve_texture, final_uv);
    
    // Apply boundary step clipping from the perspective math
    main_texture.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);
    
    // Apply dissolve threshold breakdown logic
    main_texture.a *= floor(dissolve_value + min(1.0, noise_texture.x));
    
    COLOR = main_texture;
}