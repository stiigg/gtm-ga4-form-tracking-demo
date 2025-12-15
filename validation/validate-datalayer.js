/**
 * DataLayer Validation Utility
 * 
 * Purpose: Runtime validation of dataLayer events against JSON schemas
 * 
 * Usage in browser console:
 *   validateDataLayer('form_submission_success')
 *   validateDataLayer('purchase')
 * 
 * Usage in automated tests:
 *   const isValid = validateDataLayer('purchase', eventData);
 *   assert(isValid, 'DataLayer event failed validation');
 * 
 * Auto-validation:
 *   Automatically validates all pushes when:
 *   - window.location.hostname === 'localhost', OR
 *   - window.location.search.includes('debug=1')
 */

const DATALAYER_SCHEMAS = {
  form_submission_success: {
    required: ['event', 'form_id', 'form_type', 'form_location'],
    properties: {
      event: { type: 'string', const: 'form_submission_success' },
      form_id: { 
        type: 'string', 
        pattern: /^[a-z_]+$/, 
        minLength: 3, 
        maxLength: 50 
      },
      form_type: { 
        type: 'string', 
        enum: ['lead', 'support', 'sales', 'newsletter', 'download'] 
      },
      form_location: { 
        type: 'string', 
        pattern: /^[a-z0-9_/]+$/ 
      },
      form_fields: { 
        type: 'object',
        optional: true
      }
    },
    additionalProperties: false
  },
  
  purchase: {
    required: ['event', 'ecommerce'],
    properties: {
      event: { type: 'string', const: 'purchase' },
      ecommerce: {
        type: 'object',
        required: ['transaction_id', 'value', 'currency', 'items'],
        properties: {
          transaction_id: { 
            type: 'string', 
            pattern: /^[A-Z0-9_-]+$/, 
            minLength: 5,
            maxLength: 100
          },
          value: { 
            type: 'number', 
            minimum: 0, 
            maximum: 1000000 
          },
          currency: { 
            type: 'string', 
            pattern: /^[A-Z]{3}$/ 
          },
          tax: { type: 'number', minimum: 0, optional: true },
          shipping: { type: 'number', minimum: 0, optional: true },
          items: {
            type: 'array',
            minItems: 1,
            maxItems: 200,
            itemSchema: {
              required: ['item_id', 'item_name', 'price', 'quantity'],
              properties: {
                item_id: { type: 'string', minLength: 1 },
                item_name: { type: 'string', minLength: 1, maxLength: 500 },
                price: { type: 'number', minimum: 0, maximum: 1000000 },
                quantity: { type: 'integer', minimum: 1, maximum: 10000 },
                item_brand: { type: 'string', maxLength: 100, optional: true },
                item_category: { type: 'string', maxLength: 100, optional: true },
                item_variant: { type: 'string', maxLength: 100, optional: true }
              }
            }
          }
        }
      }
    }
  }
};

function validateDataLayer(eventName, eventData) {
  const schema = DATALAYER_SCHEMAS[eventName];
  
  if (!schema) {
    console.error(`❌ No validation schema found for event: ${eventName}`);
    console.log('Available schemas:', Object.keys(DATALAYER_SCHEMAS).join(', '));
    return false;
  }
  
  // Get latest matching event from dataLayer if eventData not provided
  if (!eventData) {
    if (typeof window === 'undefined' || !window.dataLayer) {
      console.error('❌ window.dataLayer not found');
      return false;
    }
    
    eventData = window.dataLayer
      .slice()
      .reverse()
      .find(e => e && e.event === eventName);
  }
  
  if (!eventData) {
    console.error(`❌ No ${eventName} event found in dataLayer`);
    return false;
  }
  
  const errors = [];
  
  // Validate required fields
  if (schema.required) {
    schema.required.forEach(field => {
      if (!(field in eventData)) {
        errors.push(`Missing required field: ${field}`);
      }
    });
  }
  
  // Validate field types and constraints
  Object.keys(eventData).forEach(key => {
    const fieldSchema = schema.properties[key];
    
    if (!fieldSchema) {
      if (!schema.additionalProperties) {
        errors.push(`Unexpected field: ${key}`);
      }
      return;
    }
    
    const value = eventData[key];
    
    // Validate based on field type
    if (fieldSchema.type === 'object') {
      validateObject(key, value, fieldSchema, errors);
    } else if (fieldSchema.type === 'array') {
      validateArray(key, value, fieldSchema, errors);
    } else {
      validatePrimitive(key, value, fieldSchema, errors);
    }
  });
  
  // Report results
  if (errors.length > 0) {
    console.group(`❌ DataLayer Validation Failed: ${eventName}`);
    errors.forEach(error => console.error(`  • ${error}`));
    console.log('Event data:', eventData);
    console.groupEnd();
    return false;
  }
  
  console.log(`✅ DataLayer validation passed: ${eventName}`);
  return true;
}

function validatePrimitive(key, value, schema, errors) {
  const actualType = typeof value;
  const expectedType = schema.type;
  
  // Type check
  if (expectedType === 'integer') {
    if (!Number.isInteger(value)) {
      errors.push(`Field "${key}" expected integer, got ${actualType} (${value})`);
      return;
    }
  } else if (actualType !== expectedType) {
    errors.push(`Field "${key}" expected ${expectedType}, got ${actualType}`);
    return;
  }
  
  // Const check
  if ('const' in schema && value !== schema.const) {
    errors.push(`Field "${key}" expected "${schema.const}", got "${value}"`);
  }
  
  // Enum check
  if (schema.enum && !schema.enum.includes(value)) {
    errors.push(`Field "${key}" value "${value}" not in allowed values: ${schema.enum.join(', ')}`);
  }
  
  // Pattern check
  if (schema.pattern && typeof value === 'string') {
    if (!schema.pattern.test(value)) {
      errors.push(`Field "${key}" value "${value}" doesn't match pattern: ${schema.pattern}`);
    }
  }
  
  // String length checks
  if (typeof value === 'string') {
    if (schema.minLength && value.length < schema.minLength) {
      errors.push(`Field "${key}" length ${value.length} below minimum: ${schema.minLength}`);
    }
    if (schema.maxLength && value.length > schema.maxLength) {
      errors.push(`Field "${key}" length ${value.length} exceeds maximum: ${schema.maxLength}`);
    }
  }
  
  // Numeric range checks
  if (typeof value === 'number') {
    if (schema.minimum !== undefined && value < schema.minimum) {
      errors.push(`Field "${key}" value ${value} below minimum: ${schema.minimum}`);
    }
    if (schema.maximum !== undefined && value > schema.maximum) {
      errors.push(`Field "${key}" value ${value} exceeds maximum: ${schema.maximum}`);
    }
  }
}

function validateObject(key, value, schema, errors) {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    errors.push(`Field "${key}" expected object, got ${typeof value}`);
    return;
  }
  
  // Validate required nested fields
  if (schema.required) {
    schema.required.forEach(field => {
      if (!(field in value)) {
        errors.push(`Field "${key}.${field}" is required but missing`);
      }
    });
  }
  
  // Validate nested properties
  if (schema.properties) {
    Object.keys(value).forEach(nestedKey => {
      const nestedSchema = schema.properties[nestedKey];
      if (!nestedSchema) {
        if (!schema.additionalProperties) {
          errors.push(`Unexpected nested field: ${key}.${nestedKey}`);
        }
        return;
      }
      
      const nestedValue = value[nestedKey];
      if (nestedSchema.type === 'array') {
        validateArray(`${key}.${nestedKey}`, nestedValue, nestedSchema, errors);
      } else if (nestedSchema.type === 'object') {
        validateObject(`${key}.${nestedKey}`, nestedValue, nestedSchema, errors);
      } else {
        validatePrimitive(`${key}.${nestedKey}`, nestedValue, nestedSchema, errors);
      }
    });
  }
}

function validateArray(key, value, schema, errors) {
  if (!Array.isArray(value)) {
    errors.push(`Field "${key}" expected array, got ${typeof value}`);
    return;
  }
  
  // Array size checks
  if (schema.minItems && value.length < schema.minItems) {
    errors.push(`Field "${key}" array length ${value.length} below minimum: ${schema.minItems}`);
  }
  if (schema.maxItems && value.length > schema.maxItems) {
    errors.push(`Field "${key}" array length ${value.length} exceeds maximum: ${schema.maxItems}`);
  }
  
  // Validate array items
  if (schema.itemSchema) {
    value.forEach((item, index) => {
      const itemKey = `${key}[${index}]`;
      
      if (typeof item !== 'object') {
        errors.push(`${itemKey} expected object, got ${typeof item}`);
        return;
      }
      
      // Required fields in array items
      if (schema.itemSchema.required) {
        schema.itemSchema.required.forEach(field => {
          if (!(field in item)) {
            errors.push(`${itemKey}.${field} is required but missing`);
          }
        });
      }
      
      // Validate item properties
      if (schema.itemSchema.properties) {
        Object.keys(item).forEach(itemProp => {
          const propSchema = schema.itemSchema.properties[itemProp];
          if (!propSchema) {
            return; // Allow additional properties in items
          }
          validatePrimitive(`${itemKey}.${itemProp}`, item[itemProp], propSchema, errors);
        });
      }
    });
  }
}

// Auto-validate on dataLayer push (development mode only)
if (typeof window !== 'undefined' && window.dataLayer) {
  const shouldAutoValidate = 
    window.location.hostname === 'localhost' || 
    window.location.hostname === '127.0.0.1' ||
    window.location.search.includes('debug=1');
  
  if (shouldAutoValidate) {
    const originalPush = window.dataLayer.push;
    
    window.dataLayer.push = function(...args) {
      const event = args[0];
      
      if (event && event.event && DATALAYER_SCHEMAS[event.event]) {
        // Validate before pushing
        setTimeout(() => validateDataLayer(event.event, event), 0);
      }
      
      return originalPush.apply(window.dataLayer, args);
    };
    
    console.log('🔍 DataLayer validation enabled (localhost or ?debug=1 detected)');
    console.log('Available schemas:', Object.keys(DATALAYER_SCHEMAS).join(', '));
  }
}

// Export for Node.js testing environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { validateDataLayer, DATALAYER_SCHEMAS };
}
