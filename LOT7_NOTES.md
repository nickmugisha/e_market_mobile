# LOT 7 — Checkout, Delivery/Pickup & Simulated Payment

Implemented:
- Checkout page connected to the LOT 6 cart.
- Delivery or pickup selection.
- Delivery address validation.
- Cash, Mobile Money and Card choices.
- Explicitly simulated payment flow: no real money is charged.
- Cash remains `pending`; simulated Mobile Money/Card become `paid`.
- Payment simulation reference generation.
- Checkout currency selector using the LOT 6 BIF-based conversion service.
- Fresh server-side cart read before checkout confirmation.
- Fresh server-side active-product read before checkout confirmation.
- Final stock/availability/single-seller validation before payment simulation.
- A validated `CheckoutDraft` model designed for LOT 8 order creation.
- Checkout summary showing fulfillment, payment, simulation reference and total.
- Unit tests for fulfillment validation, stock changes and simulated payments.

Important boundary:
LOT 7 does NOT create a Firestore order and does NOT decrement stock.
Those transactional operations belong to LOT 8, so an interrupted simulated
checkout cannot create a half-finished order.

Deferred phone/runtime validation:
1. Open cart and continue to checkout.
2. Delivery requires an address.
3. Pickup works without an address.
4. Cash simulation stays pending.
5. Mobile Money/Card simulation reports paid.
6. Change product stock before confirming and verify checkout is stopped.
7. Disable/delete a product before confirming and verify checkout is stopped.
8. Confirm display currency totals.
9. Confirm no real payment app/API is contacted.
