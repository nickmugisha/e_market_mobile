# LOT 6 — Client Cart, Currency & Stock Validation

Implemented:
- Real client cart persisted in Firestore.
- Client-only cart access.
- Add-to-cart from product details.
- Quantity increase/decrease and remove item.
- Clear cart.
- Server-enforced single-seller cart using the parent `carts/{clientUid}` document.
- Server-enforced stock ceiling in Firestore rules.
- Fresh product/stock checks during cart mutations.
- Cart validation against the live active-product catalogue.
- BIF / USD / EUR display selector.
- Deterministic fixed-rate conversion using BIF as the pivot.
- Converted cart totals.
- Checkout button is enabled only when the cart has no stock/availability issues.
- Checkout itself remains LOT 7.
- Pure tests for currency conversion, single-seller policy, and stock validation.

Fixed demo/fallback rates in LOT 6:
- 1 USD = 2900 BIF
- 1 EUR = 3150 BIF

Deferred runtime validation until a physical phone is available:
1. Client adds first product.
2. Same seller product can be added.
3. Different seller product is rejected.
4. Quantity cannot exceed live stock.
5. Seller reducing stock creates a cart warning.
6. Currency selector changes displayed totals.
7. Cart survives app restart/login persistence.
8. Seller/visitor cannot use client cart.
9. Firestore rules reject manual cross-user cart access.
