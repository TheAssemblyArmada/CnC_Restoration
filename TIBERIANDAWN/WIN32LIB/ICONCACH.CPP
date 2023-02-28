#include "iconcach.h"
#include "wwstd.h"
#include <gbuffer.h>

IconCacheClass	CachedIcons[MAX_CACHED_ICONS];

extern "C"{
IconSetType		IconSetList[MAX_ICON_SETS];
short				IconCacheLookup[MAX_LOOKUP_ENTRIES];
}

int		CachedIconsDrawn=0;		//Counter of number of cache hits
int		UnCachedIconsDrawn=0;	//Counter of number of cache misses
BOOL	CacheMemoryExhausted;	//Flag set if we have run out of video RAM

DDSURFACEDESC VideoSurfaceDescription;

int Optimize_Video_Memory_Cache()
{
  int cache_hits[MAX_CACHED_ICONS];
  int cache_misses[MAX_CACHED_ICONS];

  if ( !CacheMemoryExhausted || CachedIconsDrawn + UnCachedIconsDrawn <= 1000 || UnCachedIconsDrawn <= CachedIconsDrawn )
  {
    return 0;
  }
  
  int total_cache_misses = 0;
  int total_cache_hits = 0;
  
  int i;
  for (i = 0; i < MAX_CACHED_ICONS; ++i )
  {
    if ( CachedIcons[i].TimesFailed > 5 )
    {
      cache_misses[++total_cache_misses] = i;
    }
  }
  
  for (i = 0; i < MAX_CACHED_ICONS; ++i )
  {
    if ( CachedIcons[i].TimesDrawn < 3 )
    {
      cache_hits[++total_cache_hits] = i;
    }
  }
  
  if ( total_cache_hits > 1 )
  {
  
    for (i = 0; i < total_cache_hits; ++i )
    {
    
      int swapped = 0;
      
      for (int j = 0; total_cache_hits - 1 > j; ++j )
      {
      
        if ( CachedIcons[cache_hits[j]].TimesDrawn > CachedIcons[cache_hits[j + 1]].TimesDrawn )
        {
          int tmp = cache_hits[j];
          cache_hits[j] = cache_hits[j + 1];
          cache_hits[j + 1] = tmp;
          swapped = 1;
        }
      }
      
      if ( !swapped )
      {
        break;
      }
    }
  }
  
  
  for (i = 0; i < total_cache_misses && i < total_cache_hits; ++i )
  {
    CachedIcons[cache_hits[i]].Uncache_It();
  }
  
  CacheMemoryExhausted = 0;
  CachedIconsDrawn = 0;
  UnCachedIconsDrawn = 0;
  
  return 1;
}

extern "C" int __cdecl Cache_New_Icon (int icon_index, void *icon_ptr)
{
//ohoh
    //if ( !Iconcheck_5B39E4 ) {
    //    return 0;
    //}
    
    if ( !CacheMemoryExhausted ) {
        return CachedIcons[icon_index].Cache_It(icon_ptr);
    }
    
    ++CachedIcons[icon_index].TimesFailed;
    
    if ( Optimize_Video_Memory_Cache() ) {
        return CachedIcons[icon_index].Cache_It(icon_ptr);
    }

    return 0;
}

void Invalidate_Cached_Icons (void)
{
    int i;
    
    for (i = 0; i < MAX_CACHED_ICONS; ++i )
    {
        CachedIcons[i].Uncache_It();
    }
    
    memset(IconCacheLookup, -1, sizeof(IconCacheLookup));
    
    for (i = 0; i < MAX_ICON_SETS; ++i )
    {
        IconSetList[i].IconSetPtr = 0;
    }
    
    CacheMemoryExhausted = 0;
}

void Restore_Cached_Icons (void)
{
    for (int i = 0; i < MAX_CACHED_ICONS; ++i )
    {
        CachedIcons[i].Restore();
    }
    
    CacheMemoryExhausted = 0;
}

void Register_Icon_Set (void *icon_data , BOOL pre_cache)
{
  for (int i = 0; i < MAX_ICON_SETS; ++i )
  {
  
    if ( !IconSetList[i].IconSetPtr )
    {
    
      IconSetList[i].IconSetPtr = (IControl_Type *)icon_data;
      
      if ( i )
      {
        IconSetList[i].IconListOffset = IconSetList[i - 1].IconListOffset + IconSetList[i - 1].IconSetPtr->Count;
        if ( IconSetList[i].IconListOffset > 6000 )
        {
          IconSetList[i].IconSetPtr = 0;
        }
      }
      else
      {
        IconSetList[0].IconListOffset = 0;
      }
      
      if ( pre_cache )
      {
          //there is no other name in debug symbols, this could be outside loop?
        for (int j = 0; j < 256; ++j )
        {
          Is_Icon_Cached(icon_data, j);
        }
      }
      
      return;
    }
  }
}

extern "C" int __cdecl Get_Free_Cache_Slot(void) 
{
  for (int i = 0; i < MAX_CACHED_ICONS; ++i) {
      if (!CachedIcons[i].Get_Is_Cached()) {
          return i;
      }
  }
  return -1;
}

IconCacheClass::IconCacheClass (void)
{
	IsCached			=FALSE;
	SurfaceLost		=FALSE;
	DrawFrequency	=0;
	CacheSurface	=NULL;
	IconSource		=NULL;
}

IconCacheClass::~IconCacheClass (void)
{
    if (IsCached){
        if (CacheSurface){
            CacheSurface->Release();
        }
    }
}	

void IconCacheClass::Restore()
{
  if (IsCached) {
  
    if ( CacheSurface ) {
    
      CacheSurface->Restore();
      
      if (IconSource) {
        Cache_It(IconSource);
      }
    }
  }
}	  


int IconCacheClass::Cache_It(void *icon_ptr)
{

    if (!DirectDrawObject) {
      return 0;
    }
    
    memset(&VideoSurfaceDescription, 0, sizeof(DDSURFACEDESC));
    
    VideoSurfaceDescription.dwSize = sizeof(DDSURFACEDESC);
    VideoSurfaceDescription.ddsCaps.dwCaps = DDSCAPS_OFFSCREENPLAIN;
    VideoSurfaceDescription.dwFlags = (DDSD_CAPS | DDSD_HEIGHT | DDSD_WIDTH);
    VideoSurfaceDescription.dwHeight = ICON_HEIGHT;
    VideoSurfaceDescription.dwWidth = ICON_WIDTH;
    
    if (!CacheSurface && DirectDrawObject->CreateSurface(&VideoSurfaceDescription, &CacheSurface, 0) ) {
      CacheMemoryExhausted = 1;
      return 0;
    }

    if (!CacheSurface) {
      return 0;
    }

    DDSCAPS surface_capabilities;
    if (CacheSurface->GetCaps(&surface_capabilities) ) {
        CacheSurface->Release();
        CacheSurface = nullptr;
      return 0;
    }

    if (surface_capabilities.dwCaps & DDSCAPS_SYSTEMMEMORY) {
      CacheSurface->Release();
      CacheSurface = nullptr;
      return 0;
    }

    int return_value = 0;
    
    if (!CacheSurface->Lock(0, &VideoSurfaceDescription, 1, 0)) {
        Cache_Copy_Icon(icon_ptr, VideoSurfaceDescription.lpSurface, VideoSurfaceDescription.lPitch);
        IsCached = 1;
        SurfaceLost = 0;
        return_value = 1;
        IconSource = icon_ptr;
    }
    
    CacheSurface->Unlock(0);
    
    return return_value;
}

void IconCacheClass::Uncache_It()
{
  if ( IsCached ) {
    if ( CacheSurface ) {
      CacheSurface->Release();
      IsCached = 0;
      CacheSurface = 0;
      IconSource = 0;
      CacheMemoryExhausted = 0;
    }
  }
}

void IconCacheClass::Draw_It(LPDIRECTDRAWSURFACE dest_surface , int x_pixel, int y_pixel, int window_left , int window_top , int window_width , int window_height)
{
    char str[100];
    RECT source_rectangle;
    RECT dest_rectangle;
    
    source_rectangle.left = 0;
    source_rectangle.top = 0;
    source_rectangle.right = 24;
    source_rectangle.bottom = 24;
    dest_rectangle.left = window_left + x_pixel;
    dest_rectangle.top = window_top + y_pixel;
    dest_rectangle.right = window_left + x_pixel + 24;
    dest_rectangle.bottom = window_top + y_pixel + 24;
    
    if ( window_left > window_left + x_pixel ) {
        dest_rectangle.left = window_left;
        source_rectangle.left = -x_pixel;
    }
    
    if ( window_left + window_width <= dest_rectangle.right ) {
        source_rectangle.right -= dest_rectangle.right - (window_left + window_width);;
        dest_rectangle.right = window_left + window_width;
    }
    
    if ( window_top > dest_rectangle.top ) {
        source_rectangle.top += window_top - dest_rectangle.top;
        dest_rectangle.top = window_top;
    }
    
    if ( window_top + window_height <= dest_rectangle.bottom ) {
        source_rectangle.bottom -= dest_rectangle.bottom - (window_top + window_height);
        dest_rectangle.bottom = window_top + window_height;
    }
    
    if ( source_rectangle.left < source_rectangle.right && source_rectangle.top < source_rectangle.bottom ) {
        HRESULT return_code = dest_surface->Blt(&dest_rectangle, CacheSurface, &source_rectangle, (DDBLT_WAIT | DDBLT_ASYNC), NULL);
    
        if ( return_code == DDERR_SURFACELOST && Gbuffer_Focus_Loss_Function ) {
            Gbuffer_Focus_Loss_Function();
        }
    
        //string buffer name doesn't exist in symbols, macro or inline?
        if ( return_code != DDERR_SURFACELOST ) {
            if (return_code) {
            sprintf(str, "DD Error code %d\n", HRESULT_CODE(return_code));
            OutputDebugStringA(str);
            }
        }
    
    ++TimesDrawn;
    
    }
}

//
// Prototypes for assembly language procedures in STMPCACH.ASM
//
extern "C" void __cdecl Clear_Icon_Pointers (void) {};
extern "C" int __cdecl Get_Icon_Index (void *icon_ptr) {return 0;};
extern "C" int __cdecl Get_Free_Index (void) {return 0;};
