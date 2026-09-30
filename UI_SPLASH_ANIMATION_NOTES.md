# UI polish — welcoming animated splash

This patch replaces the dark logo splash with a light, custom animated opening.

Visual sequence:
- soft off-white background with restrained blue ambient shapes;
- a clean custom-drawn shopping bag scales into view;
- five short motion strokes fly toward the bag from different directions;
- the bag settles with a tiny controlled bounce;
- three hand-drawn-style highlight strokes reveal below the bag;
- the three underline strokes use different lengths/positions/curves so they
  do not look rigid or parallel;
- `e-market` and `Good finds are on the way.` fade/slide in;
- subtle loading indicators finish the sequence;
- the app then transitions into the existing AuthGate.

Design intent:
- welcoming, light and clean;
- premium enough for an exam presentation without looking over-decorated;
- no copied hand-drawn bag asset: the bag is rendered as a reusable Flutter
  CustomPainter;
- no new package or image asset is required.

Total animation time: about 3.2 seconds.
