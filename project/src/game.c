#include "game.h"
#include <ace/managers/log.h>
#include <ace/managers/mouse.h>
#include <ace/types.h>
#include <ace/managers/viewport/camera.h>
#include <ace/utils/bitmap.h>
#include <ace/utils/extview.h>
#include <ace/utils/palette.h>
#include <ace/managers/key.h>
#include <ace/managers/game.h>
#include <ace/managers/system.h>
#include <ace/managers/viewport/simplebuffer.h>
#include <ace/managers/viewport/scrollbuffer.h>
#include <ace/managers/viewport/tilebuffer.h>
#include <ace/managers/blit.h>


#define TILE_SHIFT 4
#define TILE_SIZE 1 << TILE_SHIFT
#define MAP_SIZE 64


static tView *s_pView; // View containing all the viewports
static tVPort *s_pVpPanel; // Viewport for panel
static tSimpleBufferManager *s_pPanelBuffer;
static tVPort *s_pVpMain; // Viewport for playfield
static tTileBufferManager *s_pMapBuffer;
static tCameraManager *s_pMainCamera;
static tBitMap *s_pMapBitmap;

/*
 * void myTileDrawCallback(UWORD uwTileX, UWORD uwTileY,
 *                         tBitMap *pBitMap, UWORD uwBitMapX, UWORD uwBitMapY) {
 *     _logWrite("Drawing tile %d:%d\n", uwTileX, uwTileY);
 * }
 */

void gameGsCreate(void) {
    logWrite("load view 0\n");
    viewLoad(0);
    logWrite("system use\n");
    systemUse();

    logWrite("Create view\n");
    s_pView = viewCreate(0,
                         TAG_VIEW_GLOBAL_CLUT, 1,
                         TAG_DONE);

    logWrite("Create map\n");
    // create map area
    s_pVpMain = vPortCreate(0,
                            TAG_VPORT_VIEW, s_pView,
                            TAG_VPORT_BPP, 5,
                            TAG_VPORT_HEIGHT, 256 - 48,
                            TAG_END);
    logWrite("Load map palette\n");
    paletteLoad("resources/forest_tileset.plt", s_pVpMain->pPalette, 32);
    
    logWrite("Load map terrain\n");
    s_pMapBitmap = bitmapCreateFromFile("resources/graphics/tilesets/forest/terrain.bm", 0);
    logWrite("Create tilebuffer\n");
    s_pMapBuffer = tileBufferCreate(0,
                                    TAG_TILEBUFFER_VPORT, s_pVpMain,
                                    TAG_TILEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
                                    TAG_TILEBUFFER_BOUND_TILE_X, MAP_SIZE,
                                    TAG_TILEBUFFER_BOUND_TILE_Y, MAP_SIZE,
                                    TAG_TILEBUFFER_TILE_SHIFT, TILE_SHIFT,
                                    TAG_TILEBUFFER_TILESET, s_pMapBitmap,
                                    TAG_TILEBUFFER_REDRAW_QUEUE_LENGTH, 20,
                                    // 16px, 320px wide -> redraw when an entire new line is visible
                                    TAG_END);
    s_pMainCamera = s_pMapBuffer->pCamera;
    logWrite("set camera coords\n");
    cameraSetCoord(s_pMainCamera, 0, 0);

    logWrite("file tile data\n");
    for (int x = 0; x < MAP_SIZE; x++) {
        logWrite("file tile data: line %d\n", x);
        for (int y = 0; y < MAP_SIZE; y++) {
            s_pMapBuffer->pTileData[x][y] = (0x90 + x);
        }
    }

    logWrite("redraw all\n");
    tileBufferRedrawAll(s_pMapBuffer);

    // create panel area
    logWrite("create panel area\n");
    s_pVpPanel = vPortCreate(0,
                             TAG_VPORT_VIEW, s_pView,
                             TAG_VPORT_BPP, 5,
                             TAG_END);
    logWrite("create panel buffer\n");
    s_pPanelBuffer = simpleBufferCreate(0,
                                        TAG_SIMPLEBUFFER_VPORT, s_pVpPanel,
                                        TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
                                        TAG_END);
    paletteLoad("resources/human_panel.plt", s_pVpPanel->pPalette, 32);
    bitmapLoadFromFile(s_pPanelBuffer->pFront, "resources/graphics/ui/human/panel_2.bm", 0, 0);

    // finish up
    logWrite("load view\n");
    viewLoad(s_pView);
    logWrite("unuse system\n");
    systemUnuse();
}

void gameGsLoop(void) {
    // This will loop every frame
    if (keyCheck(KEY_W)) {
        cameraMoveBy(s_pMainCamera, 0, -1);
    }
    if (keyCheck(KEY_S)) {
        cameraMoveBy(s_pMainCamera, 0, 1);
    }
    if (keyCheck(KEY_A)) {
        cameraMoveBy(s_pMainCamera, -1, 0);
    }
    if (keyCheck(KEY_D)) {
        cameraMoveBy(s_pMainCamera, 1, 0);
    }
    if (keyCheck(KEY_ESCAPE)) {
        gameExit();
    }

    if (mouseGetX(MOUSE_PORT_1) > s_pVpMain->uwWidth - 5) {
        cameraMoveBy(s_pMainCamera, 1, 0);
    } else if (mouseGetX(MOUSE_PORT_1) < 5) {
        cameraMoveBy(s_pMainCamera, -1, 0);
    } else if (mouseGetY(MOUSE_PORT_1) < 5) {
        cameraMoveBy(s_pMainCamera, 0, -1);
    } else if (mouseGetY(MOUSE_PORT_1) > s_pVpMain->uwHeight - 5) {
        cameraMoveBy(s_pMainCamera, 0, 1);
    }

    viewProcessManagers(s_pView);
    copProcessBlocks();
    vPortWaitForEnd(s_pVpPanel);
}

void gameGsDestroy(void) {
    systemUse();

    // This will also destroy all associated viewports and viewport managers
    viewDestroy(s_pView);
}
