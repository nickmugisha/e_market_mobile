# e-market — Final physical phone test checklist

Run this checklist when an Android phone is available again.

Do not skip directly to checkout. Test in order because later scenarios depend
on accounts/products created earlier.

## A. Environment and launch

- [ ] `flutter devices --no-version-check` detects the Android phone.
- [ ] Phone has working internet.
- [ ] USB debugging is authorized.
- [ ] Run:

```powershell
flutter --no-version-check run -d <DEVICE_ID>
```

- [ ] Splash animation appears correctly.
- [ ] No startup crash.
- [ ] Firebase initializes.
- [ ] UI fits the phone without overflow.

## B. Visitor flow

- [ ] Continue as visitor without authentication.
- [ ] Home screen loads.
- [ ] Marketplace opens.
- [ ] Active seller products are visible.
- [ ] Search by product name works.
- [ ] Search by seller/category text works.
- [ ] Category filter works.
- [ ] `In stock only` works.
- [ ] Product detail opens.
- [ ] Inactive products are not publicly visible.
- [ ] Visitor presses Save -> authentication is requested.
- [ ] Visitor presses Add to cart -> authentication is requested.

## C. Client registration and authentication

Create or use a dedicated client test account.

- [ ] Sign-up accepts name/email/phone/password.
- [ ] Client does not need a seller WhatsApp number.
- [ ] Registration succeeds.
- [ ] `users/{uid}` exists in Firestore.
- [ ] Firestore role is exactly `client`.
- [ ] Logout succeeds.
- [ ] Login succeeds.
- [ ] Incorrect password shows a friendly error.
- [ ] Close/reopen app while signed in -> session persists.
- [ ] Password reset action does not crash.

## D. Seller registration and authentication

Create or use a separate seller test account.

- [ ] Choose Seller during registration.
- [ ] Seller WhatsApp field is required.
- [ ] Invalid/missing WhatsApp is rejected.
- [ ] Registration succeeds with valid details.
- [ ] `users/{uid}` role is `seller`.
- [ ] Seller profile contains WhatsApp.
- [ ] Profile visibly identifies the account as Seller.
- [ ] Seller dashboard opens.

## E. Seller product management

From the seller account:

- [ ] Default categories exist after seller dashboard opens.
- [ ] Create a product with:
  - name;
  - description;
  - category;
  - price;
  - currency;
  - stock greater than 0;
  - image;
  - active = on.
- [ ] Native image picker opens.
- [ ] Selected image appears correctly after save.
- [ ] Product appears in seller dashboard.
- [ ] Product appears publicly in Marketplace.
- [ ] Edit name/description/price/stock.
- [ ] Changes appear publicly.
- [ ] Stock decrement/increment controls work.
- [ ] Stock cannot become negative.
- [ ] Set product inactive -> disappears from public marketplace.
- [ ] Set active again -> reappears.
- [ ] Create a second product under the same seller.

For the mixed-seller cart test, create a second seller account and at least one
active product owned by that second seller.

## F. Seller profile editing

Using a seller with existing products:

- [ ] Open Edit profile.
- [ ] Change seller display name.
- [ ] Change seller WhatsApp.
- [ ] Save succeeds.
- [ ] Seller `users/{uid}` updates.
- [ ] Existing product documents update `sellerName`.
- [ ] Existing product documents update `sellerWhatsapp`.
- [ ] Product details show the new public seller information.

## G. Client saved products

Login as the client.

- [ ] Open an active product.
- [ ] Tap heart/save.
- [ ] Product appears in Saved.
- [ ] Restart/reopen app -> saved item persists.
- [ ] Remove from Saved.
- [ ] It disappears.
- [ ] Save a product, then seller hides it.
- [ ] Hidden product is no longer shown as a purchasable saved item.

## H. WhatsApp contact

From product details:

- [ ] Contact seller action is visible when seller WhatsApp exists.
- [ ] Tap it.
- [ ] WhatsApp opens if installed, otherwise the phone/browser handles the
  `wa.me` link.
- [ ] Correct seller number is used.
- [ ] Pre-filled message mentions the product.
- [ ] App does not automatically send a message.

## I. Client cart

Login as the client.

- [ ] Add seller A product to cart.
- [ ] Add another seller A product.
- [ ] Cart persists.
- [ ] Increase quantity.
- [ ] Decrease quantity.
- [ ] Quantity cannot exceed current product stock.
- [ ] Remove one item.
- [ ] Add it again.
- [ ] Attempt to add seller B product while seller A items exist.
- [ ] Mixed-seller add is rejected with a clear message.
- [ ] Clear cart works.
- [ ] After clear, seller B product can be added.
- [ ] Rebuild seller A cart for checkout tests.

## J. Currency display

With items in the client cart:

- [ ] BIF display works.
- [ ] USD display works.
- [ ] EUR display works.
- [ ] Totals change consistently when currency changes.
- [ ] Product's stored currency remains unchanged.

## K. Checkout

- [ ] Continue from valid cart to Checkout.
- [ ] Select Delivery.
- [ ] Empty/too-short delivery address is rejected.
- [ ] Valid delivery address is accepted.
- [ ] Select Pickup -> address is no longer required.
- [ ] Cash simulation returns pending.
- [ ] Mobile Money simulation reports paid.
- [ ] Card simulation reports paid.
- [ ] No real payment application/API is contacted.

Stock-change test:

- [ ] Client reaches checkout.
- [ ] Seller reduces product stock below cart quantity.
- [ ] Client reruns checkout check.
- [ ] Checkout is stopped with a stock warning.

Product-availability test:

- [ ] Client reaches checkout.
- [ ] Seller disables/deletes product.
- [ ] Client reruns checkout check.
- [ ] Checkout is stopped.

## L. Real order creation

With a valid cart/checkout:

- [ ] Press Place order.
- [ ] Firestore `orders/{orderId}` is created.
- [ ] Order item snapshot(s) exist.
- [ ] Parent order belongs to correct client/seller.
- [ ] Cart is cleared only after successful order creation.
- [ ] Client order history shows the new order.
- [ ] Client order detail shows items, fulfillment, payment and total.
- [ ] Client cannot change order status.

## M. Seller incoming orders and stock reservation

Login as the order's seller.

- [ ] Seller order list contains the order.
- [ ] Seller can open order details.
- [ ] Seller sees correct client/item details.
- [ ] Before confirmation, note current product stock.
- [ ] Confirm order.
- [ ] Status becomes Confirmed.
- [ ] Product stock decreases exactly once by ordered quantity.
- [ ] Reopening/refreshing does not decrement stock again.
- [ ] Move Confirmed -> Preparing.
- [ ] Move Preparing -> Ready.
- [ ] Move Ready -> Completed.
- [ ] Cash order completion changes payment status Pending -> Paid.

## N. Cancellation and stock restoration

Create another order for this test.

Pending cancellation:

- [ ] Cancel while still Pending.
- [ ] Status becomes Cancelled.
- [ ] Product stock is unchanged.

Reserved cancellation:

- [ ] Create another order.
- [ ] Seller confirms it.
- [ ] Verify stock decreases.
- [ ] Cancel while Confirmed/Preparing/Ready.
- [ ] Verify stock is restored exactly once.
- [ ] Cancelled order cannot continue through workflow.

## O. Security/ownership checks

Use separate client/seller accounts where practical.

- [ ] Client A cannot read Client B private cart.
- [ ] Client A cannot read Client B saved products.
- [ ] Client A cannot read Client B orders.
- [ ] Client cannot write seller products.
- [ ] Client cannot manually update order status.
- [ ] Seller A cannot edit/delete Seller B product.
- [ ] Seller A cannot read/update Seller B order.
- [ ] Seller cannot use client cart/saved UI.
- [ ] User cannot change role/email/uid through profile editing.

## P. Final visual and stability pass

- [ ] No overflow warnings.
- [ ] No red Flutter error screen.
- [ ] Back navigation behaves correctly.
- [ ] Bottom navigation behaves correctly.
- [ ] Empty states are readable.
- [ ] Loading states are readable.
- [ ] Error snackbars/dialogs are understandable.
- [ ] Product images render correctly.
- [ ] App remains usable after logout/login.
- [ ] Final demo accounts/products are left in a presentable state.

When every item above passes, the deferred runtime validation for LOTs 2–9 can
be considered complete.
