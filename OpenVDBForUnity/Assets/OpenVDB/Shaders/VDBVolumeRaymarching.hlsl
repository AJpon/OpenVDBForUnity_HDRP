#ifndef __VDBVOLUME_RAYTRACING_INCLUDED__
#define __VDBVOLUME_RAYTRACING_INCLUDED__

//#include "UnityCG.cginc"
//#include "Camera.cginc"

#ifndef ITERATIONS
#define ITERATIONS 100
#endif

inline float3 GetCameraPosition()    { return _WorldSpaceCameraPos;      }
inline float3 GetCameraForward()     { return -UNITY_MATRIX_V[2].xyz;    }
inline float3 GetCameraUp()          { return UNITY_MATRIX_V[1].xyz;     }
inline float3 GetCameraRight()       { return UNITY_MATRIX_V[0].xyz;     }
inline float  GetCameraFocalLength() { return abs(UNITY_MATRIX_P[1][1]); }
inline float  GetCameraNearClip()    { return _ProjectionParams.y;       }
inline float  GetCameraFarClip()     { return _ProjectionParams.z;       }
inline float  GetCameraMaxDistance() { return GetCameraFarClip() - GetCameraNearClip(); }

inline float3 _GetCameraDirection(float2 sp)
{
    float3 camDir      = GetCameraForward();
    float3 camUp       = GetCameraUp();
    float3 camSide     = GetCameraRight();
    float  focalLen    = GetCameraFocalLength();

    return normalize((camSide * sp.x) + (camUp * sp.y) + (camDir * focalLen));
}

inline float3 GetCameraDirection(float4 screenPos)
{
    #if UNITY_UV_STARTS_AT_TOP
    screenPos.y *= -1.0;
    #endif
    screenPos.x *= _ScreenParams.x / _ScreenParams.y;
    screenPos.xy /= screenPos.w;

    return _GetCameraDirection(screenPos.xy);
}

float SampleVolume(float3 uv, Texture3D Volume, SamplerState VolumeSampler)
{
    return SAMPLE_TEXTURE3D(Volume, VolumeSampler, uv).r;
}

struct Ray
{
    float3 origin;
    float3 dir;
};

struct AABB
{
    float3 min;
    float3 max;
};

inline bool IsInnerCube(float3 pos)
{
    return all(max(0.5 - abs(pos), 0.0));
}

inline float Intersect(Ray r, AABB aabb)
{
    float3 invR = 1.0 / r.dir;
    float3 tbot = invR * (aabb.min - r.origin);
    float3 ttop = invR * (aabb.max - r.origin);
    float3 tmax = max(ttop, tbot);
    float2 t = min(tmax.xx, tmax.yz);
    return min(t.x, t.y);
}

inline float3 GetUV(float3 p)
{
    return (p + 0.5);
}

inline float ComputeDepth(float4 clippos)
{
    #if defined(SHADER_TARGET_GLSL) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
    return (clippos.z / clippos.w) * 0.5 + 0.5;
    #else
    return clippos.z / clippos.w;
#endif
}

inline float3 Localize(float3 p, float4x4 unity_WorldToObject)
{
    return mul(unity_WorldToObject, float4(p, 1)).xyz;
}

void RayMarching_float(Texture3D Volume, SamplerState VolumeSampler, float Intensity, float ShadowSteps, float ShadowThreshold, float3 ShadowDensity, float StepDistance,
    float3 AmbientColor, float AmbientDensity, float3 world, float4 pos, float sceneDepth, float3 mainLightDirection, float4x4 unity_WorldToObject, float4x4 unity_ObjectToWorld,
    float screenWidth, float screenHeight, float3 cameraPos, float3 camDir, float nearPlane, float farPlane, out float4 outColor, out float outDepth)
{
    Ray ray;

    float4 screenPos = pos;
    screenPos.x *= screenWidth / screenHeight;
    //screenPos.xy /= screenPos.w;
    //float3 camUp       = GetCameraUp();
    float3 camUp       = float3(0, 1, 0);
    //float3 camSide     = GetCameraRight();
    float3 camSide     = float3(1, 0, 0);
    //float  focalLen    = GetCameraFocalLength();
    float  focalLen    = 1;

    float3 cameraDir = normalize((camSide * screenPos.x) + (camUp * screenPos.y) + (camDir * focalLen));
    //ray.dir = normalize(mul((float3x3) unity_WorldToObject, cameraDir));
    ray.dir = float3(SafeNormalize(screenPos.xyz));
    //wray.dir = screenPos.xyz / 10000000000000000.0;

    float3 rayOriginWorld = world;

    // get near camera position in object space
    float3 nearCameraPos = cameraPos + (nearPlane + 0.01) * cameraDir;
    float3 nearCameraPosLocal = Localize(nearCameraPos, unity_WorldToObject);

    // If camera inside volume cube, change the original position of the ray.
    if(IsInnerCube(nearCameraPosLocal))
    {
        rayOriginWorld = nearCameraPos;
    }
    ray.origin = Localize(rayOriginWorld, unity_WorldToObject);

    AABB aabb;
    aabb.min = float3(-0.5, -0.5, -0.5);
    aabb.max = float3(0.5, 0.5, 0.5);

    float tfar = Intersect(ray, aabb);

    // calculate start offset
    /*float3 cameraForward = GetCameraForward();
    float stepDist = StepDistance / dot(cameraDir, cameraForward);

    float cameraDist = length(rayOriginWorld - cameraPos);
    float startOffset = stepDist - fmod(cameraDist, stepDist);
    float3 start = ray.origin + mul((float3x3) unity_WorldToObject, cameraDir * startOffset);*/
    float stepDist = StepDistance;
    float3 start = ray.origin;

    // sampling parameter (start, end, stepcount)
    float3 end = ray.origin + ray.dir * tfar;

    //Get the distance to the camera from the depth buffer for this point
    /*float tfar2 = length(ray.origin - Localize(sceneDepth * cameraDir + cameraPos, unity_WorldToObject));
    end = ray.origin + ray.dir * min(tfar, tfar2);*/

    float dist = length(end - start);
    half stepCount = dist / stepDist;
    float3 ds = ray.dir * stepDist;

    // shadow parameter
    // directional light
    float shadowstepsize = 1.0 / (float)ShadowSteps;
    float3 lightVec = normalize(mul((float3x3) unity_WorldToObject, mainLightDirection.xyz))  * shadowstepsize;
    float3 shadowDensity = 1.0 / ShadowDensity * shadowstepsize;

    // threshold for shadow density
    float shadowThreshold = -log(ShadowThreshold) / length(shadowDensity);

    float3 p = start;
    float3 depth = end;
    bool depthtest = true;

    float curdensity = 0.0;
    float transmittance = 1;
    float3 lightenergy = 0;

    //[unroll]
    [loop]
    for (int iter = 0; iter < ITERATIONS; iter++)
    {
        // sampling voxel
        float3 uv = GetUV(p);
        float cursample = SampleVolume(uv, Volume, VolumeSampler);

        if(cursample > 0.01)
        {
            float3 lpos = p;
            float shadowdist = 0;

            if(depthtest)
            {
                depth = p;
                depthtest = false;
            }

            /*[loop]
            for (int s = 0; s < ShadowSteps; s++)
            {
                lpos += lightVec;
                float3 luv = GetUV(lpos);
                float lsample = SampleVolume(saturate(luv), Volume, VolumeSampler);

                shadowdist += lsample;

                float3 shadowboxtest = floor( 0.5 + ( abs( 0.5 - luv ) ) );
                float exitshadowbox = shadowboxtest .x + shadowboxtest .y + shadowboxtest .z;

                // check to exit shadow box
                if(shadowdist > shadowThreshold || exitshadowbox >= 1)
                {
                    break;
                }
            }*/

            curdensity = saturate(cursample * Intensity);
            float3 shadowterm = exp(-shadowdist * shadowDensity);
            float3 absorbedlight = shadowterm * curdensity;
            lightenergy += absorbedlight * transmittance;
            transmittance *= 1-curdensity;

            /*shadowdist = 0;

            float3 luv = uv + float3(0,0,0.05);
            shadowdist += SampleVolume(saturate(luv), Volume, VolumeSampler);
            luv = uv + float3(0,0,0.1);
            shadowdist += SampleVolume(saturate(luv), Volume, VolumeSampler);
            luv = uv + float3(0,0,0.2);
            shadowdist += SampleVolume(saturate(luv), Volume, VolumeSampler);
            lightenergy += exp(-shadowdist * AmbientDensity) * curdensity * AmbientColor * transmittance;*/
        }
        p += ds;

        if(iter >= stepCount)
        {
            break;
        }

        if (transmittance < 0.01)
        {
            break;
        }
    }
    if(depthtest)
    {
        clip(-1);
    }

    outColor = float4(lightenergy, 1-transmittance);
    outColor = float4(ray.dir, 1);
    outDepth = ComputeDepth(mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, (float4(depth, 1.0)))));
}
#endif
