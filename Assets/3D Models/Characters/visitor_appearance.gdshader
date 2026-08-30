shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 skin_color : source_color = vec4(0.72, 0.46, 0.32, 1.0);
uniform vec4 hair_color : source_color = vec4(0.06, 0.035, 0.025, 1.0);
uniform vec4 upper_clothing : source_color = vec4(0.12, 0.24, 0.32, 1.0);
uniform vec4 lower_clothing : source_color = vec4(0.055, 0.07, 0.09, 1.0);
uniform vec4 shoe_color : source_color = vec4(0.025, 0.02, 0.018, 1.0);
uniform float roughness_value : hint_range(0.2, 1.0) = 0.78;

varying vec3 body_position;

void vertex() {
	body_position = VERTEX;
}

void fragment() {
	float height = body_position.y;
	float side = abs(body_position.x);
	vec3 color = lower_clothing.rgb;

	// Shoes, trousers/skirt, upper garment, exposed hands/neck/face, then hair.
	if (height < 0.14) {
		color = shoe_color.rgb;
	} else if (height < 0.78) {
		color = lower_clothing.rgb;
	} else if (height < 1.34) {
		color = upper_clothing.rgb;
	}

	float hand_mask = smoothstep(0.32, 0.48, side)
		* smoothstep(0.70, 0.86, height)
		* (1.0 - smoothstep(1.22, 1.34, height));
	color = mix(color, skin_color.rgb, hand_mask);

	if (height >= 1.34) {
		color = skin_color.rgb;
	}
	if (height >= 1.58) {
		color = hair_color.rgb;
	}

	// Subtle woven variation prevents the outfit from looking like flat plastic.
	float weave = sin(body_position.x * 95.0) * sin(body_position.y * 110.0) * 0.025;
	ALBEDO = color + weave;
	ROUGHNESS = roughness_value;
	SPECULAR = 0.22;
}
