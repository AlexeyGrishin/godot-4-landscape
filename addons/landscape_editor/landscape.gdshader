shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D noise;
uniform sampler2D gradient;
uniform sampler2D orm_gradient;
varying vec3 pos;

void vertex() {
	pos = VERTEX;
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 n = texture(noise, UV*20.0);
	float u = (pos.y+10.0)/20.0;// + n.x*0.02;
	vec4 albedo = texture(gradient, vec2(u, 0.5));
	ALBEDO = albedo.rgb;
	vec4 orm = texture(orm_gradient, vec2(u, 0.5));
	METALLIC = orm.b;
	ROUGHNESS = orm.g;
}

