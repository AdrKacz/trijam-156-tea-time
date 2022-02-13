shader_type canvas_item;

uniform vec4 color : hint_color = vec4(.2, .2, .2, 1.);

void fragment() {
  COLOR = color;
}