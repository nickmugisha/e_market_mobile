# e-market — Exam demonstration script

Use this as a short presentation sequence. Keep one client account and two
seller accounts ready if possible.

## 1. Introduction

Say:

> e-market is a Flutter and Firebase marketplace. It has visitor, client and
> seller flows. Authentication is Firebase Auth, application data is protected
> with Firestore security rules, payments are simulated, and WhatsApp is only
> opened externally for seller contact.

## 2. Visitor demo

1. Launch app and show animated splash.
2. Continue as visitor.
3. Open Marketplace.
4. Search a product.
5. Use a category filter.
6. Open product details.
7. Try a protected action such as Save/Add to cart.
8. Show that authentication is requested.

Key point:

> Visitors can browse freely, but protected client operations require an
> authenticated client account.

## 3. Seller demo

1. Login as Seller A.
2. Open profile and show `Seller`.
3. Open Seller Dashboard.
4. Show existing product list.
5. Add or edit a product.
6. Show category, currency, stock, active visibility and image picker.
7. Toggle product inactive/active.
8. Show seller order list.

Key point:

> Firestore rules restrict product management to the owning seller.

## 4. Client catalogue and saved products

1. Login as Client.
2. Open Marketplace.
3. Open Seller A product.
4. Save it.
5. Open Saved tab.
6. Return to product details.
7. Show seller public information.
8. Open the WhatsApp contact action, then return to the app without sending.

Key point:

> WhatsApp is not an API integration; the app simply opens a pre-filled
> external conversation.

## 5. Cart and currency

1. Add Seller A product.
2. Add another Seller A product.
3. Change quantity.
4. Switch BIF -> USD -> EUR.
5. Show total conversion.
6. Attempt to add Seller B product if time allows.
7. Show single-seller restriction.

Key point:

> The cart is intentionally single seller, which keeps order ownership and
> security simple.

## 6. Checkout

1. Continue to checkout.
2. Show Delivery and Pickup.
3. Show delivery-address validation.
4. Select a simulated payment method.
5. Run the checkout validation.
6. Place the order.

Key point:

> No real money is transferred. The app rechecks current Firebase cart/product
> information before the order is created.

## 7. Client order history

1. Open My Orders.
2. Open the newly created order.
3. Show status, payment, fulfillment and immutable item snapshots.

## 8. Seller order workflow

1. Logout client.
2. Login Seller A.
3. Open Seller Orders.
4. Open the pending order.
5. Note product stock.
6. Confirm order.
7. Show that stock is reduced.
8. Move to Preparing.
9. Move to Ready.
10. Complete order.

If using Cash, point out that payment changes from Pending to Paid at
completion.

Key point:

> Stock is transactionally reserved by the seller at confirmation. This keeps
> seller inventory writes protected by Firestore role rules.

## 9. Security and edge-case explanation

Mention these examples briefly:

- visitor protected actions require login;
- seller WhatsApp is mandatory;
- clients cannot manage seller products;
- sellers cannot access another seller's products/orders;
- quantity above stock is rejected;
- mixed-seller cart is rejected;
- checkout rechecks changed stock/product availability;
- cancellation after stock reservation restores stock;
- saved items are private to their client.

## 10. Free-tier design explanation

Say:

> The project is intentionally kept on Firebase's no-billing setup. Because
> Firebase Storage was not enabled, selected product images are compressed and
> stored as a bounded Base64 image field in Firestore. For a production system
> I would replace that with proper object storage and CDN URLs.

That shows the limitation was deliberate rather than accidental.
