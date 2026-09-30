# UI polish — Home header, categories and catalogue cards

This patch continues the post-LOT UI polish without changing business logic.

Home:
- more premium dark greeting header with restrained ambient shapes;
- cleaner profile/cart/notification controls;
- stronger greeting hierarchy and compact account-status badge;
- custom search card instead of a default TextField;
- live horizontal category cards backed by Firestore categories;
- tapping a category opens Marketplace with that category already selected;
- refined section headings around Featured Market and Latest Products.

Marketplace:
- compact dark marketplace hero;
- premium search field;
- animated custom category chips;
- cleaner in-stock filter;
- improved result-count hierarchy;
- spacing tuned to match the new home/splash visual language.

Product cards:
- softer depth/shadow;
- full-bleed product image;
- subtle image gradient for seller-name readability;
- stock pill;
- clearer category / product / price hierarchy;
- seller name remains visible;
- status dot and compact availability label;
- outward-arrow visual cue.

No Firebase schema/rule change is required.
No new dependency is added.
