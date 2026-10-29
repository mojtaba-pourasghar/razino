shader_type canvas_item;
// Makes a painted backdrop move without repainting it.
//
// A filter over the whole picture would be a filter over the whole picture:
// the stones would ripple and the whole thing would read as heat haze. What
// actually moves in a street at night is small and bright — water catching
// the light, a lamp, a lit window — so the shader finds those and leaves
// everything else exactly as painted.
//
// `mask` is luminance above a threshold, which picks out lit things because
// in a night painting nothing dark is a light source. That is a cheap test
// and it is right far more often than it is wrong; where it is wrong, it is
// wrong on something already bright, where a little shimmer is invisible.

uniform float shimmer_speed : hint_range(0.0, 6.0) = 1.4;
uniform float shimmer_amount : hint_range(0.0, 0.08) = 0.016;
uniform float glow_amount : hint_range(0.0, 0.6) = 0.18;
uniform float glow_speed : hint_range(0.0, 6.0) = 2.1;
// Below this the pixel is scenery and is left alone.
uniform float light_floor : hint_range(0.0, 1.0) = 0.46;

void fragment() {
	vec2 uv = UV;
	vec4 flat_colour = texture(TEXTURE, uv);
	float lit = dot(flat_colour.rgb, vec3(0.299, 0.587, 0.114));
	float mask = smoothstep(light_floor, light_floor + 0.26, lit);

	// Two waves that do not divide into each other, so the surface never
	// settles into a pattern the eye can predict and start ignoring.
	float wave = sin(uv.y * 180.0 + TIME * shimmer_speed)
		* sin(uv.x * 97.0 - TIME * shimmer_speed * 0.63);
	uv.x += wave * shimmer_amount * mask;

	vec4 colour = texture(TEXTURE, uv);
	// Lit things also breathe in brightness, on a slower count than they
	// ripple, which is what separates a lamp from a reflection.
	float pulse = 1.0 + glow_amount * mask
		* (0.5 + 0.5 * sin(TIME * glow_speed + uv.x * 11.0));
	colour.rgb *= pulse;
	// Written straight, without MODULATE: that built-in does not exist in
	// the GL-compatibility renderer this project ships on, and a backdrop
	// is drawn at full brightness anyway. A caller that needs to dim one
	// does it with its own modulate on a parent, which still applies.
	COLOR = colour;
}
