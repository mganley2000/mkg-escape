shader_type canvas_item;

// Screen-space vignette with a red pulse used when the hero is hurt.

uniform float strength : hint_range(0.0, 1.0) = 0.65;
uniform float inner = 0.42;
uniform float outer = 1.05;
uniform float hurt : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.5, 1.0) * 2.0;
	float d = length(p);
	float a = smoothstep(inner, outer, d) * strength;
	float h = smoothstep(0.35, 1.1, d) * hurt;
	vec3 col = mix(vec3(0.0), vec3(0.55, 0.0, 0.02), clamp(h * 1.5, 0.0, 1.0));
	COLOR = vec4(col, max(a, h * 0.75));
}
