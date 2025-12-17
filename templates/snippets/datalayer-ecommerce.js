// ECOMMERCE DATA LAYER - COPY/PASTE AND MAP TO CLIENT PLATFORM
// Replace IDs, currency, and items dynamically from your storefront

window.dataLayer = window.dataLayer || [];

function pushViewItemList(listName, items) {
  window.dataLayer.push({
    event: 'view_item_list',
    ecommerce: {
      item_list_name: listName,
      items: items
    }
  });
}

function pushViewItem(item) {
  window.dataLayer.push({
    event: 'view_item',
    ecommerce: { items: [item] }
  });
}

function pushAddToCart(item) {
  window.dataLayer.push({
    event: 'add_to_cart',
    ecommerce: {
      currency: 'USD',
      value: item.price * item.quantity,
      items: [item]
    }
  });
}

function pushBeginCheckout(cart) {
  window.dataLayer.push({
    event: 'begin_checkout',
    ecommerce: {
      currency: cart.currency || 'USD',
      value: cart.total,
      items: cart.items
    }
  });
}

function pushPurchase(order) {
  window.dataLayer.push({
    event: 'purchase',
    ecommerce: {
      transaction_id: order.id,
      currency: order.currency || 'USD',
      value: order.total,
      tax: order.tax || 0,
      shipping: order.shipping || 0,
      items: order.items
    }
  });
}

// Example item structure (replace with live data)
// const item = { item_id: 'SKU123', item_name: 'Product Name', price: 49.0, quantity: 1, item_category: 'Category' };
