# Daksha's Creation — jewellery storefront

A responsive, single-file storefront prototype for Daksha's Creation.

## Preview locally
1. Download or clone this repository.
2. Open `index.html` in a modern browser.

No build step is required.

## Included
- Premium, light editorial-style storefront with animated hero artwork
- Category browsing for necklaces, bracelets, nosepins, and earrings
- Product search, category filters, sorting, cart, and demo checkout
- Customer details form and address collection at checkout
- Demo admin panel to add products, edit price/stock, and view local demo orders
- Export of demo data as JSON
- Contact number: 8237824917

## Important: prototype, not ready for real orders
This is a front-end demo. Data is saved in the current browser's localStorage, not a shared database. The admin panel is not secure and uses a visible demo code (`daksha-demo`). Customer records and orders are not available across devices or browsers.

Real phone OTP and email verification are **not implemented**. The demo does not send SMS or email. Before taking real customer details or orders, add a secure backend, authenticated admin access, database, server-side validation, rate limits, and an OTP/email provider. Do not use this demo admin panel to store real customer data.

The checkout QR code is a placeholder. Replace it with the business's correct payment QR image before use, and add a trusted payment/order-confirmation process. Sample products, prices, stock, and abstract jewellery illustrations are placeholders and should be replaced with actual catalogue information and product photos.

## Deployment
GitHub stores the source code; it does not automatically make a website live. For a static demo, GitHub Pages can be configured in repository settings. A production store with OTP, accounts, orders, and secure administration needs backend hosting as well.
