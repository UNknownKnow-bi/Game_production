shader_type canvas_item;

// 固定圆角半径
uniform float corner_radius = 15.0;

void fragment() {
    vec2 size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
    vec2 pixel_position = UV * size;

    // 是否应用透明度
    bool should_clip = false;

    // 左上角圆角
    if (pixel_position.x < corner_radius && pixel_position.y < corner_radius) {
        float distance = length(pixel_position - vec2(corner_radius, corner_radius));
        if (distance > corner_radius) {
            should_clip = true;
        }
    }

    // 右上角圆角
    if (pixel_position.x > size.x - corner_radius && pixel_position.y < corner_radius) {
        float distance = length(pixel_position - vec2(size.x - corner_radius, corner_radius));
        if (distance > corner_radius) {
            should_clip = true;
        }
    }

    // 如果点在圆角区域外部，则将其设为透明
    if (should_clip) {
        COLOR.a = 0.0;
    }
}