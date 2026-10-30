#ifndef UNIFORMS_INC
#define UNIFORMS_INC

#include "options.glsl"

// Mipmaps on a render-target texture require the driver to regenerate them
// every frame. Some mobile/translation-layer GL drivers stall indefinitely
// on that call with no error or crash log, which was freezing the game.
// The VHS luma/chroma split is done with a manual box blur instead, so this
// stays off.
const bool colortex0MipmapEnabled = false;
const bool colortex4Clear = false;

// Built-in engine uniforms

uniform int heldItemId;
uniform int heldBlockLightValue;
uniform int heldItemId2;
uniform int heldBlockLightValue2;

uniform int fogMode;
uniform float fogStart;
uniform float fogDensity;

uniform vec3 fogColor;
uniform vec3 skyColor;

uniform int worldTime;
uniform int worldDay;
uniform int moonPhase;

uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;

uniform float sunAngle;
uniform float shadowAngle;

uniform float rainStrength;

uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;

uniform float near;
uniform float far;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;

uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;

uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform mat4 modelViewMatrix;
uniform mat4 modelViewMatrixInverse;
uniform mat4 projectionMatrix;
uniform mat4 projectionMatrixInverse;

uniform vec3 chunkOffset;

uniform float wetness;

uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;

uniform ivec2 terrainTextureSize;
uniform int terrainIconSize;

uniform int isEyeInWater;

uniform float nightVision;
uniform float blindness;

uniform float screenBrightness;

uniform int hideGUI;

uniform float centerDepthSmooth;

uniform ivec2 atlasSize;
uniform vec4 spriteBounds;

uniform vec4 entityColor;
uniform int entityId;
uniform int blockEntityId;

uniform ivec4 blendFunc;

uniform int instanceId;

uniform float playerMood;

uniform int renderStage;

uniform int bossBattle;

uniform float darknessFactor;

// Distant Horizons support

#ifdef DISTANT_HORIZONS
    uniform float dhNearPlane;
    uniform float dhFarPlane;
    uniform int dhRenderDistance;
#endif

// Textures

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;

uniform sampler2D shadow;
uniform sampler2D watershadow;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D colortex15;

uniform sampler2D noisetex;

#endif
