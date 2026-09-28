# LOT 4 — Seller Product Management

Implemented:
- Seller dashboard with product/stock/visibility statistics.
- Default category seeding.
- Create, edit, activate/deactivate and delete seller-owned products.
- Quick stock +/- controls.
- BIF / USD / EUR pricing.
- Gallery image selection with Android-native compression (no extra Flutter package).
- Image persistence without paid Firebase Storage:
  compressed image bytes are encoded as a bounded data URI in `products.imageRef`.
- Product image preview widget supports Firestore data URIs and HTTP(S) URLs.
- Firestore rules continue to enforce seller ownership and now bound `imageRef`.
- Local codec tests.

## Important deferred runtime checks

Because the physical phone currently has a connectivity issue, LOT 4 is not considered
runtime-certified until a seller account is used on-device to verify:
1. default categories appear,
2. create product,
3. edit product,
4. stock +/-,
5. active/inactive,
6. delete,
7. image pick and persistence after app restart,
8. a different seller cannot edit/delete the product.

The Firestore-image workaround is intentionally small and exam-friendly. Firebase
documents have a strict size ceiling, so selected images are compressed natively on Android and the resulting bytes are limited before Base64 encoding. This avoids enabling paid Firebase Storage.
