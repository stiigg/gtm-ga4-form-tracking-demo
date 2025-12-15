<?php
/**
 * WooCommerce GA4 Enhanced Ecommerce Tracking
 * Add to theme's functions.php or custom plugin
 */

// View Item - Product Page
add_action('woocommerce_after_single_product', 'ga4_view_item');
function ga4_view_item() {
    global $product;
    ?>
    <script>
    dataLayer.push({ecommerce: null});
    dataLayer.push({
        event: 'view_item',
        ecommerce: {
            currency: '<?php echo get_woocommerce_currency(); ?>',
            value: <?php echo $product->get_price(); ?>,
            items: [{
                item_id: '<?php echo $product->get_sku(); ?>',
                item_name: '<?php echo $product->get_name(); ?>',
                item_category: '<?php echo strip_tags(wc_get_product_category_list($product->get_id())); ?>',
                price: <?php echo $product->get_price(); ?>,
                quantity: 1
            }]
        }
    });
    </script>
    <?php
}

// Add to Cart - AJAX and standard
add_action('woocommerce_after_add_to_cart_button', 'ga4_add_to_cart_js');
function ga4_add_to_cart_js() {
    global $product;
    ?>
    <script>
    jQuery(document).ready(function($) {
        $('form.cart').on('submit', function(e) {
            var quantity = $(this).find('input[name="quantity"]').val() || 1;
            dataLayer.push({ecommerce: null});
            dataLayer.push({
                event: 'add_to_cart',
                ecommerce: {
                    currency: '<?php echo get_woocommerce_currency(); ?>',
                    value: <?php echo $product->get_price(); ?> * quantity,
                    items: [{
                        item_id: '<?php echo $product->get_sku(); ?>',
                        item_name: '<?php echo $product->get_name(); ?>',
                        price: <?php echo $product->get_price(); ?>,
                        quantity: quantity
                    }]
                }
            });
        });
    });
    </script>
    <?php
}

// Begin Checkout
add_action('woocommerce_before_checkout_form', 'ga4_begin_checkout');
function ga4_begin_checkout() {
    $cart_total = WC()->cart->get_cart_contents_total();
    $cart_items = [];
    
    foreach (WC()->cart->get_cart() as $cart_item) {
        $product = $cart_item['data'];
        $cart_items[] = [
            'item_id' => $product->get_sku(),
            'item_name' => $product->get_name(),
            'price' => $product->get_price(),
            'quantity' => $cart_item['quantity']
        ];
    }
    ?>
    <script>
    dataLayer.push({ecommerce: null});
    dataLayer.push({
        event: 'begin_checkout',
        ecommerce: {
            currency: '<?php echo get_woocommerce_currency(); ?>',
            value: <?php echo $cart_total; ?>,
            items: <?php echo json_encode($cart_items); ?>
        }
    });
    </script>
    <?php
}

// Purchase - Thank You Page
add_action('woocommerce_thankyou', 'ga4_purchase_event');
function ga4_purchase_event($order_id) {
    $order = wc_get_order($order_id);
    
    // Prevent duplicate firing on page refresh
    if (get_post_meta($order_id, '_ga4_purchase_tracked', true)) {
        return;
    }
    
    $order_items = [];
    foreach ($order->get_items() as $item) {
        $product = $item->get_product();
        $order_items[] = [
            'item_id' => $product->get_sku(),
            'item_name' => $product->get_name(),
            'price' => $item->get_total() / $item->get_quantity(),
            'quantity' => $item->get_quantity()
        ];
    }
    ?>
    <script>
    dataLayer.push({ecommerce: null});
    dataLayer.push({
        event: 'purchase',
        ecommerce: {
            transaction_id: '<?php echo $order->get_order_number(); ?>',
            affiliation: 'WooCommerce Store',
            value: <?php echo $order->get_total(); ?>,
            tax: <?php echo $order->get_total_tax(); ?>,
            shipping: <?php echo $order->get_shipping_total(); ?>,
            currency: '<?php echo $order->get_currency(); ?>',
            items: <?php echo json_encode($order_items); ?>
        }
    });
    </script>
    <?php
    
    // Mark as tracked
    update_post_meta($order_id, '_ga4_purchase_tracked', true);
}

// Remove from Cart
add_action('woocommerce_cart_item_removed', 'ga4_remove_from_cart', 10, 2);
function ga4_remove_from_cart($cart_item_key, $cart) {
    $cart_item = $cart->removed_cart_contents[$cart_item_key];
    $product = $cart_item['data'];
    ?>
    <script>
    dataLayer.push({ecommerce: null});
    dataLayer.push({
        event: 'remove_from_cart',
        ecommerce: {
            currency: '<?php echo get_woocommerce_currency(); ?>',
            value: <?php echo $product->get_price() * $cart_item['quantity']; ?>,
            items: [{
                item_id: '<?php echo $product->get_sku(); ?>',
                item_name: '<?php echo $product->get_name(); ?>',
                price: <?php echo $product->get_price(); ?>,
                quantity: <?php echo $cart_item['quantity']; ?>
            }]
        }
    });
    </script>
    <?php
}
?>
