shader_type canvas_item;

uniform sampler2D palette : filter_nearest, repeat_disable;
uniform sampler2D origPalette : filter_nearest, repeat_disable;
uniform ivec2 paletteSize;

void fragment() {
	vec4 spriteColor = texture(TEXTURE, UV);

	vec2 uvOffset = 1.0 / vec2(paletteSize);

	for (int x = 0; x < paletteSize.x; x++) {
		for (int y = 0; y < paletteSize.y; y++) {
			vec2 paletteUV = vec2(float(x) + 0.5, float(y) + 0.5) * uvOffset;

			vec4 oldColor = texture(origPalette, paletteUV);
			vec4 newColor = texture(palette, paletteUV);

			float areSameColor = step(distance(spriteColor, oldColor), 0.0);

			spriteColor = mix(spriteColor, newColor, areSameColor);
		}
	}

	COLOR = spriteColor;
}
