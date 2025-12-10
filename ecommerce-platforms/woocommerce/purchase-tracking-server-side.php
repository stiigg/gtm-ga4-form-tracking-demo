<?php
/**
 * WooCommerce Purchase Tracking with Server-Side GTM
 * 
 * Installation:
 * 1. Add to functions.php or custom plugin
 * 2. Configure constants with your IDs
 * 3. Server container will route to GA4 + Meta CAPI
 */

// Configuration
define('GTM_CONTAINER_ID', 'GTM-XXXXXX');
define('GA4_MEASUREMENT_ID', 'G-XXXXXXXXXX');
define('SERVER_TRANSPORT_URL', 'https://track.yourdomain.com');

/**
 * Add server-side GTM tracking to order confirmation page
 */
add_action('woocommerce_thankyou', 'add_server_side_purchase_tracking', 10, 1);

function add_server_side_purchase_tracking($order_id) {
    if (!$order_id) return;
    
    // Prevent double-tracking on page refresh
    $tracked_key = 'order_tracked_' . $order_id;
    if (WC()->session && WC()->session->get($tracked_key)) {
        return;
    }
    
    $order = wc_get_order($order_id);
    if (!$order) return;
    
    // Generate unique transaction ID
    $transaction_id = $order_id . '_' . $order->get_date_created()->getTimestamp();
    
    // Prepare items array
    $items = array();
    foreach ($order->get_items() as $item) {
        $product = $item->get_product();
        $items[] = array(
            'item_id' => $product->get_sku() ?: $product->get_id(),
            'item_name' => $item->get_name(),
            'item_variant' => $product->is_type('variation') ? implode(', ', $product->get_variation_attributes()) : '',
            'price' => $item->get_total() / $item->get_quantity(),
            'quantity' => $item->get_quantity(),
            'item_category' => strip_tags(wc_get_product_category_list($product->get_id(), ', '))
        );
    }
    
    // Hash customer data for Meta CAPI (GDPR-compliant)
    $email_hash = hash('sha256', strtolower($order->get_billing_email()));
    $phone_hash = $order->get_billing_phone() ? hash('sha256', preg_replace('/\D/', '', $order->get_billing_phone())) : '';
    
    ?>
    <!-- Google Tag Manager -->
    <script>
    (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
    new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
    j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
    'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
    })(window,document,'script','dataLayer','<?php echo GTM_CONTAINER_ID; ?>');
    
    // Configure server-side routing
    gtag('config', '<?php echo GA4_MEASUREMENT_ID; ?>', {
        'transport_url': '<?php echo SERVER_TRANSPORT_URL; ?>',
        'first_party_collection': true
    });
    
    // Push purchase event to dataLayer
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({
        event: 'purchase',
        tracking_source: 'server',
        transaction_id: '<?php echo esc_js($transaction_id); ?>',
        ecommerce: {
            transaction_id: '<?php echo esc_js($transaction_id); ?>',
            affiliation: '<?php echo esc_js(get_bloginfo('name')); ?>',
            value: <?php echo $order->get_subtotal(); ?>,
            tax: <?php echo $order->get_total_tax(); ?>,
            shipping: <?php echo $order->get_shipping_total(); ?>,
            currency: '<?php echo $order->get_currency(); ?>',
            items: <?php echo json_encode($items); ?>
        },
        user_data: {
            email_hash: '<?php echo $email_hash; ?>',
            phone_hash: '<?php echo $phone_hash; ?>',
            address: {
                city: '<?php echo esc_js($order->get_billing_city()); ?>',
                region: '<?php echo esc_js($order->get_billing_state()); ?>',
                postal_code: '<?php echo esc_js($order->get_billing_postcode()); ?>',
                country: '<?php echo esc_js($order->get_billing_country()); ?>'
            }
        }
    });
    
    console.log('✅ Purchase event pushed to dataLayer (server-side routing)');
    console.log('Transaction ID: <?php echo esc_js($transaction_id); ?>');
    </script>
    <?php
    
    // Mark order as tracked
    if (WC()->session) {
        WC()->session->set($tracked_key, true);
    }
}
