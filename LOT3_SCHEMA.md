# e-market — LOT 3 Firestore foundation

## Collections

### `users/{uid}`
Authentication profile. Roles are `client` and `seller`. A user can only read/update their own profile, and role/email/uid/createdAt are immutable after creation.

### `categories/{categoryId}`
Public active catalogue categories. Signed-in sellers can seed missing default categories; categories are otherwise immutable in the current exam scope.

### `products/{productId}`
Seller-owned catalogue data. Public/visitor reads are limited to active products. Sellers can read all of their own products, including inactive products, and can only create/update/delete their own documents.

### `carts/{clientUid}/items/{productId}`
Private client cart. Only the owning client can read/write it. Cart snapshots are checked against the current active product document.

### `orders/{orderId}`
One seller per order. This intentionally simplifies marketplace isolation: a mixed-seller cart will later be split into one order per seller during checkout. The client and that seller can read the order. Only the seller can advance order status.

### `orders/{orderId}/items/{itemId}`
Immutable order line snapshots. They are readable by the order client and seller.

## Currency
`BIF`, `USD`, `EUR` are accepted. Fixed conversion rates remain a LOT 6 concern.

## Product images
`imageRef` is deliberately generic. It can later hold a URL/reference or another no-billing image strategy. Firebase Storage is not enabled because the project must remain on the free/no-billing setup.

## Security status
The rules in this LOT enforce ownership/role isolation and protect seller products, carts, profiles, and order visibility. They are not a trusted payment backend and cannot independently recompute an aggregate order total across subcollection items. Payment remains simulated as required by the exam.

## Deferred mandatory checks
LOT 2 runtime checks remain pending due to the phone connectivity problem: visitor access, protected-action redirect, client registration, seller registration with WhatsApp, logout/login, session persistence, incorrect credentials, Firestore user profile creation, and deployed rules behavior.
