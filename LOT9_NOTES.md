# LOT 9 — WhatsApp, Profiles, Saved Products & Exam Edge Cases

Implemented:
- Client saved/favorite products in Firestore.
- Saved tab now opens a real saved-products page.
- Product details include a live heart action for client accounts.
- Visitors are redirected to authentication before saving.
- Seller accounts cannot use client saved products.
- Product details include a "contact seller" WhatsApp action.
- WhatsApp uses a dependency-free Android native URL launcher.
- The app only opens a pre-filled `wa.me` link; it does not send messages
  automatically and does not use a paid/real WhatsApp API.
- Burundi 8-digit local WhatsApp numbers are normalized to country code 257.
- Profile editing for client and seller accounts.
- Email and role remain immutable.
- Seller WhatsApp remains mandatory.
- Editing a seller name/WhatsApp synchronizes the public seller contact fields
  on existing seller products in the same Firestore batch.
- Firestore rules now support this atomic seller public-profile synchronization
  with `getAfter`.
- Stronger Firestore profile rules require a usable phone number and seller
  WhatsApp value.
- Saved-product rules restrict saved items to the authenticated client owner.
- Pure tests cover WhatsApp normalization/link building and profile validation.

Exam edge cases already handled across LOTs 2–9:
1. Visitor attempts a protected action -> sign-in flow.
2. Seller attempts client-only cart/saved actions -> blocked.
3. Client attempts seller-only product management -> blocked by role/navigation
   and Firestore rules.
4. Out-of-stock product -> add-to-cart disabled/rejected.
5. Quantity above live stock -> rejected.
6. Mixed-seller cart -> rejected.
7. Product hidden/deleted after being added -> cart/checkout warning.
8. Stock changes before checkout/order -> fresh server/transaction validation.
9. Order confirmation with insufficient stock -> rejected.
10. Cancelling a reserved order -> stock restored.
11. Incorrect login credentials -> friendly auth error.
12. Seller WhatsApp missing/invalid -> form/rules reject it.
13. Saved product later hidden/deleted -> no longer shown as purchasable.
14. Manual cross-user cart/order/saved access -> Firestore rules deny it.
15. Seller profile contact changes -> public product contact data stays synced.

Deferred physical-device/runtime validation:
- Native WhatsApp opening and web fallback.
- Save/remove favorites and persistence after app restart.
- Edit client profile.
- Edit seller profile and verify existing products update seller name/WhatsApp.
- Firestore permission-denial checks for saved products and profile updates.
- All previously deferred LOT 2–8 runtime scenarios.

LOT 10 will perform final static QA, README/demo documentation, build checks,
and prepare the complete phone-test script.
