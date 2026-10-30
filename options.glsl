#ifndef OPTIONS_INC
#define OPTIONS_INC

// --- Core VHS look toggles ---
#define LENS_DISTORTION
#define ASPECT_RATIO
#define FAST_LINEAR_SRGB

// How many discrete steps each colour channel is quantized to.
#define COLOUR_DEPTH 256.0 //[8.0 16.0 32.0 64.0 128.0 256.0 512.0 1024.0]

// Blur radius (in pixels, linear not exponential) for luma/chroma - higher = softer/more tape-like.
#define LUMA_QUALITY 1.0 //[0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define CHROMA_QUALITY 2.0 //[0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]

#define LUMA_NOISE 0.05 //[0.0 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define CHROMA_NOISE 0.2 //[0.0 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define INTERLACING
#define INTERLACE_FRAMERATE 24.0 //[24.0 30.0 60.0]
#define INTERLACE_STRENGTH 0.4 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Overall sharpen/soften amount. Positive sharpens, negative pushes toward
// an actual soft-focus blur - real analog tape is inherently soft, not
// just "not sharpened".
#define SHARPNESS 0.5 //[-1.0 -0.75 -0.5 -0.25 0.0 0.5 1.0 1.5 2.0]

#define HELD_ITEM_BRIGHTNESS 1.0 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define HELD_ITEM_SPOTLIGHT

// --- Flashlight beam shape ---
// Real reflector flashlights cast a bright ring (hotspot) with a darker
// spot dead-center where the bulb/LED holder shadows the reflector, then
// a dimmer "spill" halo further out. FLASHLIGHT_DONUT_SIZE is how wide
// that dark center dot is, in degrees; 0 disables it for a plain hotspot.
#define FLASHLIGHT_DONUT_SIZE 2.5 //[0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0]
#define FLASHLIGHT_HOTSPOT_SIZE 6.0 //[2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
// Overall beam width. Fixed rather than a slider so the beam shape stays
// consistent with FLASHLIGHT_DONUT_SIZE/FLASHLIGHT_HOTSPOT_SIZE above.
#define FLASHLIGHT_SPILL_SIZE 20.0

// How bright the flashlight itself is, separate from HELD_ITEM_BRIGHTNESS
// (which scales the light's raw value before this is applied).
#define FLASHLIGHT_INTENSITY 1.2 //[0.2 0.4 0.6 0.8 1.0 1.2 1.5 1.8 2.2 2.6 3.0]

// Subtle battery-powered flicker.
#define FLASHLIGHT_FLICKER

// Only let the flashlight contribute where it's actually dark - night with
// no nearby light, or an unlit cave/interior. In already-lit areas it stays
// off, same as pointing a flashlight at something in broad daylight doing
// nothing.
//#define FLASHLIGHT_DARK_ONLY
#define FLASHLIGHT_DARK_THRESHOLD 0.35 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6]

// --- Colour grade profile ---
// 0 = off, 1 = Backrooms (sickly yellow fluorescent), 2 = Poolrooms (light
// blue tile/water), 3 = Liminal Night (cooler blue shadows, same darkness),
// 4 = Parking Garage (sodium-vapor orange, darker), 5 = Dead Channel (cold,
// heavily desaturated static-TV look), 6 = Lost (foggy, washed-out grey),
// 7 = After Hours (dim, quiet, cool neutral), 8 = Forgotten (dusty, faded,
// warm desaturated), 9 = Body Camera (cool, contrasty, clinical digital
// look).
// Selected automatically by the matching profile button; only change by
// hand if you want to mix a grade with a different profile's settings.
#define COLOUR_GRADE 0 //[0 1 2 3 4 5 6 7 8 9]

// Soft corner darkening - fits the CRT/liminal-space look. 0 disables it.
#define VIGNETTE_STRENGTH 0.15 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4]

// --- Extra tape artifacts ---
// A horizontal band that drifts down the screen and briefly tears the
// image sideways, like a VHS tape struggling to hold tracking.
//#define TRACKING_ERROR
#define TRACKING_ERROR_STRENGTH 0.03 //[0.01 0.02 0.03 0.04 0.05 0.06 0.08 0.1]

// Slight per-channel colour offset that grows toward the screen edges,
// like a cheap lens/CRT. Subtle by default.
//#define CHROMATIC_ABERRATION
#define CHROMATIC_ABERRATION_STRENGTH 0.15 //[0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5]

// A thin strip of raw static right at the bottom edge of the frame, where
// an actual VHS deck's playback head switches tracks between fields.
//#define HEAD_SWITCH_NOISE
#define HEAD_SWITCH_STRENGTH 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Vertical coloured streak bleeding out of bright lights - streetlights,
// windows, torches - like an overexposed CCD camera sensor. Off by default
// since it costs extra samples; only runs when enabled.
//#define CCD_SMEAR
// How far the streak reaches, as a percentage of screen height.
#define CCD_SMEAR_LENGTH 25.0 //[10.0 15.0 20.0 25.0 30.0 40.0 50.0 60.0]
#define CCD_SMEAR_STRENGTH 1.0 //[0.25 0.5 0.75 1.0 1.5 2.0 2.5 3.0]
#define CCD_SMEAR_TAPS 6 //[4 6 8 10 12 16]

// --- Fog ---
// Multiplies how quickly fog closes in with distance - higher is thicker,
// closer-in fog. 1.0 is the original untouched distance.
#define FOG_DENSITY 1.0 //[0.5 0.75 1.0 1.5 2.0 2.5 3.0 4.0 5.0]

// Dust flecks and thin scratches that flicker in and out, like dirt and
// damage on old film/tape stock.
//#define FILM_DUST
// Roughly how many specks show up per second-ish of pattern change.
#define FILM_DUST_RATE 12.0 //[4.0 6.0 8.0 10.0 12.0 16.0 20.0 24.0]
// Higher = more dust visible at once.
#define FILM_DUST_DENSITY 1.5 //[0.5 1.0 1.5 2.0 3.0 4.0 5.0 6.0]
#define FILM_DUST_STRENGTH 0.8 //[0.2 0.4 0.6 0.8 1.0]

// --- More tape/CRT artifacts ---

// Thin dark horizontal lines mimicking a CRT's visible scan rows.
//#define SCAN_LINES
#define SCAN_LINE_STRENGTH 0.25 //[0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5 0.6]

// Continuous wavy horizontal warping - a tape that's just barely holding
// tracking, as opposed to TRACKING_ERROR's occasional torn band.
//#define TRACKING_WAVE
#define TRACKING_WAVE_STRENGTH 0.15 //[0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5]

// Directional horizontal colour smear, mainly on reds - how saturated
// colour actually bleeds sideways on analog tape.
//#define COLOR_BLEED
#define COLOR_BLEED_STRENGTH 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0]

// The whole frame shakes slightly side to side, like a tape/deck that
// isn't quite steady.
//#define WOBBLE
#define WOBBLE_STRENGTH 0.3 //[0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0]

// Full-screen white noise, blended in at adjustable strength - a dead
// channel at 1.0, a faint haze of static at low values.
//#define STATIC_SNOW
#define STATIC_SNOW_STRENGTH 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Random bright horizontal streaks - a tape dropout losing signal on a
// scanline for an instant.
//#define DROPOUT_LINES
#define DROPOUT_STRENGTH 0.7 //[0.2 0.4 0.6 0.8 1.0]

// Global colour fade independent of whichever COLOUR_GRADE profile is
// active - washes the whole palette toward grey. 0 is untouched.
#define DESATURATION 0.0 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Bright areas spread and glow outward in every direction, unlike
// CCD_SMEAR which only streaks vertically.
//#define BLOOM
#define BLOOM_STRENGTH 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0 1.5]
#define BLOOM_THRESHOLD 0.7 //[0.5 0.6 0.7 0.8 0.9]

// Extra barrel warp plus rounded, darkened corners simulating the curved
// glass of a CRT tube itself - separate from LENS_DISTORTION, which
// simulates the camera lens capturing the scene rather than the display
// showing it back.
//#define SCREEN_CURVATURE
#define SCREEN_CURVATURE_STRENGTH 0.3 //[0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0]

// Stylised smeared horizontal motion trails, like tape spooling past the
// head at speed. There's no way for a shader to detect an actual rewind/
// fast-forward action, so this is a manually toggled look rather than
// something that triggers automatically.
//#define REWIND_STREAK
#define REWIND_STREAK_STRENGTH 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0]

// A shakier, torn, unstable-freeze-frame look. Same caveat as
// REWIND_STREAK - shaders have no way to detect the game actually being
// paused, so this is a manual look rather than an automatic trigger.
//#define PAUSE_JITTER
#define PAUSE_JITTER_STRENGTH 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.8 1.0]

// Occasional brief flashes of full static or inverted colour, like a
// signal cutting out for a frame or two.
//#define SIGNAL_LOSS
#define SIGNAL_LOSS_STRENGTH 1.0 //[0.25 0.5 0.75 1.0]

// A distinct textural grain layer, separate from LUMA_NOISE/CHROMA_NOISE
// (which model noise in the analog signal itself rather than a film
// texture sitting over the image).
//#define FILM_GRAIN
#define FILM_GRAIN_STRENGTH 0.15 //[0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5]

// Blinking REC dot and a running MM:SS timecode burned into the corner,
// like a camcorder's on-screen display. The clock counts up from when the
// shader loads (there's no way for a shader to read a real wall-clock
// date/time), rather than showing the actual date.
//#define VCR_TIMESTAMP

#endif
