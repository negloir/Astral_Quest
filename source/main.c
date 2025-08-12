#include <nds.h>
int main(void){
    // Main screen framebuffer
    videoSetMode(MODE_FB0);
    vramSetBankA(VRAM_A_LCD);
    u16* fb = (u16*)0x06800000;
    for (int i=0;i<256*192;i++) fb[i] = RGB15(31,0,0) | BIT(15); // solid red

    // Bottom screen framebuffer
    videoSetModeSub(MODE_FB0);
    vramSetBankC(VRAM_C_LCD);
    u16* fbSub = (u16*)0x06200000;
    for (int i=0;i<256*192;i++) fbSub[i] = RGB15(0,0,31) | BIT(15); // solid blue

    while(1) swiWaitForVBlank();
}
