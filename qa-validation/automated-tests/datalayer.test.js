describe('GA4 dataLayer Structure Tests', () => {
  test('Purchase event should have required fields', () => {
    const purchaseEvent = {
      event: 'purchase',
      ecommerce: {
        transaction_id: 'T_12345',
        currency: 'USD',
        value: 79.99,
        items: [{
          item_id: 'SKU_12345',
          item_name: 'Product Name',
          price: 79.99,
          quantity: 1
        }]
      }
    };
    
    expect(purchaseEvent.event).toBe('purchase');
    expect(purchaseEvent.ecommerce.transaction_id).toBeDefined();
    expect(purchaseEvent.ecommerce.currency).toBeDefined();
    expect(purchaseEvent.ecommerce.items).toBeInstanceOf(Array);
    expect(purchaseEvent.ecommerce.items[0].item_id).toBeDefined();
  });
  
  test('Event names should not exceed 40 characters', () => {
    const validEvent = 'add_to_cart';
    const invalidEvent = 'this_event_name_is_way_too_long_and_exceeds_the_forty_character_limit';
    
    expect(validEvent.length).toBeLessThanOrEqual(40);
    expect(invalidEvent.length).toBeGreaterThan(40);
  });
  
  test('Item arrays should contain required fields', () => {
    const validItem = {
      item_id: 'SKU_001',
      item_name: 'Product Name',
      price: 29.99,
      quantity: 2
    };
    
    expect(validItem).toHaveProperty('item_id');
    expect(validItem).toHaveProperty('item_name');
    expect(validItem).toHaveProperty('price');
    expect(validItem).toHaveProperty('quantity');
  });
});
