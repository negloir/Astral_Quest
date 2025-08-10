#define ARM9 1
#define __NDS__ 1
#include "game.h"
#include <fat.h>
#include <string.h>
#include <filesystem.h>

static Player gPlayer;
static Enemy  gEnemy;
static int    gTurn = 0; // 0=player,1=enemy
static bool   gRunning = true;

static void init_console() {
    videoSetMode(MODE_0_2D);
    videoSetModeSub(MODE_0_2D);
    consoleDemoInit();
}

static Stats make_stats(u16 lvl, u32* seed) {
    Stats s;
    s.level = lvl;
    s.hp = 40 + lvl*10 + (randint(seed,0,8));
    s.mp = 20 + lvl*4  + (randint(seed,0,5));
    s.atk = 8  + lvl*2 + (randint(seed,0,3));
    s.def = 6  + lvl*2 + (randint(seed,0,3));
    s.spd = 8  + lvl*2 + (randint(seed,0,3));
    s.exp = 0;
    return s;
}

static void spawn_enemy(u32* seed) {
    snprintf(gEnemy.name, sizeof(gEnemy.name), "Wisp");
    gEnemy.stats = make_stats(gPlayer.stats.level, seed);
    gEnemy.isBoss = false;
}

void game_init(void) {
    init_console();
    iprintf("\x1b[1;1H%s v%s\n", GAME_TITLE, VERSION_STR);
    bool nitroOk = nitroFSInit(NULL);
    bool fatOk = fatInitDefault();
    iprintf("Data: NitroFS=%s, FAT=%s\n", nitroOk ? "OK":"--", fatOk ? "OK":"--");
    if(!load_profile(&gPlayer)) {
        strncpy(gPlayer.name, "Hero", sizeof(gPlayer.name));
        gPlayer.rng_seed = 0xA5A5A5A5;
        gPlayer.stats = make_stats(1, &gPlayer.rng_seed);
        save_profile(&gPlayer);
    }
    spawn_enemy(&gPlayer.rng_seed);
    draw_hud(&gPlayer, &gEnemy, gTurn);
}

static void player_turn() {
    draw_text_center(12, "[A] Attack  [B] Guard  [X] Skill");
    scanKeys();
    int down = keysDownRepeat();
    if(down & KEY_A){
        int dmg = (gPlayer.stats.atk + randint(&gPlayer.rng_seed,0,4)) - (gEnemy.stats.def/2);
        if(dmg < 1) dmg = 1;
        if(dmg > gEnemy.stats.hp) dmg = gEnemy.stats.hp;
        gEnemy.stats.hp -= dmg;
        iprintf("\x1b[16;1HYou strike! %d dmg.      ", dmg);
        gTurn = 1;
    } else if(down & KEY_B){
        iprintf("\x1b[16;1HYou brace for impact.      ");
        gPlayer.stats.def += 2;
        gTurn = 1;
    } else if(down & KEY_X){
        if(gPlayer.stats.mp >= 5){
            gPlayer.stats.mp -= 5;
            int dmg = (gPlayer.stats.atk*3/2 + randint(&gPlayer.rng_seed,3,8)) - (gEnemy.stats.def/3);
            if(dmg < 2) dmg = 2;
            if(dmg > gEnemy.stats.hp) dmg = gEnemy.stats.hp;
            gEnemy.stats.hp -= dmg;
            iprintf("\x1b[16;1HArcane Bolt! %d dmg.      ", dmg);
            gTurn = 1;
        } else {
            iprintf("\x1b[16;1HNot enough MP!            ");
        }
    }
}

static void enemy_turn() {
    swiDelay(50000);
    int choice = randint(&gPlayer.rng_seed, 0, 10);
    if(choice < 7){
        int dmg = (gEnemy.stats.atk + randint(&gPlayer.rng_seed,0,3)) - (gPlayer.stats.def/2);
        if(dmg < 1) dmg = 1;
        if(dmg > gPlayer.stats.hp) dmg = gPlayer.stats.hp;
        gPlayer.stats.hp -= dmg;
        iprintf("\x1b[16;1HThe Wisp zaps! %d dmg.     ", dmg);
    } else {
        gEnemy.stats.def += 2;
        iprintf("\x1b[16;1HThe Wisp flickers, guarding.");
    }
    gTurn = 0;
}

void game_loop(void) {
    while(gRunning){
        draw_hud(&gPlayer, &gEnemy, gTurn);
        if(gEnemy.stats.hp == 0){
            iprintf("\x1b[18;1HEnemy defeated! +10 EXP");
            gPlayer.stats.exp += 10;
            if(gPlayer.stats.exp >= 20){
                gPlayer.stats.exp = 0;
                gPlayer.stats.level++;
                gPlayer.stats.hp += 6; gPlayer.stats.mp += 4;
                gPlayer.stats.atk += 2; gPlayer.stats.def += 2; gPlayer.stats.spd += 1;
                iprintf("\x1b[19;1HLevel up! Now %d         ", gPlayer.stats.level);
            }
            spawn_enemy(&gPlayer.rng_seed);
            swiDelay(100000);
        }
        if(gPlayer.stats.hp == 0){
            iprintf("\x1b[18;1HYou fall... Press START to retry");
            scanKeys();
            if(keysDown() & KEY_START){
                gPlayer.stats = (Stats){.hp=40,.mp=20,.atk=8,.def=6,.spd=8,.level=1,.exp=0};
            }
        }
        scanKeys();
        int down = keysDown();
        if(down & KEY_START){ save_profile(&gPlayer); iprintf("\x1b[22;1HSaved.\n"); }
        if(down & KEY_SELECT){ gRunning = false; }
        if(gTurn == 0) player_turn(); else enemy_turn();
        swiWaitForVBlank();
    }
}

int main(void){ game_init(); game_loop(); return 0; }
