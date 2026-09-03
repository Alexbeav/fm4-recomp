// Scoped FM4 startup-media hooks.

#include <rex/ppc.h>

void EnableTurn10MovieSkip(PPCRegister& r29) {
  // The following store writes descriptor + 0x28.
  r29.u64 = 1;
}

void RestoreTurn10MovieMode(PPCRegister& r29) {
  // Do not change the mode used by later movie descriptors.
  r29.u64 = 2;
}

void EnableClarksonVoiceoverSkip(PPCRegister& r3) {
  // The previous instruction loaded the allowskipvoiceover byte into r3.
  r3.u64 = 1;
}
