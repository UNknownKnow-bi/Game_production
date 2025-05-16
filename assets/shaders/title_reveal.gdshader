shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.05;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    // 计算到水平中心的距离
    float distance_from_center = abs(UV.x - 0.5);

    // 基于进度计算显示阈值
    float threshold = progress * 0.5;

    // 创建柔和边缘的alpha值
    float alpha = 1.0 - smoothstep(threshold - edge_softness, threshold + edge_softness, distance_from_center);

    // 获取原始纹理颜色
    vec4 texture_color = texture(TEXTURE, UV);

    // 计算边缘发光 - 在渐变边缘处显示
    float distance_to_edge = abs(distance_from_center - threshold);
    float glow = (1.0 - distance_to_edge / edge_softness) *
                 step(distance_to_edge, edge_softness * 2.0) *
                 glow_intensity * progress; // 随进度增强

    vec4 glow_color = vec4(1.0, 1.0, 1.0, glow);

    // 合并颜色和发光
    vec4 final_color = mix(texture_color, texture_color + glow_color, glow);

    // 应用计算后的alpha，保持原始颜色和发光效果
    COLOR = final_color;
    COLOR.a = texture_color.a * alpha;
}