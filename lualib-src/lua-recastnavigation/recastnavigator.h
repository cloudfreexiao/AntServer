#ifndef __Recast__Navigator__
#define __Recast__Navigator__
#include <stdlib.h>
#include <stdio.h>
#include "Recast.h"
#include "DetourNavMesh.h"
#include "DetourNavMeshBuilder.h"
#include "DetourNavMeshQuery.h"

class CNavigator
{
public:
    CNavigator();
    ~CNavigator();
    
public:
    bool    init(const char *pszFile, float walkableHeight, float walkableRadius, float walkableClimb,
                float fscale, float fstep = 0.5f, float fslop = 0.01f, int maxSearchNode = 2048);
    
    bool    queryPath(float *spos, float *epos, int steps, float *result, int *nresult);
    
    void    setExclude(int flag);

    unsigned short getExclude();
    
    
//private:
    bool    _loadMeshFromFile(const char *pszFile);
    char*   _parseRow(char* buf, char* bufEnd, char* row, int len);
    bool    _initFilter();
    
public:
    unsigned short* m_verts;
    unsigned short* m_polys;
    unsigned short* m_flags;
    unsigned char*  m_areas;
    
    dtNavMeshCreateParams params;
    
    dtNavMesh*      m_navMesh;
    dtNavMeshQuery* m_navQuery;
    dtQueryFilter   m_filter;
    
    float m_polyPickExt[3];
    float m_scale;
    float m_stepSize;
    float m_slop;
    float m_walkableHeight;
    float m_walkableRadius;
    float m_walkableClimb;
};
#endif /* defined(__RecastDemo__Navigator__) */