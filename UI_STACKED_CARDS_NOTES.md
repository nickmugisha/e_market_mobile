# UI polish — stacked featured cards

This patch changes the Home screen Featured Market section from a flat
horizontal PageView into a tactile stacked card deck.

Interaction:
- the current card sits visibly above the next two cards;
- dragging the top card follows the finger;
- the top card rotates/scales very slightly while dragging;
- the cards underneath rise and scale smoothly as the top card leaves;
- a short swipe snaps back;
- a committed swipe flies the top card off-screen and advances the deck;
- swiping either left or right advances to the next featured card;
- tapping the top card still opens the marketplace.

Visual polish:
- premium dark gradients;
- restrained glow shapes;
- glass-like icon tile;
- collection label;
- strong title hierarchy;
- Explore call-to-action;
- swipe hint;
- animated position dots and `01 / 04` counter.

The normal product grid is intentionally unchanged. The stacked interaction is
used for the large Featured Market cards where it improves presentation
without making product browsing slower.
