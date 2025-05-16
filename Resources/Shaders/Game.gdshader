shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

uniform sampler2D palette : repeat_disable, filter_nearest;

uniform sampler2D origPalette : repeat_disable, filter_nearest;

uniform ivec2 paletteSize;

void fragment() {
	vec4 screenColor = COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 uvOffset = 1.0/vec2(paletteSize);
	
	for (int x = 0; x < paletteSize.x; x++)
	for (int y = 0; y < paletteSize.y; y++) {
		vec2 paletteUV = vec2(float(x) + 0.5, float(y) + 0.5) * uvOffset;
		
		vec4 oldColor = texture(origPalette, paletteUV);
		vec4 newColor = texture(palette, paletteUV);
		
		float areSameColor = step(distance(screenColor, oldColor), 0.0);
		
		COLOR = mix(COLOR, newColor, areSameColor);
	}
}


