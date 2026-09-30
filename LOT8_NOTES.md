# LOT 8 — Orders, History, Seller Workflow & Stock Update

Implemented:
- A validated LOT 7 checkout can now create a real Firestore order.
- Order creation and cart clearing happen in one Firestore transaction.
- Product/cart data is re-read inside the order transaction before commit.
- Order items use the latest live product name/image/price/currency.
- Mixed-currency items are supported; the parent order stores the selected
  display currency and converted display total.
- Client order history and order details.
- Seller incoming-order history and order details.
- Seller status workflow:
  `pending -> confirmed -> preparing -> ready -> completed`
  with cancellation from pending/confirmed/preparing/ready.
- Stock is decremented transactionally when the seller confirms an order.
- Cancelling a previously confirmed/preparing/ready order restores stock.
- Completing a cash order changes its payment status from pending to paid.
- Firestore rules bind client name/phone to the authenticated user profile.
- Firestore rules validate immutable order-item product snapshots against
  live product documents at order creation.
- Order item document IDs equal product IDs to prevent duplicate product
  lines in one order.
- Order policy tests cover workflow, stock reservation/restoration and
  mixed-currency display totals.

Why stock is reserved at seller confirmation instead of client creation:
- The app is Spark/free-tier and has no trusted paid backend/Cloud Function.
- Product writes remain seller-owned in Firestore security rules.
- A client therefore cannot directly decrement seller inventory.
- The seller confirmation transaction is both secure under the role rules
  and still provides transactional stock protection.
- If another order consumes the stock first, seller confirmation fails
  clearly instead of allowing negative stock.

Deferred phone/runtime validation:
1. Client places a real order from checkout.
2. Cart disappears only after successful order creation.
3. Client order history/detail shows the order and its item snapshots.
4. Seller sees only orders belonging to that seller.
5. Seller confirmation decrements stock exactly once.
6. Confirmation fails if live stock is insufficient.
7. Preparing -> Ready -> Completed works.
8. Completing cash marks payment paid.
9. Cancelling before confirmation does not change stock.
10. Cancelling after confirmation restores stock exactly once.
11. Client cannot update order status.
12. Seller cannot read/update another seller's orders.
13. Client cannot read another client's orders.
