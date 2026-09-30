# e-market — Final Firestore schema and security overview

This document began in LOT 3 and is updated in LOT 10 to describe the final
model implemented across LOTs 3–9.

## `users/{uid}`

Private authenticated profile.

Important fields:

```text
uid
name
email
phone
role                 client | seller
whatsappNumber       mandatory for seller, empty for client
createdAt
updatedAt
```

Security intent:

- the user reads their own profile;
- the user updates their own editable contact fields;
- `uid`, `email`, `role` and `createdAt` remain immutable;
- seller WhatsApp remains required;
- seller profile contact updates are synchronized with public seller contact
  fields on that seller's product documents.

## `categories/{categoryId}`

Catalogue category.

Important fields:

```text
name
description
active
createdAt
```

Active categories are public. Signed-in sellers can create missing categories
for the exam catalogue flow.

## `products/{productId}`

Seller-owned public/private catalogue item.

Important fields:

```text
sellerId
sellerName
sellerWhatsapp
name
description
categoryId
categoryName
price
currency             BIF | USD | EUR
stock
imageRef
active
createdAt
updatedAt
```

Security intent:

- visitors/clients can read active products;
- a seller can also read their own inactive products;
- only the owning seller can create/update/delete the product;
- product `sellerName` / `sellerWhatsapp` must match the seller profile;
- stock cannot be negative;
- the image field is bounded by security rules.

## `carts/{clientUid}`

Parent metadata for the client's current single-seller cart.

Important fields:

```text
clientId
sellerId
updatedAt
```

Only the owning client can access it.

## `carts/{clientUid}/items/{productId}`

Private cart line.

Important fields:

```text
productId
sellerId
productName
imageRef
quantity
unitPrice
currency
addedAt
updatedAt
```

Rules validate the cart line against the current active product, seller,
currency and available stock.

The final implementation uses a **single-seller cart**. It does not split a
mixed-seller cart automatically.

## `saved/{clientUid}/items/{productId}`

Client favorite/saved product.

Important fields:

```text
productId
addedAt
```

Only the owning client can read/write saved products. Saving requires an active
product.

## `orders/{orderId}`

One order belongs to one client and one seller.

Important fields:

```text
clientId
sellerId
clientName
clientPhone
status               pending | confirmed | preparing | ready |
                     completed | cancelled
fulfillmentType      delivery | pickup
paymentMethod        cash | mobile_money | card
paymentStatus        pending | paid | failed
paymentReference
currency             BIF | USD | EUR
total
itemCount
deliveryAddress
createdAt
updatedAt
```

Client creates an order only after checkout validation. The client name/phone
are bound by rules to the authenticated user profile.

Seller status workflow:

```text
pending
  -> confirmed
  -> preparing
  -> ready
  -> completed
```

Cancellation is allowed before completion.

Stock behavior:

- the client order is initially `pending`;
- stock is transactionally decremented when the seller moves
  `pending -> confirmed`;
- insufficient stock blocks confirmation;
- cancellation after reservation restores the stock;
- cancelling a still-pending order does not modify stock.

## `orders/{orderId}/items/{productId}`

Immutable order-line snapshot.

Important fields:

```text
productId
sellerId
productName
imageRef
quantity
unitPrice
subtotal
currency
```

The document ID equals the product ID, preventing duplicate product lines
inside one order.

At creation, Firestore rules validate the line snapshot against the current
product document.

## Currency

Accepted values:

```text
BIF
USD
EUR
```

LOT 6 uses deterministic BIF-pivot display rates:

```text
1 USD = 2900 BIF
1 EUR = 3150 BIF
```

## Product image persistence

Because the project must stay on a no-billing Firebase setup, Firebase Storage
is not enabled.

`imageRef` currently stores a compressed Base64 data URI produced by the
Android native picker/compressor. This is a small exam-scale workaround rather
than the recommended production storage architecture.

## Security scope and limitation

The rules protect ownership, roles, stock bounds, cart isolation, saved-item
isolation, seller product ownership and order visibility/workflow.

Payment is intentionally simulated. Firestore security rules are not treated
as a trusted real-money payment backend.
