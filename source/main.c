#include "game.h"
#include <stdlib.h>
#include <time.h>

// Global state
GameState g;

static void seed_rng(void) {
    // Simple seed using time + scanline counter to vary between runs
    uint32_t t = (uint32_t)time(NULL);
    t ^= ((uint32_t)REG_VCOUNT << 16);
    srand(t);
}

void game_init(void) {
    // Minimal, reliable setup for text mode on DS
    consoleDemoInit();   // sets video modes + VRAM + a default console

    // Game state
    g.player = (Entity){ .name = "Hero", .hp = 30, .max_hp = 30, .defending = false };
    g.enemy  = (Entity){ .name = "Wisp", .hp = 20, .max_hp = 20, .defending = false };
    g.gameOver = false;
    g.lastMsg[0] = '\0';

    seed_rng();

    clear_screen();
    iprintf("Astral Quest\n");
    iprintf("-----------------------------\n");
    iprintf("A: Attack  B: Defend  X: Heal\n");
    iprintf("START: Reset   SELECT: Quit\n\n");
}

static void player_turn(u16 keys) {
    if (keys & KEY_A) {
        int dmg = rand_range(3, 8);
        if (g.enemy.defending) dmg = (dmg+1)/2;
        g.enemy.hp -= dmg;
        snprintf(g.lastMsg, sizeof(g.lastMsg), "You attack for %d!", dmg);
        g.enemy.defending = false;
    } else if (keys & KEY_B) {
        g.player.defending = true;
        snprintf(g.lastMsg, sizeof(g.lastMsg), "You brace for impact.");
    } else if (keys & KEY_X) {
        int heal = rand_range(3, 6);
        g.player.hp = clampi(g.player.hp + heal, 0, g.player.max_hp);
        snprintf(g.lastMsg, sizeof(g.lastMsg), "You heal %d HP.", heal);
        g.player.defending = false;
    }
}

static void enemy_turn(void) {
    if (g.enemy.hp <= 0) return;

    int choice = rand_range(0, 9); // 0..9
    if (choice < 7) { // 70% attack
        int dmg = rand_range(2, 6);
        if (g.player.defending) dmg = (dmg+1)/2;
        g.player.hp -= dmg;
        snprintf(g.lastMsg, sizeof(g.lastMsg), "Wisp hits you for %d.", dmg);
        g.player.defending = false;
    } else { // 30% defend
        g.enemy.defending = true;
        snprintf(g.lastMsg, sizeof(g.lastMsg), "Wisp is guarding.");
    }
}

void game_update(void) {
    scanKeys();
    u16 kd = keysDown();

    if (kd & KEY_SELECT) {
        // Hang so emulator can exit the ROM cleanly
        while (1) swiWaitForVBlank();
    }
    if (kd & KEY_START) {
        game_init(); // full reset
        return;
    }

    if (!g.gameOver) {
        if (kd & (KEY_A | KEY_B | KEY_X)) {
            player_turn(kd);
            if (g.enemy.hp <= 0) {
                g.enemy.hp = 0;
                g.gameOver = true;
                snprintf(g.lastMsg, sizeof(g.lastMsg), "You win! START=Reset");
            } else {
                enemy_turn();
                if (g.player.hp <= 0) {
                    g.player.hp = 0;
                    g.gameOver = true;
                    snprintf(g.lastMsg, sizeof(g.lastMsg), "You fell... START=Reset");
                }
            }
        }
    }
}

static void draw_bar(const char* who, int hp, int maxhp) {
    // Simple ASCII HP bar (length 16)
    int filled = (hp * 16 + maxhp/2) / maxhp;
    if (filled < 0) filled = 0;
    if (filled > 16) filled = 16;

    char bar[17];
    for (int i=0;i<16;i++) bar[i] = (i < filled) ? '#' : '.';
    bar[16] = '\0';

    iprintf("%-5s [%s] %2d/%2d\n", who, bar, hp, maxhp);
}

void game_draw(void) {
    clear_screen();
    iprintf("Astral Quest\n");
    iprintf("-----------------------------\n");
    draw_bar("You",   g.player.hp, g.player.max_hp);
    draw_bar("Wisp",  g.enemy .hp, g.enemy .max_hp);
    iprintf("\nA: Attack  B: Defend  X: Heal\n");
    iprintf("START: Reset   SELECT: Quit\n\n");
    if (g.lastMsg[0]) iprintf("%s\n", g.lastMsg);
}

int main(void) {
    game_init();
    while (1) {
        game_update();
        game_draw();
        swiWaitForVBlank();
    }
    return 0;
}
