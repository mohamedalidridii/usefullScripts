#!/bin/bash

echo "🗄️  Setting up MongoDB database..."

# Check if mongosh is installed
if ! command -v mongosh &> /dev/null; then
    echo "❌ mongosh is not installed. Please install MongoDB Shell first."
    echo "Visit: https://www.mongodb.com/docs/mongodb-shell/install/"
    exit 1
fi

# Database configuration
DB_NAME="nest-crud-db"
COLLECTION_NAME="users"

echo "📦 Creating database: $DB_NAME"
echo "📦 Creating collection: $COLLECTION_NAME"

# Connect and setup database
mongosh --eval "
  use $DB_NAME;
  
  // Create collection with validation
  db.createCollection('$COLLECTION_NAME', {
    validator: {
      \$jsonSchema: {
        bsonType: 'object',
        required: ['name', 'email'],
        properties: {
          name: {
            bsonType: 'string',
            description: 'must be a string and is required'
          },
          email: {
            bsonType: 'string',
            pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$',
            description: 'must be a valid email and is required'
          },
          age: {
            bsonType: ['int', 'double'],
            minimum: 0,
            maximum: 150,
            description: 'must be a number between 0 and 150'
          },
          isActive: {
            bsonType: 'bool',
            description: 'must be a boolean'
          }
        }
      }
    }
  });
  
  // Create unique index on email
  db.$COLLECTION_NAME.createIndex({ email: 1 }, { unique: true });
  
  // Create index on isActive for faster queries
  db.$COLLECTION_NAME.createIndex({ isActive: 1 });
  
  print('✅ Database setup complete!');
  print('📊 Collections:');
  db.getCollectionNames();
  print('📑 Indexes on users collection:');
  db.$COLLECTION_NAME.getIndexes();
"

echo ""
echo "✅ MongoDB setup complete!"
echo "🔗 Connection string: mongodb://localhost:27017/$DB_NAME"
