# LOT 5 — Public Catalogue, Search, Filter & Product Details

Implemented:
- Live Firestore marketplace for visitors, clients and sellers.
- Search by product name, description, category and seller.
- Dynamic category filters from Firestore.
- Optional in-stock-only filter.
- Product result count and empty/error states.
- Live "Latest products" section on the home screen.
- Product detail page with image, price, category, live stock, description and seller information.
- Public browsing works without authentication.
- Visitors are prompted to sign in only when they try the future buy/cart action.
- Seller public name and WhatsApp are copied into product documents so public catalogue pages do not expose private user documents.
- Existing LOT 4 products remain readable; editing them once upgrades their public seller fields.
- Pure catalogue filter tests.

Deferred:
- LOT 6: real cart, quantity management, currency conversion and stock validation.
- LOT 7: checkout, delivery/pickup and simulated payment.
- LOT 8: orders and stock deduction.
- LOT 9: saved products and real WhatsApp launch flow.
