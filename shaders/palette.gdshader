shader_type canvas_item;

// Recolors sprites per monster tier ("rot" zombies, crimson elites) and
// provides a hit flash. Lighting still applies after this runs.

uniform vec4 tint : source_color = vec4(1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.25, 0.2, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(g), desaturate);
	c.rgb = mix(c.rgb, vec3(g) * tint.rgb * 1.5, tint_amount);
	c.rgb = mix(c.rgb, flash_color.rgb, flash);
	COLOR = c;
}
