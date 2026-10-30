#include "version.glsl"

#if defined(VERTEX)

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolour;

attribute vec4 at_tangent;
attribute vec3 mc_Entity;

varying mat3 tbn;
varying float block_id;
varying float v_sky_light;

#include "uniforms.glsl"
#include "common.glsl"

void main()
{
    gl_Position = ftransform();

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolour = gl_Color;

    vec3 normal = normalize(gl_Normal);
    vec3 tangent = normalize(at_tangent.xyz);
    vec3 binormal = normalize(cross(tangent, normal));

    tbn = mat3(
        tangent.x, binormal.x, normal.x,
        tangent.y, binormal.y, normal.y,
        tangent.z, binormal.z, normal.z
    );

    block_id = mc_Entity.x;

    // Same result for every fragment in the frame, so compute it once per
    // vertex here instead of once per fragment.
    vec3 sun_direction = LightPosToWorldDir(sunPosition);
    v_sky_light = pow(sun_direction.y * 0.5 + 0.5, 3.0);
    v_sky_light *= (1.0 - rainStrength) * 0.1 + 0.9;
}

#elif defined(FRAGMENT)

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolour;

varying mat3 tbn;
varying float block_id;
varying float v_sky_light;

#include "uniforms.glsl"
#include "common.glsl"

void main()
{
    vec4 colour = texture2D(gtexture, texcoord);
    if (colour.a < 0.1) discard;
    colour.rgb = sRGBToLinear(colour.rgb);

    vec3 screen_point = gl_FragCoord.xyz / vec3(viewWidth, viewHeight, 1.0);
    vec3 world_point = TransformScreenToWorldPoint(screen_point);
    float dist_to_player = length(world_point);

    vec3 geo_normal = normalize(vec3(tbn[0][2], tbn[1][2], tbn[2][2]));

    vec3 pix_normal = vec3(texture2D(normals, texcoord).xy * 2.0 - 1.0, 0.0);
    pix_normal.z = sqrt(max(0.0, 1.0 - dot(pix_normal.xy, pix_normal.xy)));
    pix_normal = normalize(pix_normal * tbn);

    vec4 spec = texture2D(specular, texcoord);
    spec.x = pow(1.0 - spec.x, 2.0);
    spec.a = spec.a > 0.997 ? 0.0 : spec.a;

    colour.rgb = colour.rgb * sRGBToLinear(glcolour.rgb) * sRGBToLinear(glcolour.aaa);
    vec3 base_colour = colour.rgb;

    float sky_light = v_sky_light;

    colour.rgb = base_colour * pow(lmcoord.y, 3.0) * sky_light
               + base_colour * (pow(lmcoord.x, 5.0) * 3.0 * blocklight_colour + spec.a * 3.0);

    // heldBlockLightValue is the same for every fragment this frame, so this
    // branch doesn't cause warp divergence - and it skips the beam-shape
    // trig (acos/degrees/smoothstep) on every terrain pixel for the very
    // common case of not holding a light source at all.
    float flashlight_punch = 0.0;

    #ifdef HELD_ITEM_SPOTLIGHT
    if (heldBlockLightValue > 0)
    {
        vec3 light_dir_to_frag = normalize(world_point);
        vec3 light_direction = normalize(vec3(-gbufferModelView[0][2], -gbufferModelView[1][2], -gbufferModelView[2][2]));

        float theta = clamp(dot(light_dir_to_frag, light_direction), -1.0, 1.0);
        float beam_angle = degrees(acos(theta));

        // Hotspot ring with a dark center dot (donut hole), then a dimmer
        // spill halo out to the edge of the beam - the pattern a real
        // reflector flashlight actually casts, rather than a flat cone.
        float donut = smoothstep(0.0, FLASHLIGHT_DONUT_SIZE, beam_angle);
        float hotspot = 1.0 - smoothstep(FLASHLIGHT_HOTSPOT_SIZE, FLASHLIGHT_SPILL_SIZE, beam_angle);
        float spill = 1.0 - smoothstep(FLASHLIGHT_HOTSPOT_SIZE * 0.5, FLASHLIGHT_SPILL_SIZE, beam_angle);

        float player_light_mask = max(donut * hotspot, spill * 0.35);
        player_light_mask *= max(0.0, dot(pix_normal, -light_direction));

        float flashlight_flicker = 1.0;
        #ifdef FLASHLIGHT_FLICKER
            flashlight_flicker = 0.97 + 0.03 * sin(frameTimeCounter * 17.0) * sin(frameTimeCounter * 5.3);
        #endif

        #ifdef FLASHLIGHT_DARK_ONLY
            float ambient_brightness = lmcoord.y * sky_light + pow(lmcoord.x, 5.0);
            float darkness_visibility = 1.0 - smoothstep(FLASHLIGHT_DARK_THRESHOLD, FLASHLIGHT_DARK_THRESHOLD + 0.15, ambient_brightness);
            player_light_mask *= darkness_visibility;
        #endif

        float held_item_light = heldBlockLightValue * HELD_ITEM_BRIGHTNESS * flashlight_flicker;
        // Inverse-square falloff instead of a linear ramp - matches how
        // real light intensity actually drops off with distance.
        float player_light = held_item_light / (1.0 + dist_to_player * dist_to_player * 0.05);

        colour.rgb += player_light * player_light_mask * base_colour * FLASHLIGHT_INTENSITY * blocklight_colour;
        flashlight_punch = clamp(player_light * player_light_mask, 0.0, 1.0);
    }
    #endif

    if (entityColor.a > 0.0)
    {
        colour.rgb += base_colour * sRGBToLinear(entityColor.rgb) * entityColor.a;
    }

    float max_fog_dist = far;
    #ifdef DISTANT_HORIZONS
        max_fog_dist = float(dhRenderDistance);
    #endif
    max_fog_dist = (isEyeInWater == 2 ? 3.0 : isEyeInWater == 1 ? 10.0 : max_fog_dist);
    max_fog_dist /= FOG_DENSITY;

    float fog = dist_to_player / max_fog_dist;
    // The flashlight beam cuts a bit of visible distance through the fog
    // where it's pointed, like a real beam does, instead of the fog being
    // completely indifferent to it.
    fog *= 1.0 - flashlight_punch * 0.4;
    vec3 fog_col = mix(vec3(0.0), fogColor, float(eyeBrightnessSmooth.y) / 240.0);
    colour.rgb = mix(colour.rgb, sRGBToLinear(fog_col), smoothstep(0.0, 1.0, min(1.0, fog)));

    /* DRAWBUFFERS:0123 */
    gl_FragData[0] = colour;
    gl_FragData[1] = vec4(geo_normal, 1.0);
    gl_FragData[2] = vec4(pix_normal, 1.0);
    gl_FragData[3] = spec;
}

#endif
