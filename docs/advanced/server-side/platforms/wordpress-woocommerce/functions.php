<?php
/**
 * WooCommerce Server-Side Tracking Implementation
 * Add to your theme's functions.php or create custom plugin
 * 
 * Features:
 * - Meta Conversions API integration
 * - GA4 Measurement Protocol integration
 * - Event deduplication
 * - PII hashing (GDPR compliant)
 * - Error handling with logging
 * 
 * Based on research from:
 * - Invicti webhook security practices
 * - WooCommerce action hooks documentation
 * - Meta CAPI best practices
 */

// Configuration - Add to wp-config.php or use environment variables
define('META_PIXEL_ID', '1234567890123456');
define('META_ACCESS_TOKEN', 'your_meta_access_token');
define('GA4_MEASUREMENT_ID', 'G-XXXXXXXXXX');
define('GA4_API_SECRET', 'your_ga4_api_secret');

/**
 * Hook into WooCommerce order payment completion
 * Fires only when payment is confirmed (not pending)
 */
add_action('woocommerce_payment_complete', 'send_server_side_conversion_events', 10, 1);

function send_server_side_conversion_events($order_id) {
    try {
        // Get order object
        $order = wc_get_order($order_id);
        
        if (!$order) {
            error_log('❌ Server-side tracking: Order not found - ' . $order_id);
            return;
        }
        
        // Prevent duplicate sends
        if ($order->get_meta('_server_side_tracking_sent')) {
            error_log('⚠️ Server-side tracking: Already sent for order ' . $order_id);
            return;
        }
        
        // Generate unique event_id for deduplication
        // CRITICAL: Use same format as client-side for proper deduplication
        $event_id = 'woo_' . $order_id . '_' . $order->get_order_number();
        
        // Capture browser identifiers from session/cookies
        // These should be stored during checkout process
        $fbp = $order->get_meta('_fbp') ?: WC()->session->get('_fbp');
        $fbc = $order->get_meta('_fbc') ?: WC()->session->get('_fbc');
        
        // Get customer data
        $customer_email = $order->get_billing_email();
        $customer_phone = $order->get_billing_phone();
        $customer_first_name = $order->get_billing_first_name();
        $customer_last_name = $order->get_billing_last_name();
        $customer_city = $order->get_billing_city();
        $customer_state = $order->get_billing_state();
        $customer_postcode = $order->get_billing_postcode();
        $customer_country = $order->get_billing_country();
        
        // Get client IP and user agent
        $client_ip = $order->get_customer_ip_address();
        $user_agent = $order->get_customer_user_agent();
        
        // Prepare order items
        $items = [];
        $content_ids = [];
        
        foreach ($order->get_items() as $item) {
            $product = $item->get_product();
            $content_ids[] = $product->get_id();
            
            $items[] = [
                'item_id' => $product->get_id(),
                'item_name' => $product->get_name(),
                'price' => floatval($item->get_total()),
                'quantity' => intval($item->get_quantity())
            ];
        }
        
        // Send to Meta Conversions API
        $meta_sent = send_to_meta_capi([
            'event_name' => 'Purchase',
            'event_time' => $order->get_date_created()->getTimestamp(),
            'event_id' => $event_id,
            'event_source_url' => get_site_url(),
            'action_source' => 'website',
            'user_data' => [
                'em' => hash_pii($customer_email),
                'ph' => hash_pii(preg_replace('/\D/', '', $customer_phone)),
                'fn' => hash_pii($customer_first_name),
                'ln' => hash_pii($customer_last_name),
                'ct' => hash_pii($customer_city),
                'st' => hash_pii($customer_state),
                'zp' => hash_pii($customer_postcode),
                'country' => hash_pii($customer_country),
                'fbp' => $fbp,
                'fbc' => $fbc,
                'client_ip_address' => $client_ip,
                'client_user_agent' => $user_agent
            ],
            'custom_data' => [
                'currency' => $order->get_currency(),
                'value' => floatval($order->get_total()),
                'content_ids' => $content_ids,
                'content_type' => 'product',
                'num_items' => $order->get_item_count(),
                'order_id' => $order->get_order_number()
            ]
        ]);
        
        // Send to GA4 Measurement Protocol
        $ga4_sent = send_to_ga4([
            'client_id' => $order->get_customer_id() ?: 'guest_' . $order_id,
            'events' => [[
                'name' => 'purchase',
                'params' => [
                    'transaction_id' => $order->get_order_number(),
                    'value' => floatval($order->get_total()),
                    'tax' => floatval($order->get_total_tax()),
                    'shipping' => floatval($order->get_shipping_total()),
                    'currency' => $order->get_currency(),
                    'coupon' => implode(',', $order->get_coupon_codes()),
                    'items' => $items
                ]
            ]]
        ]);
        
        // Mark as sent to prevent duplicates
        if ($meta_sent || $ga4_sent) {
            $order->update_meta_data('_server_side_tracking_sent', true);
            $order->update_meta_data('_server_side_tracking_timestamp', time());
            $order->save();
            
            error_log('✅ Server-side tracking sent for order ' . $order_id);
        }
        
    } catch (Exception $e) {
        error_log('❌ Server-side tracking error: ' . $e->getMessage());
    }
}

/**
 * Hash PII data for privacy compliance
 */
function hash_pii($data) {
    if (empty($data)) return null;
    return hash('sha256', strtolower(trim($data)));
}

/**
 * Send event to Meta Conversions API
 */
function send_to_meta_capi($event) {
    $url = 'https://graph.facebook.com/v19.0/' . META_PIXEL_ID . '/events';
    
    $response = wp_remote_post($url, [
        'headers' => ['Content-Type' => 'application/json'],
        'body' => json_encode([
            'data' => [$event],
            'access_token' => META_ACCESS_TOKEN
        ]),
        'timeout' => 10
    ]);
    
    if (is_wp_error($response)) {
        error_log('❌ Meta CAPI error: ' . $response->get_error_message());
        return false;
    }
    
    $body = json_decode(wp_remote_retrieve_body($response), true);
    
    if (isset($body['events_received']) && $body['events_received'] > 0) {
        error_log('✅ Meta CAPI event sent: ' . json_encode($body));
        return true;
    }
    
    error_log('❌ Meta CAPI failed: ' . json_encode($body));
    return false;
}

/**
 * Send event to GA4 Measurement Protocol
 */
function send_to_ga4($data) {
    $url = 'https://www.google-analytics.com/mp/collect';
    $url .= '?measurement_id=' . GA4_MEASUREMENT_ID;
    $url .= '&api_secret=' . GA4_API_SECRET;
    
    $response = wp_remote_post($url, [
        'headers' => ['Content-Type' => 'application/json'],
        'body' => json_encode($data),
        'timeout' => 10
    ]);
    
    if (is_wp_error($response)) {
        error_log('❌ GA4 error: ' . $response->get_error_message());
        return false;
    }
    
    $status = wp_remote_retrieve_response_code($response);
    
    if ($status >= 200 && $status < 300) {
        error_log('✅ GA4 event sent successfully');
        return true;
    }
    
    error_log('❌ GA4 failed with status: ' . $status);
    return false;
}

/**
 * Capture browser identifiers during checkout
 * Add to your checkout page or custom plugin
 */
add_action('wp_footer', 'capture_browser_identifiers');

function capture_browser_identifiers() {
    if (!is_checkout()) return;
    ?>
    <script>
    (function() {
        function getCookie(name) {
            const value = `; ${document.cookie}`;
            const parts = value.split(`; ${name}=`);
            if (parts.length === 2) return parts.pop().split(';').shift();
        }
        
        const fbp = getCookie('_fbp');
        const fbclid = new URLSearchParams(location.search).get('fbclid');
        const fbc = getCookie('_fbc') || (fbclid ? `fb.1.${Date.now()}.${fbclid}` : null);
        
        if (fbp || fbc) {
            // Store in WooCommerce session
            jQuery.post('<?php echo admin_url('admin-ajax.php'); ?>', {
                action: 'store_browser_identifiers',
                fbp: fbp,
                fbc: fbc
            });
        }
    })();
    </script>
    <?php
}

/**
 * AJAX handler to store browser identifiers in session
 */
add_action('wp_ajax_store_browser_identifiers', 'store_browser_identifiers_handler');
add_action('wp_ajax_nopriv_store_browser_identifiers', 'store_browser_identifiers_handler');

function store_browser_identifiers_handler() {
    if (isset($_POST['fbp'])) {
        WC()->session->set('_fbp', sanitize_text_field($_POST['fbp']));
    }
    if (isset($_POST['fbc'])) {
        WC()->session->set('_fbc', sanitize_text_field($_POST['fbc']));
    }
    wp_die();
}
?>
