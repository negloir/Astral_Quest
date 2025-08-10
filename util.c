#include "game.h"
#include <fat.h>
#include <string.h>

void draw_text_center(int y, const char* text){
    int x = (32 - (int)strlen(text)) / 2;
    if(x < 0) x = 0;
    iprintf("\x1b[%d;%dH%s", y, x, text);
}

void draw_hud(const Player* p, const Enemy* e, int turn){
    iprintf("\x1b[4;1H%-16s L%2d  HP:%3d MP:%3d ATK:%2d DEF:%2d SPD:%2d   ",
        p->name, p->stats.level, p->stats.hp, p->stats.mp, p->stats.atk, p->stats.def, p->stats.spd);
    iprintf("\x1b[6;1H%-16s        HP:%3d              ",
        e->name, e->stats.hp);
    iprintf("\x1b[8;1HTurn: %s                                 ",
        (turn==0) ? "Player" : "Enemy");
    iprintf("\x1b[10;1HSTART=Save  SELECT=Quit                    ");
}

void wait_vblank_and_keys(u16 mask){
    while(1){
        scanKeys();
        if(keysDown() & mask) break;
        swiWaitForVBlank();
    }
}

u32 xorshift32(u32* state){
    u32 x = *state; x ^= x << 13; x ^= x >> 17; x ^= x << 5; *state = x; return x;
}
int randint(u32* state, int lo, int hi){
    if(hi <= lo) return lo;
    u32 r = xorshift32(state); int span = (hi - lo + 1); return lo + (int)(r % (u32)span);
}

static const char* save_path(){
    if(fatInitDefault()){ return "/astral_quest.sav"; }
    return NULL;
}

void save_profile(const Player* p){
    const char* path = save_path(); if(!path) return;
    FILE* f = fopen(path, "wb"); if(!f) return;
    fwrite(p, 1, sizeof(Player), f); fclose(f);
}
bool load_profile(Player* p){
    const char* path = save_path(); if(!path) return false;
    FILE* f = fopen(path, "rb"); if(!f) return false;
    fread(p, 1, sizeof(Player), f); fclose(f);
    if(p->stats.level == 0) return false; return true;
}
