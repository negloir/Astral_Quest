#pragma once

#include <nds.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

// ------------ Game state ------------
typedef struct {
    const char *name;
    int hp;
    int max_hp;
    bool defending;
} Entity;

typedef struct {
    Entity player;
    Entity enemy;
    bool gameOver;
    char lastMsg[96];
} GameState;

// Global-ish state (lives in main.c, referenced from util.c)
extern GameState g;

// ------------ Game API ------------
void game_init(void);
void game_update(void);
void game_draw(void);

// ------------ Utils (implemented in util.c) ------------
int  clampi(int x, int lo, int hi);
int  rand_range(int lo, int hi);
void clear_screen(void);
