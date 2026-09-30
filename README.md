# e-market

**e-market** is a Flutter + Firebase e-commerce application developed as a
final-exam project. It supports three usage modes:

- **Visitor** — browse the public catalogue, search/filter products and view
  product details without creating an account.
- **Client** — save products, use a single-seller cart, choose a display
  currency, checkout, place orders, view order history and contact sellers.
- **Seller** — publish/manage products, maintain stock, receive orders and move
  them through the seller workflow.

## Technology

- Flutter / Dart
- Firebase Authentication
- Cloud Firestore
- Android native Kotlin bridge for:
  - selecting/compressing product images;
  - opening the seller WhatsApp contact link.
- No real payment API.
- No real WhatsApp API.
- No paid Firebase service is required by the implementation.

## Firebase project

Project ID:

```text
e-market-ca238
```

Authentication uses Firebase Email/Password.

Firestore rules are stored in:

```text
firestore.rules
```

Deploy them with:

```powershell
firebase deploy --only firestore:rules --project=e-market-ca238
```

## Main application flow

### Visitor

A visitor can:

- open the app without signing in;
- browse active products;
- search products;
- filter by category;
- filter to in-stock products;
- view product details and seller public contact information.

Protected actions such as saving or buying redirect the visitor to
authentication.

### Client

A client can:

- register and sign in;
- edit their name/phone;
- save and remove favorite products;
- add products to a cart;
- change quantities;
- remove/clear cart items;
- select BIF, USD or EUR as the display currency;
- choose delivery or pickup;
- choose Cash, Mobile Money or Card;
- complete a simulated payment step;
- create a Firestore order;
- view order history and order details;
- contact the seller through a pre-filled WhatsApp link.

The cart is deliberately **single seller**. Adding an item from another seller
is rejected until the current cart is cleared.

### Seller

A seller can:

- register with a mandatory WhatsApp number;
- edit profile/contact information;
- create/edit/delete products;
- choose category, price, currency and stock;
- activate/deactivate public visibility;
- choose a product image;
- view incoming orders;
- confirm orders;
- move orders through Preparing -> Ready -> Completed;
- cancel active orders.

Stock is reserved when the seller confirms an order. If a confirmed/preparing/
ready order is cancelled, its reserved stock is restored.

## Currency conversion

LOT 6 uses deterministic fixed rates with **BIF as the pivot**:

```text
1 USD = 2900 BIF
1 EUR = 3150 BIF
```

This makes the exam demo deterministic and also works offline. The values are
display/demo conversion rates, not a financial payment service.

## Simulated payment

The project never charges real money.

- Cash -> payment remains `pending` until the seller completes the order.
- Mobile Money -> simulated as `paid`.
- Card -> simulated as `paid`.

Each simulation creates a local `SIM-...` reference stored on the order.

## Product images and the free Firebase constraint

The project is intentionally kept on Firebase's free/no-billing setup.

Firebase Storage was therefore not enabled. Instead, the Android native image
picker compresses a selected image and the app stores the compressed image as
a bounded Base64 data URI in the product Firestore document.

The implementation limits image size before persistence and Firestore rules
also bound `imageRef`.

This is a deliberate free-tier workaround for the exam project. A production
application should normally use object storage/CDN URLs rather than Base64
images inside Firestore documents.

## Firestore data model

```text
users/{uid}
categories/{categoryId}
products/{productId}

carts/{clientUid}
carts/{clientUid}/items/{productId}

saved/{clientUid}/items/{productId}

orders/{orderId}
orders/{orderId}/items/{productId}
```

One order belongs to one client and one seller.

See `LOT3_SCHEMA.md` for the final field-level overview and security intent.

## Security model

Firestore rules enforce the important role/ownership boundaries:

- users read/update only their own profile;
- role/email/uid remain immutable after registration;
- public users read only active catalogue products;
- sellers manage only their own products;
- clients access only their own cart and saved products;
- clients read only their own orders;
- sellers read only orders assigned to them;
- seller order status changes follow the allowed workflow;
- order items are immutable after creation;
- product/cart/order writes include consistency and stock checks.

Security rules are still not a replacement for a trusted payment backend. The
project uses simulated payment specifically because this is an exam/demo app.

## Local validation

From the project root:

```powershell
flutter pub get --offline
flutter analyze
flutter test
flutter build apk --debug --no-pub
git diff --check
```

A convenience script is included:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\final_qa.ps1
```

Expected result:

```text
FINAL LOCAL QA PASSED.
```

The debug APK is expected at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Device validation

Some Firebase/native behavior cannot be certified only by local unit/static
tests. The full device validation sequence is documented in:

```text
FINAL_PHONE_TEST_CHECKLIST.md
```

This includes authentication, Firestore rules behavior, native image picking,
saved products, cart/checkout, order workflow, stock reservation/restoration
and WhatsApp opening.

## Exam demonstration

Use:

```text
DEMO_SCRIPT.md
```

It gives a short visitor -> seller -> client -> seller demonstration sequence.

## Important limitations

- Payment is simulated.
- WhatsApp is opened externally; the app does not send messages automatically.
- Product images use the Firestore Base64 workaround because paid Firebase
  Storage is intentionally not enabled.
- The application targets an exam/demo scale, not production marketplace load.
- Physical Android runtime validation must still be completed when a test phone
  is available.
