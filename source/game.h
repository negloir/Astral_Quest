#pragma once
#ifndef ARM9
#define ARM9 1
#endif
#ifndef __NDS__
#define __NDS__ 1
#endif
#include <nds.h>
#include <stdio.h>

#define GAME_TITLE "Astral Quest: Echoes of the Shards"
#define VERSION_STR "0.1.0-dev"

typedef struct { u16 hp, mp, atk, def, spd; u16 level, exp; } Stats;

typedef struct {
    char name[16];
    Stats stats;
    u32 rng_seed;
} Player;

typedef struct {
    char name[16];
    Stats stats;
    bool isBoss;
} Enemy;

void game_init(void);
void game_loop(void);
void draw_hud(const Player* p, const Enemy* e, int turn);
void draw_text_center(int y, const char* text);
void wait_vblank_and_keys(u16 mask);
u32 xorshift32(u32* state);
int randint(u32* state, int lo, int hi);
void save_profile(const Player* p);
bool load_profile(Player* p);
