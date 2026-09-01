shader_type spatial;

uniform sampler2D hair_texture : source_color;
uniform vec3 tint : source_color = vec3(0.02, 0.02, 0.025);
uniform float roughness : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 tex = texture(hair_texture, UV);

	ALBEDO = tex.rgb * tint;
	ROUGHNESS = roughness;
	SPECULAR = 0.8;
}