//
//  Navigator.cpp
//  RecastDemo
//
//  Created by wenjie on 8/27/15.
//
//
#include <string.h>
#include <math.h>
#include <assert.h>
#include "recastnavigator.h"

#include "RecastAlloc.h"
#include "RecastAssert.h"
#include "DetourCommon.h"

#define MAX_POLYS  256

CNavigator::CNavigator()
: m_verts(0)
, m_polys(0)
, m_flags(0)
, m_areas(0)
, m_navMesh(0)
, m_navQuery(0)
, m_scale(1.0f)
, m_stepSize(0.5f)
, m_slop(0.01f)
{
    m_polyPickExt[0] = 2.0f;
    m_polyPickExt[1] = 4.0f;
    m_polyPickExt[2] = 2.0f;
}

CNavigator::~CNavigator()
{
    if (m_verts) {
        rcFree(m_verts);
        m_verts = 0;
    }
    
    if (m_polys) {
        rcFree(m_polys);
        m_polys = 0;
    }
    
    if (m_areas) {
        rcFree(m_areas);
        m_areas = 0;
    }
    
    if (m_flags) {
        rcFree(m_flags);
        m_flags = 0;
    }
    
    if (m_navMesh) {
        dtFreeNavMesh(m_navMesh);
        m_navMesh = 0;
    }
    
    
    if (m_navQuery) {
        dtFreeNavMeshQuery(m_navQuery);
        m_navQuery = 0;
    }
}



char* CNavigator::_parseRow(char* buf, char* bufEnd, char* row, int len)
{
    bool start = true;
    bool done = false;
    int n = 0;
    while (!done && buf < bufEnd)
    {
        char c = *buf;
        buf++;
        // multirow
        switch (c)
        {
            case '\n':
                if (start) break;
                done = true;
                break;
            case '\r':
                break;
            case '\t':
            case ' ':
                if (start) break;
            default:
                start = false;
                row[n++] = c;
                if (n >= len-1)
                    done = true;
                break;
        }
    }
    row[n] = '\0';
    return buf;
}

bool CNavigator::_loadMeshFromFile(const char *pszFile)
{
    const int nvp = 6;
    char * buf = 0;
    FILE *fp = fopen(pszFile, "rb");
    if (!fp)
        return false;
    
    fseek(fp, 0, SEEK_END);
    int bufSize = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    buf = (char*)malloc(bufSize*sizeof(char));
    
    if (!buf) {
        fclose(fp);
        return false;
    }
    
    size_t readLen = fread(buf, bufSize, 1, fp);
    fclose(fp);
    
    if (readLen != 1) {
        free(buf);
        buf = 0;
        return false;
    }
    
    int vertCount = 0;
    int polyCount = 0;

    char *src = buf;
    char *srcEnd = src + bufSize;
    char row[256];
    
    //counters
    row[0] = '\0';
    src = _parseRow(src, srcEnd, row, sizeof(row)/sizeof(char));
    sscanf(row, "%d %d", &vertCount, &polyCount);
    
    if (vertCount <= 0 || polyCount <= 0)
        goto ERR;
    
    if (vertCount >= 0xfffe)
        goto ERR;
   
    //bounds
    float bmin[3];
    float bmax[3];
    row[0] = '\0';
    src = _parseRow(src, srcEnd, row, sizeof(row)/sizeof(char));
    sscanf(row, "%f %f %f %f %f %f", &bmin[0], &bmin[1], &bmin[2], &bmax[0], &bmax[1], &bmax[2]);
    
    
    m_verts = (unsigned short*)rcAlloc(sizeof(unsigned short)*vertCount*3, RC_ALLOC_PERM);
    if (!m_verts)
        goto ERR;
    
    m_polys = (unsigned short*)rcAlloc(sizeof(unsigned short)*polyCount*nvp*2, RC_ALLOC_PERM);
    if (!m_polys)
        goto ERR;

    m_areas = (unsigned char*)rcAlloc(sizeof(unsigned char)*polyCount, RC_ALLOC_PERM);
    if (!m_areas)
        goto ERR;
    
    m_flags = (unsigned short*)rcAlloc(sizeof(unsigned char)*polyCount, RC_ALLOC_PERM);
    if (!m_flags)
        goto ERR;
    
    {
    memset(m_verts, 0, sizeof(unsigned short)*vertCount*3);
    memset(m_polys, 0xff, sizeof(unsigned short)*polyCount*nvp*2);
    memset(m_areas, 0, sizeof(unsigned char)*polyCount);
    memset(m_flags, 0, sizeof(unsigned char)*polyCount);
    
    int nv = 0;
    int np = 0;
    while (src < srcEnd)
    {
        row[0] = '\0';
        src = _parseRow(src, srcEnd, row, sizeof(row)/sizeof(char));
        if (row[0] == 'v')
        {
            float x,y,z;
            sscanf(row+1, "%f %f %f", &x, &y, &z);
            unsigned short *p = &m_verts[nv*3];
            p[0] = (unsigned short)(floorf(x));
            p[1] = (unsigned short)(floorf(y));
            p[2] = (unsigned short)(floorf(z));
            
            nv++;
        }
        else if (row[0] == 'f')
        {
            unsigned short p0, p1, p2;
            unsigned short n0, n1, n2, n3, n4, n5;
            unsigned short area;
            sscanf(row+1, "%hd %hd %hd %hd %hd %hd %hd %hd %hd %hd", &p0, &p1, &p2, &n0, &n1, &n2, &n3, &n4, &n5, &area);
            
            unsigned short* p = &m_polys[np*nvp*2];
            p[0] = p0;
            p[1] = p1;
            p[2] = p2;
            
            //neibours
            p[6] = n0;
            p[7] = n1;
            p[8] = n2;
            p[9] = n3;
            p[10] = n4;
            p[11] = n5;

            
            m_areas[np] = (unsigned char)area;
            
            assert(area<sizeof(unsigned short));
            
            unsigned short flag = 0x01;
            for (int i=0; i<area; i++){
                flag = flag<<1;
            }
            m_flags[np] = flag;
            
            np++;
        }
    }
    
    memset(&params, 0, sizeof(params));
    rcVcopy(params.bmin, bmin);
    rcVcopy(params.bmax, bmax);
    params.verts = m_verts;
    params.vertCount = vertCount;
    params.polys = m_polys;
    params.polyAreas = m_areas;
    params.polyFlags = m_flags;
    params.polyCount = polyCount;
    params.nvp = nvp;
    params.walkableHeight = m_walkableHeight;
    params.walkableRadius = m_walkableRadius;
    params.walkableClimb = m_walkableClimb;
    params.cs = m_scale;
    params.ch = m_scale;
    params.buildBvTree = true;
    
    free(buf);
    buf = 0;
    return true;
    }
ERR:
    if(buf)
    {
        free(buf);
        buf = 0;
    }

    return false;
}

bool CNavigator::_initFilter()
{
    int si = sizeof(unsigned short);
    for (int i = 0; i<si; i++)
        m_filter.setAreaCost(i, 1.0f);
    
    m_filter.setIncludeFlags(0xffff);
    m_filter.setExcludeFlags(0xfffe);
    
    return true;
}

bool CNavigator::init(const char *pszFile, float walkableHeight, float walkableRadius, float walkableClimb, float fscale,
                      float fstep, float fslop, int maxSearchNode)
{
    assert(pszFile);
    assert(fscale > 0 && fstep > 0 && fslop > 0);
    assert(walkableHeight > 0 && walkableRadius > 0 && walkableClimb > 0);
    
    m_scale = fscale;
    m_slop  = fslop;
    m_stepSize  = fstep;
    m_walkableHeight = walkableHeight;
    m_walkableRadius = walkableRadius;
    m_walkableClimb  = walkableClimb;
    
    bool suc = _loadMeshFromFile(pszFile);
    if (!suc)
        return false;
    
    unsigned char* navData = 0;
    int navDataSize = 0;
    suc = dtCreateNavMeshData(&params, &navData, &navDataSize);
    if (!suc)
        return false;
    
    m_navMesh = dtAllocNavMesh();
    if (!m_navMesh)
        return false;
    
    dtStatus status;
    status = m_navMesh->init(navData, navDataSize, DT_TILE_FREE_DATA);
    if (dtStatusFailed(status))
        return false;
    
    m_navQuery = dtAllocNavMeshQuery();
    status = m_navQuery->init(m_navMesh, maxSearchNode);
    if (dtStatusFailed(status))
        return false;
    
    suc = _initFilter();
    if (!suc)
        return false;
    
    return true;
}


inline bool inRange(const float* v1, const float* v2, const float r, const float h)
{
    const float dx = v2[0] - v1[0];
    const float dy = v2[1] - v1[1];
    const float dz = v2[2] - v1[2];
    return (dx*dx + dz*dz) < r*r && fabsf(dy) < h;
}


static int fixupCorridor(dtPolyRef* path, const int npath, const int maxPath,
                         const dtPolyRef* visited, const int nvisited)
{
    int furthestPath = -1;
    int furthestVisited = -1;
    
    // Find furthest common polygon.
    for (int i = npath-1; i >= 0; --i)
    {
        bool found = false;
        for (int j = nvisited-1; j >= 0; --j)
        {
            if (path[i] == visited[j])
            {
                furthestPath = i;
                furthestVisited = j;
                found = true;
            }
        }
        if (found)
            break;
    }
    
    // If no intersection found just return current path.
    if (furthestPath == -1 || furthestVisited == -1)
        return npath;
    
    // Concatenate paths.
    
    // Adjust beginning of the buffer to include the visited.
    const int req = nvisited - furthestVisited;
    const int orig = rcMin(furthestPath+1, npath);
    int size = rcMax(0, npath-orig);
    if (req+size > maxPath)
        size = maxPath-req;
    if (size)
        memmove(path+req, path+orig, size*sizeof(dtPolyRef));
    
    // Store visited
    for (int i = 0; i < req; ++i)
        path[i] = visited[(nvisited-1)-i];
    
    return req+size;
}

// This function checks if the path has a small U-turn, that is,
// a polygon further in the path is adjacent to the first polygon
// in the path. If that happens, a shortcut is taken.
// This can happen if the target (T) location is at tile boundary,
// and we're (S) approaching it parallel to the tile edge.
// The choice at the vertex can be arbitrary,
//  +---+---+
//  |:::|:::|
//  +-S-+-T-+
//  |:::|   | <-- the step can end up in here, resulting U-turn path.
//  +---+---+
static int fixupShortcuts(dtPolyRef* path, int npath, dtNavMeshQuery* navQuery)
{
    if (npath < 3)
        return npath;
    
    // Get connected polygons
    static const int maxNeis = 16;
    dtPolyRef neis[maxNeis];
    int nneis = 0;
    
    const dtMeshTile* tile = 0;
    const dtPoly* poly = 0;
    if (dtStatusFailed(navQuery->getAttachedNavMesh()->getTileAndPolyByRef(path[0], &tile, &poly)))
        return npath;
    
    for (unsigned int k = poly->firstLink; k != DT_NULL_LINK; k = tile->links[k].next)
    {
        const dtLink* link = &tile->links[k];
        if (link->ref != 0)
        {
            if (nneis < maxNeis)
                neis[nneis++] = link->ref;
        }
    }
    
    // If any of the neighbour polygons is within the next few polygons
    // in the path, short cut to that polygon directly.
    static const int maxLookAhead = 6;
    int cut = 0;
    for (int i = dtMin(maxLookAhead, npath) - 1; i > 1 && cut == 0; i--) {
        for (int j = 0; j < nneis; j++)
        {
            if (path[i] == neis[j]) {
                cut = i;
                break;
            }
        }
    }
    if (cut > 1)
    {
        int offset = cut-1;
        npath -= offset;
        for (int i = 1; i < npath; i++)
            path[i] = path[i+offset];
    }
    
    return npath;
}

static bool getSteerTarget(dtNavMeshQuery* navQuery, const float* startPos, const float* endPos,
                           const float minTargetDist,
                           const dtPolyRef* path, const int pathSize,
                           float* steerPos, unsigned char& steerPosFlag, dtPolyRef& steerPosRef,
                           float* outPoints = 0, int* outPointCount = 0)
{
    // Find steer target.
    static const int MAX_STEER_POINTS = 3;
    float steerPath[MAX_STEER_POINTS*3];
    unsigned char steerPathFlags[MAX_STEER_POINTS];
    dtPolyRef steerPathPolys[MAX_STEER_POINTS];
    int nsteerPath = 0;
    navQuery->findStraightPath(startPos, endPos, path, pathSize,
                               steerPath, steerPathFlags, steerPathPolys, &nsteerPath, MAX_STEER_POINTS);
    if (!nsteerPath)
        return false;
    
    if (outPoints && outPointCount)
    {
        *outPointCount = nsteerPath;
        for (int i = 0; i < nsteerPath; ++i)
            dtVcopy(&outPoints[i*3], &steerPath[i*3]);
    }
    
    
    // Find vertex far enough to steer to.
    int ns = 0;
    while (ns < nsteerPath)
    {
        // Stop at Off-Mesh link or when point is further than slop away.
        if ((steerPathFlags[ns] & DT_STRAIGHTPATH_OFFMESH_CONNECTION) ||
            !inRange(&steerPath[ns*3], startPos, minTargetDist, 1000.0f))
            break;
        ns++;
    }
    // Failed to find good point to steer to.
    if (ns >= nsteerPath)
        return false;
    
    dtVcopy(steerPos, &steerPath[ns*3]);
    steerPos[1] = startPos[1];
    steerPosFlag = steerPathFlags[ns];
    steerPosRef = steerPathPolys[ns];
    
    return true;
}


bool CNavigator::queryPath(float *spos, float *epos, int steps, float *result, int *nresult)
{
    assert(m_navMesh && m_navQuery && nresult);
    assert(spos && epos && result);
    assert(steps > 0 && steps <= 2048);
    
    dtPolyRef startRef = 0;
    dtPolyRef endRef = 0;
    *nresult = 0;
    
    m_navQuery->findNearestPoly(spos, m_polyPickExt, &m_filter, &startRef, 0);
    m_navQuery->findNearestPoly(epos, m_polyPickExt, &m_filter, &endRef, 0);
    
    if (!startRef || !endRef)
        return false;
    

    dtPolyRef polys[MAX_POLYS] = {0};
    int npolys = 0;
    m_navQuery->findPath(startRef, endRef, spos, epos, &m_filter, polys, &npolys, MAX_POLYS);
    if (!npolys)
        return false;
    
    float iterPos[3], targetPos[3];
    m_navQuery->closestPointOnPoly(startRef, spos, iterPos, 0);
    m_navQuery->closestPointOnPoly(polys[npolys-1], epos, targetPos, 0);
    
    int nstep = 0;
    dtVcopy(&result[nstep*3], iterPos);
    nstep ++;
    
    while (npolys && nstep < steps) {
        float steerPos[3];
        unsigned char steerPosFlag;
        dtPolyRef steerPosRef;
        
        bool suc = getSteerTarget(m_navQuery, iterPos, targetPos, m_slop, polys, npolys, steerPos, steerPosFlag, steerPosRef);
        if (!suc)
            break;
        
        bool endOfPath = (steerPosFlag & DT_STRAIGHTPATH_END) ? true : false;
        bool offMeshConnection = (steerPosFlag & DT_STRAIGHTPATH_OFFMESH_CONNECTION) ? true : false;
        
        float delta[3], len;
        dtVsub(delta, steerPos, iterPos);
        len = dtMathSqrtf(dtVdot(delta,  delta));
        if ((endOfPath || offMeshConnection))
            len = 1;
        else
            len = m_stepSize / len;
        
        float moveTgt[3];
        dtVmad(moveTgt, iterPos, delta, len);
        
        //Move
        float res[3];
        dtPolyRef  visited[16];
        int nvisited = 0;
        m_navQuery->moveAlongSurface(polys[0], iterPos, moveTgt, &m_filter, res, visited, &nvisited, 16);
        npolys = fixupCorridor(polys, npolys, MAX_POLYS, visited, nvisited);
        npolys = fixupShortcuts(polys, npolys, m_navQuery);
        
        float h = 0;
        m_navQuery->getPolyHeight(polys[0], res, &h);
        res[1] = h;
        dtVcopy(iterPos, res);
        
        if (endOfPath && inRange(iterPos, steerPos, m_slop, 1.0f)) {
            dtVcopy(iterPos, targetPos);
            if (nstep < steps) {
                dtVcopy(&result[nstep*3], iterPos);
                nstep ++;
            }
            break;
        }
        else if (offMeshConnection && inRange(iterPos, steerPos, m_slop, 1.0f))
        {
            //not supported
        }
        
        if (nstep < steps) {
            dtVcopy(&result[nstep*3], iterPos);
            nstep ++;
        }
    }
    
    
    *nresult = nstep;
    
    return true;
}

void CNavigator::setExclude(int flag)
{
    unsigned short flags = getExclude();
    unsigned short f = 0x01;
    f = (~(f<<flag)) & flags;
    m_filter.setExcludeFlags(f);
}

unsigned short CNavigator::getExclude()
{
    return m_filter.getExcludeFlags();
}








